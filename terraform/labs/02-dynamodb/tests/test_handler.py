import importlib.util
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


def _stream_event(event_name="INSERT", new_image=None, old_image=None):
    record = {
        "eventName": event_name,
        "dynamodb": {},
    }
    if new_image:
        record["dynamodb"]["NewImage"] = new_image
    if old_image:
        record["dynamodb"]["OldImage"] = old_image
    return {"Records": [record]}


def test_insert_processed():
    event = _stream_event("INSERT", new_image={"pk": {"S": "order#1"}, "status": {"S": "PENDING"}})
    result = lambda_handler(event, {})
    assert result["processed"] == 1


def test_remove_processed():
    event = _stream_event("REMOVE", old_image={"pk": {"S": "order#1"}})
    result = lambda_handler(event, {})
    assert result["processed"] == 1


def test_empty_event():
    result = lambda_handler({"Records": []}, {})
    assert result["processed"] == 0
