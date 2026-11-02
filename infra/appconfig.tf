resource "aws_appconfig_application" "ai_assistant" {
  name        = "ai-assistant-app"
  description = "AppConfig application for AI model selection"
}


resource "aws_appconfig_environment" "production" {
  name           = "production"
  description    = "Production environment for AI assistant"
  application_id = aws_appconfig_application.ai_assistant.id
}


resource "aws_appconfig_configuration_profile" "model_selection" {
  application_id = aws_appconfig_application.ai_assistant.id
  name           = "model-selection"
  description    = "Model selection configuration"

  location_uri = "hosted"
  type         = "AWS.Freeform"
}

resource "aws_appconfig_hosted_configuration_version" "model_selection" {
  application_id = aws_appconfig_application.ai_assistant.id

  configuration_profile_id = (
    aws_appconfig_configuration_profile.model_selection.configuration_profile_id
  )

  content_type = "application/json"

  content = jsonencode({
    primary_model = "amazon.nova-micro-v1:0"

    fallback_models = [
      "amazon.nova-lite-v1:0",
      "amazon.nova-pro-v1:0"
    ]
  })
}

resource "aws_appconfig_configuration_profile" "feature_flags" {
  application_id = aws_appconfig_application.ai_assistant.id

  name         = "feature-flags"
  description  = "Feature flags for AI model routing"
  location_uri = "hosted"

  type = "AWS.AppConfig.FeatureFlags"
}

resource "aws_appconfig_hosted_configuration_version" "feature_flags" {
  application_id = aws_appconfig_application.ai_assistant.id

  configuration_profile_id = (
    aws_appconfig_configuration_profile.feature_flags.configuration_profile_id
  )

  content_type = "application/json"

  content = jsonencode({
    version = "1"

    flags = {
      model_override = {
        name        = "Model Override"
        description = "Temporarily override the primary Bedrock model"

        attributes = {
          model_id = {
            constraints = {
              type = "string"
            }
          }
        }
      }
    }

    values = {
      model_override = {
        enabled = false

        attributeValues = {
          model_id = "amazon.nova-lite-v1:0"
        }
      }
    }
  })
}

###### Deplaoyement strategy for immediate deployment of configuration changes
resource "aws_appconfig_deployment_strategy" "immediate" {
  name        = "ai-assistant-immediate"
  description = "Immediately deploy AI assistant configuration"

  deployment_duration_in_minutes = 0
  growth_factor                  = 100
  replicate_to                   = "SSM_DOCUMENT"
}

resource "aws_appconfig_deployment" "model_selection" {
  application_id = aws_appconfig_application.ai_assistant.id

  environment_id = (
    aws_appconfig_environment.production.environment_id
  )

  configuration_profile_id = (
    aws_appconfig_configuration_profile.model_selection.configuration_profile_id
  )

  configuration_version = (
    aws_appconfig_hosted_configuration_version.model_selection.version_number
  )

  deployment_strategy_id = (
    aws_appconfig_deployment_strategy.immediate.id
  )
}

resource "aws_appconfig_deployment" "feature_flags" {
  application_id = aws_appconfig_application.ai_assistant.id

  environment_id = (
    aws_appconfig_environment.production.environment_id
  )

  configuration_profile_id = (
    aws_appconfig_configuration_profile.feature_flags.configuration_profile_id
  )

  configuration_version = (
    aws_appconfig_hosted_configuration_version.feature_flags.version_number
  )

  deployment_strategy_id = (
    aws_appconfig_deployment_strategy.immediate.id
  )
}