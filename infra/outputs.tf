output "guardrail_id" {
  description = "Identifier of the financial assistant guardrail, passed to Bedrock at invocation time."
  value       = aws_bedrock_guardrail.financial_assistant.guardrail_id
}

output "guardrail_arn" {
  description = "ARN of the financial assistant guardrail."
  value       = aws_bedrock_guardrail.financial_assistant.guardrail_arn
}

output "guardrail_version" {
  description = "Published Bedrock Guardrail version"

  value = aws_bedrock_guardrail_version.financial_assistant.version
}

output "api_endpoint" {
  description = "AI Assistant API endpoint"

  value = (
    "${aws_api_gateway_stage.prod.invoke_url}/generate"
  )
}


output "lambda_name" {
  value = aws_lambda_function.model_abstraction.function_name
}


output "appconfig_application_id" {
  value = aws_appconfig_application.ai_assistant.id
}


output "model_selection_profile_id" {
  value = (
    aws_appconfig_configuration_profile.model_selection.configuration_profile_id
  )
}


output "feature_flag_profile_id" {
  value = (
    aws_appconfig_configuration_profile.feature_flags.configuration_profile_id
  )
}