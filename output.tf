# output.tf
output "role_arn_read_only" {
  value = aws_iam_role.github_actions_read_only.arn
}

output "role_arn_write_only" {
  value = aws_iam_role.github_actions_write_only.arn
}
