# This creates the OIDC Provider directly with the correct Audience client list
resource "aws_iam_openid_connect_provider" "github" {
  url             = "https://token.actions.githubusercontent.com"
  client_id_list  = ["sts.amazonaws.com"]
  thumbprint_list = ["6938fd4d98bab03faadb97b34396831e3780aea1", "1c58a3a8518e8759bf075b76b750d4f2df264fcd"]
}

# 2. IAM Role assumed dynamically by the GitHub runner
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
          }
          StringLike = {
            # FIXED: Added both the specific repository ID and the trailing wildcard
            "token.actions.githubusercontent.com:sub" = "repo:naghi20@64667680/Module1-project@1315402738:*"
          }
        }
      }
    ]
  })
# 3. Grants permissions to manage container updates and cluster states
resource "aws_iam_role_policy_attachment" "admin_bind" {
  role       = aws_iam_role.github_actions_role.name
  policy_arn = "arn:aws:iam::aws:policy/AdministratorAccess"
}

output "github_actions_role_arn" {
  value       = aws_iam_role.github_actions_role.arn
  description = "Copy this output value back into your GitHub actions deploy.yml configuration file."
}
