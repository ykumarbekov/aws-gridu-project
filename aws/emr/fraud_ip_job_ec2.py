import sys
import boto3
from pyspark import SparkConf
from pyspark.sql import SparkSession
from pyspark.sql.functions import count, col


if __name__ == "__main__":
    if len(sys.argv) != 3:
        print("Usage: emp_spark_step.py s3://BUCKET/logs/views Table", file=sys.stderr)
        exit(-1)
    # ***********
    inp = sys.argv[1]
    table = sys.argv[2]
    conf = SparkConf()
    conf.setAppName("Fraud-ip-ec2-job")
    conf.setMaster('local')
    conf.set("spark.hadoop.fs.s3a.impl", "org.apache.hadoop.fs.s3a.S3AFileSystem")
    spark = SparkSession.builder.config(conf=conf).getOrCreate()
    df = spark.read.format("json").load(inp)
    df1 = df.groupBy("timestamp", "ip").agg(count("ip").alias("ip_count"))
    df2 = df1.filter(col("ip_count") >= 5).select("ip").distinct()
    ip_list = df2.rdd.map(lambda x: x.ip).collect()
    # ***********
    dynamodb = boto3.resource('dynamodb')
    ddb_table = dynamodb.Table(table)
    for ip in ip_list:
        ddb_table.put_item(Item={'ip': ip})



