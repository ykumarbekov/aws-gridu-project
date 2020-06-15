import boto3
from urllib.parse import unquote_plus
from datetime import datetime

s3 = boto3.client('s3')
sm = boto3.client('sagemaker')
model_name = 'ykumarbekov-bt-capstone-model'
job_name = "ykumarbekov-bt-job-" + datetime.now().strftime("%d%m%Y%H%M%S")


def lambda_handler(event, context):
    for record in event['Records']:
        bucket = record['s3']['bucket']['name']
        key = unquote_plus(record['s3']['object']['key'])
        input_path = 's3://{}/{}'.format(bucket, key)
        output_path = 's3://{}/{}/'.format(bucket, 'logs/predictions')
        request = \
            {
                "TransformJobName": job_name,
                "ModelName": model_name,
                "BatchStrategy": "MultiRecord",
                "TransformOutput": {
                    "S3OutputPath": output_path,
                    "AssembleWith": "Line",
                    "Accept": "application/jsonlines"
                },
                "TransformInput": {
                    "DataSource": {
                        "S3DataSource": {
                            "S3DataType": "S3Prefix",
                            "S3Uri": input_path
                        }
                    },
                    "ContentType": "application/jsonlines",
                    "SplitType": "Line",
                },
                "TransformResources": {
                    "InstanceType": "ml.m4.xlarge",
                    "InstanceCount": 1
                },
                "DataProcessing": {
                    "InputFilter": "$.review",
                    "OutputFilter": "$",
                    "JoinSource": "Input"
                }
            }
        sm.create_transform_job(**request)

    return
