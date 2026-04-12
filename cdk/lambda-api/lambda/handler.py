import json
import os
import boto3

dynamodb = boto3.resource("dynamodb")
table = dynamodb.Table(os.environ["TABLE_NAME"])


def lambda_handler(event, context):
    method = event.get("httpMethod", "GET")
    path   = event.get("path", "/")

    if method == "POST":
        body = json.loads(event.get("body") or "{}")
        table.put_item(Item={"pk": body.get("pk", "demo"), "sk": body.get("sk", "1"), **body})
        return _resp(201, {"created": True})

    if method == "GET":
        result = table.scan(Limit=10)
        return _resp(200, {"items": result.get("Items", [])})

    return _resp(405, {"error": "method not allowed"})


def _resp(status: int, body: dict):
    return {
        "statusCode": status,
        "headers": {"Content-Type": "application/json"},
        "body": json.dumps(body),
    }
