# This creates the OIDC Provider directly with the correct Audience client list
resource "aws_iam_openid_connect_provider" "github" {
  url             = "https://token.actions.githubusercontent.com"
  client_id_list  = ["sts.amazonaws.com"] # This fixes the missing audience bug
  thumbprint_list = ["ab9d0263244dd0326eb67015705a667e79cfe998"]
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
            # Enforces flexible repo-level matching with a clean trailing wildcard asterisk
            "token.actions.githubusercontent.com:sub" = "repo:naghi20@64667680/Module1-project:*"
          }
        }
      }
    ]
  })
}

# 3. Grants permissions to manage container updates and cluster states
resource "aws_iam_role_policy_attachment" "admin_bind" {
  role       = aws_iam_role.github_actions_role.name
  policy_arn = "arn:aws:iam::aws:policy/AdministratorAccess"
}

output "github_actions_role_arn" {
  value = aws_iam_role.github_actions_role.arn
}
