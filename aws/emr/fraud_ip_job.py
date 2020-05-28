import sys
import boto3
from pyspark.sql import SparkSession
from pyspark.sql.functions import count, col


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
    df2 = df1.filter(col("ip_count") >= 5).select("ip").distinct()
    df1\
        .filter(col("ip_count") >= 5).select("ip").distinct()\
        .coalesce(1)\
        .write\
        .format("csv")\
        .mode('overwrite')\
        .save(out_p)

    from pyspark.sql import Row
    # rdd = spark.sparkContext.parallelize(["msg 1", "msg 2"])
    # rdd.saveAsTextFile(out_p)
    # ***********
    # dynamodb = boto3.resource('dynamodb')
    # ddb_table = dynamodb.Table(table)
    # for ip in ip_list: ddb_table.put_item(Item={'ip': ip})


