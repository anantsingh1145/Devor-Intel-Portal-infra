"""Keeps a Route 53 A record pointed at the Chronicle ECS task's current
public IP. There's no ALB in this architecture, so the task's IP changes on
every restart/redeploy/autoscaling event — this Lambda is what keeps DNS
in sync instead.

Triggered by an EventBridge rule matching "ECS Task State Change" events
where lastStatus/desiredStatus are RUNNING (see modules/dns_sync/main.tf for
the exact event pattern). Logs the full incoming event first, so a bad
assumption about the event shape is diagnosable from CloudWatch Logs instead
of failing silently.
"""

import json
import os

import boto3

ec2 = boto3.client("ec2")
route53 = boto3.client("route53")

HOSTED_ZONE_ID = os.environ["HOSTED_ZONE_ID"]
RECORD_NAME = os.environ["RECORD_NAME"]
RECORD_TTL = int(os.environ.get("RECORD_TTL", "60"))


def handler(event, context):
    print("Received event:", json.dumps(event))

    detail = event.get("detail", {})
    last_status = detail.get("lastStatus")
    if last_status != "RUNNING":
        print(f"Ignoring task in status {last_status!r} (only acting on RUNNING)")
        return {"skipped": True, "reason": f"lastStatus={last_status}"}

    eni_id = _extract_eni_id(detail)
    if not eni_id:
        print("No ENI attachment found in event detail; nothing to do")
        return {"skipped": True, "reason": "no-eni"}

    public_ip = _get_public_ip(eni_id)
    if not public_ip:
        print(f"ENI {eni_id} has no public IP association; nothing to do")
        return {"skipped": True, "reason": "no-public-ip"}

    _update_record(public_ip)
    return {"updated": True, "public_ip": public_ip}


def _extract_eni_id(detail):
    for attachment in detail.get("attachments", []):
        if attachment.get("type") != "eni":
            continue
        for item in attachment.get("details", []):
            if item.get("name") == "networkInterfaceId":
                return item.get("value")
    return None


def _get_public_ip(eni_id):
    resp = ec2.describe_network_interfaces(NetworkInterfaceIds=[eni_id])
    interfaces = resp.get("NetworkInterfaces", [])
    if not interfaces:
        return None
    association = interfaces[0].get("Association", {})
    return association.get("PublicIp")


def _update_record(public_ip):
    print(f"Updating {RECORD_NAME} -> {public_ip}")
    route53.change_resource_record_sets(
        HostedZoneId=HOSTED_ZONE_ID,
        ChangeBatch={
            "Comment": "Auto-updated by dns_sync Lambda on ECS task state change",
            "Changes": [
                {
                    "Action": "UPSERT",
                    "ResourceRecordSet": {
                        "Name": RECORD_NAME,
                        "Type": "A",
                        "TTL": RECORD_TTL,
                        "ResourceRecords": [{"Value": public_ip}],
                    },
                }
            ],
        },
    )
    print("Route 53 update submitted successfully")
