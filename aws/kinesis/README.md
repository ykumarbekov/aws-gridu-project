Kinesis Data Streams, Analytics and Lambda  
Task:   
1. Use Kinesis Data Streams and Kinesis Analytics to identify the most popular 10 items and categories by views  
2. Sse Lambda to set up SNS email notification, if number of views exceeds 1000 for top 10 items  
----
Main running script: main.sh, contains sub-scripts:  
- analytics.sh: Creates role; Kinesis streams and Kinesis Analytics  
- lambda.sh: Initializes lambda script and sns subscription  

