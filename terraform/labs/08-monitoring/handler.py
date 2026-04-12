import json
import logging

# X-Ray SDK — uncomment after adding the layer or installing aws-xray-sdk
# from aws_xray_sdk.core import xray_recorder, patch_all
# patch_all()

logger = logging.getLogger()
logger.setLevel(logging.INFO)


def lambda_handler(event, context):
    logger.info("Processing event: %s", json.dumps(event))

    # Simulate an error ~30% of the time to trigger the error-rate alarm
    import random
    if random.random() < 0.3:
        raise Exception("Simulated error — check CloudWatch Logs and X-Ray")

    return {"status": "ok"}
