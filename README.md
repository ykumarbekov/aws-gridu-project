AWS-Gridu course Capstone project
-----------
1. Script: init.sh:
   - Creating Security Groups for EC2, RDS
   - Re-Creating Bucket and Folders:
     - logs/[views, reviews]; config; emr/[logs, code]
   - Copies fraud_ip_job.py to S3 Bucket - for Spark cluster
   - Re-Creating RDS: PostgreSQL
   - Creating EC2 instance:
     - bootstrap scripts: configurator.sh, rds_init.sh, rds_catalog_table.sql
     - creating EC2 key pair
     - creating Instance Profile & Attaching ROLE  
   - Creating DynamoDB table
 As result - after successful completion of the init.sh script, we should receive EC2 instance with Log generator
 Generated logs are saving on s3 Bucket at folders: logs[views, reviews]
 
 2. Script: emr_init.sh:
    - Creating EMR Cluster
    - Adding Spark job - results must be saved on folder: emr/result/ip_fraud & saved on DynamoDB table
 
 3. Filtering data from blocked IPs via Glue and store into S3 bucket