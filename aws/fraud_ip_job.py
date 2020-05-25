from __future__ import print_function
import sys
from pyspark.sql import SparkSession
from pyspark.sql.functions import *

if __name__ == "__main__":
    if len(sys.argv) != 3:
        print("Usage: emp_spark_step.py s3://BUCKET/logs/views s3://BUCKET/emr/result/fraud_ip", file=sys.stderr)
        exit(-1)
    # ***********
    inp = sys.argv[1]
    out_p = sys.argv[2]
    spark = SparkSession.builder.appName('Fraud-ip-job').getOrCreate()
    df = spark.read.format("json").load(inp)
    df1 = df.groupBy("timestamp", "ip").agg(count("ip").alias("ip_count"))
    df1\
        .filter(col("ip_count") >= 5)\
        .select("ip")\
        .distinct()\
        .write\
        .format("csv")\
        .mode('overwrite')\
        .option("path", out_p)\
        .save()
    # ***********

