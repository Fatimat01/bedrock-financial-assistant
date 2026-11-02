# Lambda needs permission to invoke Bedrock, retrieve AppConfig configuration and write CloudWatch logs

resource "aws_iam_role" "lambda_role" {
  name = "ai-assistant-lambda-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"

    Statement = [
      {
        Effect = "Allow"

        Principal = {
          Service = "lambda.amazonaws.com"
        }

        Action = "sts:AssumeRole"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "lambda_basic" {
  role = aws_iam_role.lambda_role.name

  policy_arn = (
    "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
  )
}

resource "aws_iam_role_policy" "lambda_permissions" {
  name = "ai-assistant-permissions"
  role = aws_iam_role.lambda_role.id

  policy = jsonencode({
    Version = "2012-10-17"

    Statement = [
      {
        Effect = "Allow"

        Action = [
          "bedrock:InvokeModel"
        ]

        Resource = "*"
      },

      {
        Effect = "Allow"

        Action = [
          "appconfig:StartConfigurationSession",
          "appconfig:GetLatestConfiguration"
        ]

        Resource = "*"
      }
    ]
  })
}