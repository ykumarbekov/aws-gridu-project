import sys
from pyspark.sql import SparkSession
from awsglue.context import GlueContext
import pyspark.sql.functions as f
from awsglue.utils import getResolvedOptions
from awsglue.job import Job
from datetime import datetime


if __name__ == "__main__":
    glueDB = ""
    table = ""
    bucket = ""
    job_name = ""

    try:
        ## @params: [JOB_NAME]
        args = getResolvedOptions(sys.argv, ['gluedb', 'table', 'bucket', 'JOB_NAME'])
        glueDB = args['gluedb']
        table = args['table']
        bucket = args['bucket']
    except Exception as e:
        print(e)
        sys.exit(-1)

    if glueDB and table and bucket:
        spark = SparkSession.builder.appName("FIND-IPS").getOrCreate()
        sc = spark.sparkContext
        glueContext = GlueContext(sc)
        # GlueContext - Wraps the Apache SparkSQL SQLContext object
        # provides mechanisms for interacting with the Apache Spark platform

        # **** Alternative code
        # ## @params: [JOB_NAME] (params we pass --job-name)
        # args = getResolvedOptions(sys.argv, ['JOB_NAME'])
        # from pyspark.context import SparkContext
        # sc = SparkContext()
        # glueContext = GlueContext(sc)
        # spark = glueContext.spark_session
        #
        # job = Job(glueContext)
        # job.init(args['JOB_NAME'], args)
        # ****

        job = Job(glueContext)
        job.init(args['JOB_NAME'], args)

        current_date = "(year == '" + datetime.now().strftime("%Y") + \
                       "' and month == '" + datetime.now().strftime("%m") + \
                       "' and day =='" + datetime.now().strftime("%d") + "')"

        views = glueContext.create_dynamic_frame\
            .from_catalog(
                database=glueDB,
                table_name=table,
                push_down_predicate=current_date).toDF()

        # Get suspicious IP: group by timestamp and IP and filter count >= 5
        filterIp = views.groupBy("timestamp", "ip").agg(f.count("*").alias("count"))
        result = filterIp.filter(f.col("count") >= 5).select("ip", "timestamp", "count")

        # result.show()
        # Save it in S3 bucket
        current_date = datetime.now().strftime("%Y%m%d")
        result.repartition(1).write.format("json")\
            .mode("overwrite")\
            .save("s3://" + bucket + "/glue/target/" + current_date + "/")

        job.commit()
