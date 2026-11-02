import boto3
import json
import os


bedrock = boto3.client("bedrock-runtime")
appconfig_data = boto3.client("appconfigdata")


def get_configuration(profile_name):
    """
    Retrieves the latest deployed AppConfig configuration
    for the requested configuration profile.
    """

    session = appconfig_data.start_configuration_session(
        ApplicationIdentifier=os.environ["APPCONFIG_APPLICATION_ID"],
        EnvironmentIdentifier=os.environ["APPCONFIG_ENVIRONMENT_ID"],
        ConfigurationProfileIdentifier=profile_name
    )

    response = appconfig_data.get_latest_configuration(
        ConfigurationToken=session["InitialConfigurationToken"]
    )

    content = response["Configuration"].read()

    if not content:
        return {}

    return json.loads(content.decode("utf-8"))


def select_model(model_config, feature_flags):
    """
    Selects the Bedrock model to use.

    If the model override feature flag is enabled, the override
    model is used. Otherwise, the benchmark-selected primary
    model is used.
    """

    model_override = feature_flags.get(
        "model_override",
        {}
    )

    if model_override.get("enabled"):
        return model_override["model_id"]

    return model_config["primary_model"]


def invoke_model(model_id, prompt):
    """
    Sends the user's prompt to the selected Bedrock model
    using the Converse API.
    """

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
            "maxTokens": 300,
            "temperature": 0.2
        }
    )

    return response[
        "output"
    ][
        "message"
    ][
        "content"
    ][0][
        "text"
    ]


def lambda_handler(event, context):
    """
    Receives the API Gateway request, retrieves model configuration
    from AppConfig, selects a model, invokes Bedrock, and returns
    the generated response.
    """

    body = json.loads(
        event.get(
            "body",
            "{}"
        )
    )

    prompt = body.get(
        "prompt",
        ""
    )

    model_config = get_configuration(
        os.environ["MODEL_CONFIG_PROFILE_ID"]
    )

    feature_flags = get_configuration(
        os.environ["FEATURE_FLAG_PROFILE_ID"]
    )

    model_id = select_model(
        model_config,
        feature_flags
    )

    response = invoke_model(
        model_id,
        prompt
    )

    return {
        "statusCode": 200,

        "headers": {
            "Content-Type": "application/json"
        },

        "body": json.dumps({
            "model_used": model_id,
            "response": response
        })
    }