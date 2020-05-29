Setup Glue service, steps:
1. Create role: {USER}_glue:  
   Add policies: See folder: roles/policies - glue_access.json, dynamo_access.json        
2. Create crawlers:  
   2.1 Create database: {USER}-gluedb  
   2.2 Crawlers:  
        - crawler: {USER}-s3-views-logs: JSON logs:               
        - crawler: {USER}-fraud-ip: Dynamodb table  
   2.3 Run and create tables: fraud_ip_{USER}, views    
3. Create Job: {USER}-filter-views, see script: etl_script.py          
    
    