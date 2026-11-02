resource "aws_bedrock_guardrail" "financial_assistant" {
  name        = "financial-assistant-guardrail"
  description = "Guardrail for the financial services AI assistant"

  blocked_input_messaging   = "I can't help with that request."
  blocked_outputs_messaging = "I can't provide that response."

  content_policy_config {

    filters_config {
      type            = "HATE"
      input_strength  = "HIGH"
      output_strength = "HIGH"
    }

    filters_config {
      type            = "VIOLENCE"
      input_strength  = "HIGH"
      output_strength = "HIGH"
    }

    filters_config {
      type            = "SEXUAL"
      input_strength  = "HIGH"
      output_strength = "HIGH"
    }

    filters_config {
      type            = "INSULTS"
      input_strength  = "HIGH"
      output_strength = "HIGH"
    }
  }

  sensitive_information_policy_config {

    pii_entities_config {
      type   = "US_SOCIAL_SECURITY_NUMBER"
      action = "BLOCK"
    }

    pii_entities_config {
      type   = "CREDIT_DEBIT_CARD_NUMBER"
      action = "BLOCK"
    }
  }

  topic_policy_config {

    topics_config {
      name       = "personal-investment-advice"
      type       = "DENY"
      definition = "Personalized investment recommendations or instructions telling a customer which specific security, stock, bond, fund, or investment they should buy or sell."

      examples = [
        "Which stock should I buy today?",
        "Tell me exactly where I should invest my retirement money.",
        "Should I sell all of my shares in this company?"
      ]
    }
  }
}

resource "aws_bedrock_guardrail_version" "financial_assistant" {
  guardrail_arn = aws_bedrock_guardrail.financial_assistant.guardrail_arn

  description = "Initial financial assistant guardrail"
}