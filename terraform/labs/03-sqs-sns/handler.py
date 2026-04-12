import json


def lambda_handler(event, context):
    """Processes SQS messages delivered via SNS fan-out."""
    for record in event.get("Records", []):
        body = json.loads(record["body"])
        # When SNS delivers to SQS the actual message is in body["Message"]
        message = json.loads(body.get("Message", body))
        print("Received:", json.dumps(message))
    return {"processed": len(event.get("Records", []))}
