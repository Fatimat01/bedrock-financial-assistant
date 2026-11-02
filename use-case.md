# Use Case

Build a customer service AI assistant for a financial services company. The assistant needs to:

- Answer product questions based on company documentation
- Generate personalized responses to customer inquiries
- Maintain high availability and consistent performance
- Comply with financial industry regulations

# Requirements

## Part 1: Foundation Model assessment and benchmarking

- Set up a benchmarking framework to evaluate different Amazon Bedrock models
- Compare models based on:
  - Response quality for financial domain questions
  - Latency and throughput
  - Cost per request
  - Compliance with guardrails

## Step 2. Flexible architecture for dynamic model selection

- Implement a model abstraction layer using AWS Lambda
- Configure AWS AppConfig for dynamic model selection rules
- Create an API Gateway endpoint for consistent client access

## Step 3. Resilient system design

- Implement AWS Step Functions with circuit breaker patterns
- Set up cross-region model deployment for high availability
- Create graceful degradation strategies for service disruptions

## Step 4. Model customization and lifecycle management

- Fine-tune a model for financial domain using Amazon SageMaker
- Implement model versioning and deployment workflows
- Create automated testing and rollback strategies


## notes
Cheaper price per token does not automatically mean cheaper request