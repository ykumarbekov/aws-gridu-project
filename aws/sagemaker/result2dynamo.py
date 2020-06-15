#!/usr/bin/env python
import argparse as arg
import json
import boto3


def cmd_parser():
    result = {}
    try:
        p = arg.ArgumentParser(prog="result2dynamo", usage="%(prog)s parameters", description="")
        p.add_argument(
            "--input-key",
            help="Source file. Must be provided",
            required=True,
            dest="inp_key"
        )
        p.add_argument(
            "--bucket",
            help="Bucket. Must be provided",
            required=True,
            dest="bucket_id"
        )
        p.add_argument(
            "--table",
            help="DynamoDB Table. Must be provided",
            required=True,
            dest="table"
        )
        a = p.parse_args()
        result["inp_key"] = a.inp_key
        result["bucket_id"] = a.bucket_id
        result["table"] = a.table
    except Exception as ex:
        print(ex)
        return {}

    return result


if __name__ == "__main__":
    data = cmd_parser()
    if data:
        s3 = boto3.client("s3")
        dynamodb = boto3.resource('dynamodb')
        ddb_table = dynamodb.Table(data['table'])
        inp_key = data['inp_key']
        bucket = data['bucket_id']
        data = s3.get_object(Bucket=bucket, Key=inp_key)
        lst = [x for x in str(data['Body'].read().decode('utf-8')).split("\n") if len(x) > 0]
        ham = 0
        r = 0
        for i in lst:
            d = json.loads(i)
            label = ''.join(d['SageMakerOutput']['label'])
            if 'ham' in label:
                r = r + int(d['rating'])
                ham = ham + 1

        ddb_table.put_item(Item={'item': str(round(r/ham, 4))})

