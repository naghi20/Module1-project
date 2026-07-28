# Establish trusted root certificate validation for GitHub
resource "aws_iam_openid_connect_provider" "github" {
  url            = "https://token.actions.githubusercontent.com"
  client_id_list = ["sts.amazonaws.com"]
  
  # ✅ Must include BOTH root thumbprints to allow traffic from all GitHub nodes
  thumbprint_list = [
    "1c58a3a8518e8759bf075b76b750d4f2df264fcd",
    "6938fd4d98bab03faadb97b34396831e3780aea1"
  ]
}

# IAM Role assumed dynamically by the GitHub runner
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
            "token.actions.githubusercontent.com:aud" = "sts.amazonaws.com"
            "token.actions.githubusercontent.com:sub" = "repo:naghi20/Module1-project:ref:refs/heads/main"
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
  description = "Dynamic credentials role target."
}
