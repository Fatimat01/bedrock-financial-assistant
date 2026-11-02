# Financial Services AI Assistant

Customer service assistant on Amazon Bedrock. Requirements are in [use-case.md](use-case.md).
Parts 1 and 2 are implemented.

## Layout

```
eveluation/   model benchmark (notebook + script) and results
infra/        Terraform: guardrail, AppConfig, Lambda, API Gateway, IAM
lambda/       model abstraction handler
```

## Part 1: Model assessment and benchmarking

`eveluation/benchmark.py` (and the same code stepped through in `benchmark.ipynb`) runs three
financial questions against Nova Micro, Nova Lite and Nova Pro through the Bedrock Converse API
and records per request:

- response quality — word overlap with a ground-truth answer
- latency
- input/output tokens
- cost, from per-model token pricing
- throughput — 5 concurrent requests, measured as requests per second

The per-model averages and the throughput results are merged into one decision table and written
to `eveluation/model_benchmark_decision_table.csv`.

Run:

```bash
cd eveluation
python benchmark.py
```

### Result

| model | quality | latency (s) | req/s | cost per 1,000 requests |
| --- | --- | --- | --- | --- |
| Nova Micro | 0.77 | 0.50 | 7.4 | $0.0093 |
| Nova Pro | 0.75 | 0.74 | 6.6 | $0.1517 |
| Nova Lite | 0.58 | 0.44 | 9.6 | $0.0106 |

Nova Micro scored highest on quality at the lowest cost, so it is the primary model. Nova Lite and
Nova Pro are configured as fallbacks.

## Part 2: Flexible architecture for dynamic model selection

```
POST /generate -> API Gateway -> Lambda -> AppConfig (model + flags) -> Bedrock
```

- **API Gateway** (`infra/api-gateway.tf`) — REST API, `POST /generate` proxied to the Lambda,
  `prod` stage. Authorization is `NONE`.
- **Lambda** (`lambda/model_abstraction.py`, `infra/lambda.tf`) — the model abstraction layer.
  Reads both AppConfig profiles per request, picks the model, calls Converse, and returns
  `model_used` and `response`.
- **AppConfig** (`infra/appconfig.tf`) — application `ai-assistant-app`, `production` environment,
  two hosted profiles deployed with an immediate strategy:
  - `model-selection` (freeform) — `primary_model` and `fallback_models`
  - `feature-flags` — `model_override` flag with a `model_id` attribute, disabled by default
- **Guardrail** (`infra/guardrail.tf`) — content filters, SSN and card-number blocking, and a deny
  topic for personalized investment advice. Created and versioned, not yet attached to the
  Converse call.
- **IAM** (`infra/iam.tf`) — Lambda execution role with `bedrock:InvokeModel`, AppConfig data
  access, and basic logging.

Model changes are config changes: edit the hosted configuration version, deploy it, and the next
request picks it up — no code deploy. The `model_override` flag switches models without touching
`model-selection`.

Deploy:

```bash
cd infra
terraform init
terraform apply
```


Call it:

```bash
curl -X POST "$(terraform output -raw api_endpoint)" \
  -H 'Content-Type: application/json' \
  -d '{"prompt": "What is a 401(k) retirement plan?"}'
```

## Not yet implemented

Part 3 (Step Functions circuit breaker, cross-region deployment, graceful degradation) and Part 4
(SageMaker fine-tuning, model versioning, automated testing and rollback). The configured
`fallback_models` are not used by the Lambda yet.
