import json


def lambda_handler(event, context):
    """Prints DynamoDB stream records — check CloudWatch Logs after a PutItem."""
    for record in event.get("Records", []):
        event_name = record["eventName"]  # INSERT | MODIFY | REMOVE
        new_image = record.get("dynamodb", {}).get("NewImage", {})
        old_image = record.get("dynamodb", {}).get("OldImage", {})
        print(f"[{event_name}] new={json.dumps(new_image)} old={json.dumps(old_image)}")
    return {"processed": len(event.get("Records", []))}
