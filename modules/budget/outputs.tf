output "budget_name" {
  description = "Name of the budget."
  value       = aws_budgets_budget.this.name
}

output "budget_arn" {
  description = "ARN of the budget."
  value       = aws_budgets_budget.this.arn
}
