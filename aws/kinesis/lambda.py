import boto3
import base64
import json

client = boto3.client("sns")
topic_arn = "CODE"


def sns_trigger(event, context):
    try:
        for record in event['Records']:
            payload = base64.b64decode(record["kinesis"]["data"])
            d = json.loads(payload.decode("utf-8"))
            msg = "Most viewed book: {} has hits: {}".format(d["ISBN"], d["HITS"])
            client.publish(TopicArn=topic_arn, Message=msg, Subject="Top 100 Hits Books Views")
            print("Successfully delivered message")
    except Exception as err:
        print("Failed...{}".format(err))

