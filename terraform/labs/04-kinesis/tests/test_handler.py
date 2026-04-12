import base64
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


def _kinesis_record(payload: dict, partition_key="pk-1", seq="001"):
    return {
        "kinesis": {
            "partitionKey": partition_key,
            "sequenceNumber": seq,
            "data": base64.b64encode(json.dumps(payload).encode()).decode(),
        }
    }


def test_single_record():
    event = {"Records": [_kinesis_record({"event": "click", "user": "u1"})]}
    result = lambda_handler(event, {})
    assert result["processed"] == 1


def test_batch_records():
    records = [_kinesis_record({"i": i}, seq=str(i)) for i in range(5)]
    result = lambda_handler({"Records": records}, {})
    assert result["processed"] == 5
