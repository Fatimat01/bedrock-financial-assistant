import boto3
import time
import pandas as pd
from concurrent.futures import ThreadPoolExecutor

session = boto3.Session(profile_name="neotrix")

bedrock = session.client(
    "bedrock-runtime",
    region_name="us-east-1"
)

models = [
    "amazon.nova-micro-v1:0",
    "amazon.nova-lite-v1:0",
    "amazon.nova-pro-v1:0"
]

# Current model pricing per 1,000 tokens.
MODEL_PRICING = {
    "amazon.nova-micro-v1:0": {
        "input": 0.000035,
        "output": 0.00014
    },
    "amazon.nova-lite-v1:0": {
        "input": 0.00006,
        "output": 0.00024
    },
    "amazon.nova-pro-v1:0": {
        "input": 0.0008,
        "output": 0.0032
    }
}

test_cases = [
    {
        "question": "What is a 401(k) retirement plan?",
        "ground_truth": (
            "A 401(k) is a tax-advantaged retirement savings "
            "plan offered by employers."
        )
    },
    {
        "question": "What is compound interest?",
        "ground_truth": (
            "Compound interest is interest earned on both the "
            "original principal and previously earned interest."
        )
    },
    {
        "question": (
            "What is the difference between a checking account "
            "and a savings account?"
        ),
        "ground_truth": (
            "A checking account is primarily used for frequent "
            "transactions while a savings account is designed "
            "for storing money and earning interest."
        )
    }
]


def invoke_model(model_id, prompt):
    """
    Sends a prompt to the selected Amazon Bedrock model and
    returns the generated response along with latency and token usage.
    """

    start_time = time.time()

    try:
        response = bedrock.converse(
            modelId=model_id,
            messages=[
                {
                    "role": "user",
                    "content": [
                        {
                            "text": prompt
                        }
                    ]
                }
            ],
            inferenceConfig={
                "maxTokens": 150,
                "temperature": 0.2
            }
        )

        latency = time.time() - start_time

        output = response["output"]["message"]["content"][0]["text"]

        usage = response.get("usage", {})

        return {
            "success": True,
            "output": output,
            "latency": latency,
            "input_tokens": usage.get("inputTokens", 0),
            "output_tokens": usage.get("outputTokens", 0)
        }

    except Exception as e:
        return {
            "success": False,
            "error": str(e),
            "latency": time.time() - start_time
        }


def calculate_similarity(output, ground_truth):
    """
    Calculates a simple word-overlap score between the model's
    response and the expected ground-truth answer.
    """

    output_words = set(output.lower().split())
    truth_words = set(ground_truth.lower().split())

    if not truth_words:
        return 0.0

    common_words = output_words.intersection(truth_words)

    return len(common_words) / len(truth_words)

def calculate_cost(model_id, input_tokens, output_tokens):
    """
    Calculates the estimated Bedrock inference cost for one request
    using the model's input and output token pricing.
    """

    pricing = MODEL_PRICING[model_id]

    input_cost = (
        input_tokens / 1000
    ) * pricing["input"]

    output_cost = (
        output_tokens / 1000
    ) * pricing["output"]

    return input_cost + output_cost

def measure_throughput(model_id, prompt, request_count=5):
    """
    Sends multiple requests to the same model concurrently and
    calculates how many successful requests are completed per second.
    """

    start_time = time.time()

    with ThreadPoolExecutor(max_workers=request_count) as executor:
        futures = [
            executor.submit(
                invoke_model,
                model_id,
                prompt
            )
            for _ in range(request_count)
        ]

        responses = [
            future.result()
            for future in futures
        ]

    total_time = time.time() - start_time

    successful_requests = sum(
        1
        for response in responses
        if response["success"]
    )

    requests_per_second = (
        successful_requests / total_time
        if total_time > 0
        else 0
    )

    return {
        "model_id": model_id,
        "successful_requests": successful_requests,
        "total_requests": request_count,
        "total_time": total_time,
        "requests_per_second": requests_per_second
    }

def evaluate_models():
    """
    Runs every test question against every model, collects the
    model responses and performance metrics, and returns them
    as a pandas DataFrame.
    """

    results = []

    for test_case in test_cases:

        prompt = (
            "Answer the following financial question clearly and accurately "
            "in no more than 3 sentences.\n\n"
            f"Question: {test_case['question']}"
        )

        for model_id in models:

            print(
                f"\nEvaluating {model_id}"
                f"\nQuestion: {test_case['question']}"
            )

            response = invoke_model(
                model_id,
                prompt
            )

            if response["success"]:
                cost = calculate_cost(
                    model_id,
                    response["input_tokens"],
                    response["output_tokens"]
                )
                similarity = calculate_similarity(
                    response["output"],
                    test_case["ground_truth"]
                )

                results.append({
                    "model_id": model_id,
                    "question": test_case["question"],
                    "output": response["output"],
                    "latency": response["latency"],
                    "input_tokens": response["input_tokens"],
                    "output_tokens": response["output_tokens"],
                    "similarity_score": similarity,
                    "cost": cost
                })

            else:

                results.append({
                    "model_id": model_id,
                    "question": test_case["question"],
                    "error": response["error"],
                    "latency": response["latency"]
                })

    return pd.DataFrame(results)


if __name__ == "__main__":

    results_df = evaluate_models()

    # Save the detailed result of every model invocation to a CSV file.
    results_df.to_csv(
        "model_evaluation_results.csv",
        index=False
    )

    print("\nEvaluation Results")
    print(results_df)

    # Calculate average metrics for each model so they are easier to compare.
    print("\nEvaluation Summary")

    summary = results_df.groupby("model_id").agg({
        "latency": "mean",
        "similarity_score": "mean",
        "input_tokens": "mean",
        "output_tokens": "mean",
        "cost": "mean"
    }).reset_index()

    print(summary)

    print("\nThroughput Test")

    throughput_prompt = (
        "Answer the following financial question clearly and accurately "
        "in no more than 3 sentences.\n\n"
        "Question: What is a 401(k) retirement plan?"
    )

    for model_id in models:

        result = measure_throughput(
            model_id,
            throughput_prompt
        )

        print(
            f"\nModel: {result['model_id']}"
            f"\nSuccessful requests: "
            f"{result['successful_requests']}/{result['total_requests']}"
            f"\nTotal time: {result['total_time']:.2f} seconds"
            f"\nRequests per second: "
            f"{result['requests_per_second']:.2f}"
        )