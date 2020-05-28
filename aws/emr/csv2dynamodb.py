#!/usr/bin/env python
import argparse as arg
import boto3


def cmd_parser():
    result = {}
    try:
        p = arg.ArgumentParser(prog="csv2dynamodb", usage="%(prog)s parameters", description="")
        p.add_argument(
            "--input-key",
            help="Input folder. Must be provided",
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


def get_matching_s3_keys(s3_, bucket_, prefix='', suffix=''):
    kwargs = {'Bucket': bucket_}
    if isinstance(prefix, str):
        kwargs['Prefix'] = prefix
    while True:
        # The S3 API response is a large blob of metadata.
        # 'Contents' contains information about the listed objects.
        resp = s3.list_objects_v2(**kwargs)
        if 'Contents' in resp:
            for obj_ in resp['Contents']:
                key_ = obj_['Key']
                if key_.startswith(prefix) and key_.endswith(suffix):
                    yield key_
        # The S3 API is paginated, returning up to 1000 keys at a time.
        # Pass the continuation token into the next response, until we
        # reach the final page (when this field is missing).
        try:
            kwargs['ContinuationToken'] = resp['NextContinuationToken']
        except KeyError:
            break


if __name__ == "__main__":
    data = cmd_parser()
    if data:
        s3 = boto3.client("s3")
        dynamodb = boto3.resource('dynamodb')
        ddb_table = dynamodb.Table(data['table'])
        inp_key = data['inp_key']
        bucket = data['bucket_id']
        for key in get_matching_s3_keys(s3_=s3, bucket_=bucket, prefix=inp_key, suffix='.csv'):
            print(key)
            ip_data = s3.get_object(Bucket=bucket, Key=key)
            ip_list = [x for x in str(ip_data['Body'].read().decode('utf-8')).split("\n") if len(x) > 0]
            for ip in ip_list:
                ddb_table.put_item(Item={'ip': ip})



