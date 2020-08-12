Filter data from blocked IPs via Glue and store into S3 bucket.  
  Sources:   
  - Dynamodb table  
  - s3:/{BUCKET}/logs/views/  
  - Output folder: s3://{BUCKET}/glue/target/  
----
Steps:
1. Create role: {USER}_glue:  
   Add policies: See folder: roles/policies - glue_access.json, glue_trust_policy.json        
2. Create crawlers:  
   2.1 Create database: {USER}-gluedb  
   2.2 Crawlers:  
        - crawler: {USER}-s3-views-logs: JSON logs: s3:/${BUCKET}/logs/views/                
        - crawler: {USER}-fraud-ip: Dynamodb table  
   2.3 Run and create tables: fraud_ip_{USER}, views    
3. Create and run Job: {USER}-filter-views, see script: etl_script.py    
----  
Local testing:  
Preparing environment  
1. Follow instructions: https://docs.aws.amazon.com/glue/latest/dg/aws-glue-programming-etl-libraries.html  
2. set SPARK_HOME, JAVA_HOME, use java version 8  
3. export AWS_REGION=us-east-1  
4. cd ../aws-glue-libs  
5. run: ./bin/gluesparksubmit ../aws-gridu-project/aws/glue/test-glue-1.py        
    
    