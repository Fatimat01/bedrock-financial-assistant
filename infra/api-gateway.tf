resource "aws_api_gateway_rest_api" "ai_assistant" {
  name        = "ai-assistant-api"
  description = "API for the AI assistant"
}

resource "aws_api_gateway_resource" "generate" {
  rest_api_id = aws_api_gateway_rest_api.ai_assistant.id

  parent_id = (
    aws_api_gateway_rest_api.ai_assistant.root_resource_id
  )

  path_part = "generate"
}

# post method for the /generate resource
resource "aws_api_gateway_method" "generate_post" {
  rest_api_id = aws_api_gateway_rest_api.ai_assistant.id
  resource_id = aws_api_gateway_resource.generate.id

  http_method   = "POST"
  authorization = "NONE"
}

resource "aws_api_gateway_integration" "lambda" {
  rest_api_id = aws_api_gateway_rest_api.ai_assistant.id
  resource_id = aws_api_gateway_resource.generate.id

  http_method = aws_api_gateway_method.generate_post.http_method

  integration_http_method = "POST"
  type                    = "AWS_PROXY"

  uri = aws_lambda_function.model_abstraction.invoke_arn
}

# grant API gateway permission to invoke the Lambda function
resource "aws_lambda_permission" "api_gateway" {
  statement_id = "AllowAPIGatewayInvoke"

  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.model_abstraction.function_name

  principal = "apigateway.amazonaws.com"

  source_arn = (
    "${aws_api_gateway_rest_api.ai_assistant.execution_arn}/*/*"
  )
}

resource "aws_api_gateway_deployment" "ai_assistant" {
  rest_api_id = aws_api_gateway_rest_api.ai_assistant.id

  depends_on = [
    aws_api_gateway_integration.lambda
  ]

  triggers = {
    redeployment = sha1(
      jsonencode([
        aws_api_gateway_resource.generate.id,
        aws_api_gateway_method.generate_post.id,
        aws_api_gateway_integration.lambda.id
      ])
    )
  }

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_api_gateway_stage" "prod" {
  deployment_id = aws_api_gateway_deployment.ai_assistant.id

  rest_api_id = aws_api_gateway_rest_api.ai_assistant.id

  stage_name = "prod"
}