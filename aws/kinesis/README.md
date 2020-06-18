1. Use Kinesis Data Streams and Kinesis Analytics to identify the most popular 10 items and categories by views  
2. Use Lambda to set up SNS email notification, if number of views exceeds 1000 for top 10 items  
----
Follow the next rules to run job:  
1) Edit values from the script: aws/kinesis/analytics.sh
```
USER="ykumarbekov"
USER_EMAIL="yermek.kumarbekov@gmail.com"
```
run script: aws/kinesis/analytics.sh  
This script creates: Kinesis streams, application for Kinesis analytics, configures input and output for Application  
2) Edit values from the script aws/kinesis/lambda.sh
```
USER="ykumarbekov"
USER_EMAIL="yermek.kumarbekov@gmail.com"
```
run script: aws/kinesis/lambda.sh  
This script creates SNS topic, sets subscription, creates and configures Lambda function

As a result after successfully implementation, you should receive emails on your mailbox   

