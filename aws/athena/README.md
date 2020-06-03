AWS Athena  
Task:  
- Use Athena to calculate distribution of views by device types.  
- Render collected statistics in QuickSight  
----
For Athena we'll use AWS Glue Data Catalog where we defined Crawlers for S3 Logs folders  
Use script init_data.sh for querying Logs folder, result of the query you can use for Dashboard   