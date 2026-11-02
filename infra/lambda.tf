data "archive_file" "model_abstraction" {
  type = "zip"

  source_file = "${path.module}/../lambda/model_abstraction.py"

  output_path = "${path.module}/model_abstraction.zip"
}

resource "aws_lambda_function" "model_abstraction" {
  function_name = "ai-assistant-model-abstraction"

  role = aws_iam_role.lambda_role.arn

  handler = "model_abstraction.lambda_handler"
  runtime = "python3.12"

  filename         = data.archive_file.model_abstraction.output_path
  source_code_hash = data.archive_file.model_abstraction.output_base64sha256

  timeout     = 30
  memory_size = 256

  environment {
    variables = {
      APPCONFIG_APPLICATION_ID = (
        aws_appconfig_application.ai_assistant.id
      )

      APPCONFIG_ENVIRONMENT_ID = (
        aws_appconfig_environment.production.environment_id
      )

      MODEL_CONFIG_PROFILE_ID = (
        aws_appconfig_configuration_profile.model_selection.configuration_profile_id
      )

      FEATURE_FLAG_PROFILE_ID = (
        aws_appconfig_configuration_profile.feature_flags.configuration_profile_id
      )
    }
  }
}