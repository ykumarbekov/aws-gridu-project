import boto3
import base64

client = boto3.client("sns")
topic_arn = ""


def sns_trigger(event, context):
    try:
        for record in event['Records']:
            payload = base64.b64decode(record["kinesis"]["data"])
            client.publish(TopicArn=topic_arn, Message=payload, Subject="Top 100 Hits Books Views")
            print("Successfully delivered message")
    except Exception:
        print("Failed...")

