import json
import os

def lambda_handler(event, context):
    print("Event:", json.dumps(event))
    return {
        "statusCode": 200,
        "headers": {"Content-Type": "application/json"},
        "body": json.dumps({
            "message": "Hello from Lambda!",
            "path": event.get("path", "/"),
            "method": event.get("httpMethod", ""),
            "env": os.environ.get("ENV", ""),
        }),
    }
