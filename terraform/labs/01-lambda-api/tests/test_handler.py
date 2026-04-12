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


def _api_event(path="/hello", method="GET"):
    return {"path": path, "httpMethod": method, "body": None, "headers": {}}


def test_returns_200():
    resp = lambda_handler(_api_event(), {})
    assert resp["statusCode"] == 200


def test_body_contains_path():
    resp = lambda_handler(_api_event(path="/foo"), {})
    body = json.loads(resp["body"])
    assert body["path"] == "/foo"


def test_method_echoed():
    resp = lambda_handler(_api_event(method="POST"), {})
    body = json.loads(resp["body"])
    assert body["method"] == "POST"
