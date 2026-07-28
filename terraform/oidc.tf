# Establish trusted root certificate validation for GitHub
resource "aws_iam_openid_connect_provider" "github" {
  url             = "https://githubusercontent.com"
  client_id_list  = ["://amazonaws.com"]
  thumbprint_list = ["6938fd4d98bab03faadb97b34396831e3780aea1"]
}
# IAM Role assumed dynamically by the GitHub runner runner
resource "aws_iam_role" "github_actions_role" {
  name = "github-actions-capstone-runner"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect    = "Allow"
        Principal = { Federated = aws_iam_openid_connect_provider.github.arn }
        Action    = "sts:AssumeRoleWithWebIdentity"
        Condition = {
          StringEquals = {
            "://githubusercontent.com:aud" = "://amazonaws.com"
          }
          StringLike = {
            # ADVICE: Replace 'your-github-username' with your actual username below
            "://githubusercontent.com:sub" = "repo:your-github-username/*"
          }
        }
      }
    ]
  })
}
# Grants permissions to manage container updates and cluster states
resource "aws_iam_role_policy_attachment" "admin_bind" {
  role       = aws_iam_role.github_actions_role.name
  policy_arn = "arn:aws:iam::aws:policy/AdministratorAccess"
}
output "github_actions_role_arn" {
  value       = aws_iam_role.github_actions_role.arn
  description = "Copy this ARN value directly into your GitHub actions workflow file environment configuration."
}