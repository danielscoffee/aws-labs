import base64
import json


def lambda_handler(event, context):
    """Decodes and prints Kinesis records."""
    for record in event.get("Records", []):
        shard_id = record["kinesis"]["partitionKey"]
        seq = record["kinesis"]["sequenceNumber"]
        payload = json.loads(base64.b64decode(record["kinesis"]["data"]).decode("utf-8"))
        print(f"[shard={shard_id} seq={seq}] {json.dumps(payload)}")
    return {"processed": len(event.get("Records", []))}
