import importlib.util
import json
import os

_spec = importlib.util.spec_from_file_location(
    __name__ + ".handler",
    os.path.join(os.path.dirname(__file__), "..", "handler.py"),
)
if _spec is None or _spec.loader is None:
    raise ImportError("handler.py not found")
_mod = importlib.util.module_from_spec(_spec)
_spec.loader.exec_module(_mod)
lambda_handler = _mod.lambda_handler


def _sqs_event(payload: dict):
    """Simulates SNS → SQS delivery: SQS body wraps the SNS envelope."""
    sns_envelope = json.dumps({"Message": json.dumps(payload)})
    return {"Records": [{"body": sns_envelope}]}


def test_single_message_processed():
    event = _sqs_event({"type": "order", "id": "ord-1"})
    result = lambda_handler(event, {})
    assert result["processed"] == 1


def test_multiple_messages():
    records = [
        {"body": json.dumps({"Message": json.dumps({"id": 1})})},
        {"body": json.dumps({"Message": json.dumps({"id": 2})})},
    ]
    result = lambda_handler({"Records": records}, {})
    assert result["processed"] == 2
