import sys
from awsglue.transforms import *
from awsglue.utils import getResolvedOptions
from pyspark.context import SparkContext
from awsglue.context import GlueContext
from awsglue.job import Job

## @params: [JOB_NAME]
args = getResolvedOptions(sys.argv, ['JOB_NAME'])

sc = SparkContext()
glueContext = GlueContext(sc)
spark = glueContext.spark_session
job = Job(glueContext)
job.init(args['JOB_NAME'], args)

# ##############################
fraud_ip = glueContext.create_dynamic_frame.from_catalog(database="ykumarbekov_gluedb",
                                                         table_name="fraud_ip_ykumarbekov",
                                                         transformation_ctx="datasource0").toDF()
views = glueContext.create_dynamic_frame.from_catalog(database="ykumarbekov_gluedb", table_name="views",
                                                      redshift_tmp_dir=args["TempDir"],
                                                      transformation_ctx="<transformation_ctx>").toDF()
# ##############################
result = fraud_ip.join(views, fraud_ip["ip"] == views["ip"], "inner") \
    .select(
    views["ip"],
    views["isbn"],
    views["device_type"],
    views["device_id"])
# ##############################
result.repartition(1).write.format("json").mode("overwrite").save("s3://ykumarbekov-534348/glue/target/")
# ##############################
# applymapping1 = ApplyMapping.apply(frame = datasource0, mappings = [("ip", "string", "ip", "string")], transformation_ctx = "applymapping1")
# ##############################
# datasink2 = glueContext.write_dynamic_frame.from_options(frame = applymapping1, connection_type = "s3", connection_options = {"path": "s3://ykumarbekov-534348/glue/target/"}, format = "json", transformation_ctx = "datasink2")
job.commit()