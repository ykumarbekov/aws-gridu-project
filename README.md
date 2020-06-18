## AWS-Gridu course Capstone project

_The Legend_  
This is online bookstore, the catalog contains most popular books, which everyone can view or buy from the store  
Folder: _catalog/books.csv_ - contains example of the books catalog  
For every book we have next fields: ISBN - uniquely identifies item, Title, Publisher and Category  
Example of Item:  
```
0782140661, OCP: Oracle9i Certification Kit, Sybex, Computer
0142001740|The Secret Life of Bees|Penguin USA |Literature & Fiction
...
``` 
Our online bookstore generates log files in JSON format every 30 minutes, to simulate this behaviour we use Python script  
Below you'll find rules for the script:  
```
# 1st Step is generating USERS:
PROJECT_FOLDER="/opt/aws-gridu-project"

python3 $PROJECT_FOLDER/code/users_list_gen.py --number 100 > $PROJECT_FOLDER/user_data/users.csv
```
The content of the generated users.csv is:  
```
device_type|device_id|ip
WINDOWS|459d3325-1101-4777-a3b8-d5a15018c3ba|68.226.92.48
...
```
where device_type: [WINDOWS, IOS, ANDROID, LINUX] - we use this file for generating views, reviews logs  
```
# 2nd Step is generating JSON log files: views.log, reviews.log  
python3 $PROJECT_FOLDER/code/runner.py \
--catalog=$PROJECT_FOLDER/catalog/books.csv \
--users_list=$PROJECT_FOLDER/user_data/users.csv \
--reviews=$PROJECT_FOLDER/user_data/reviews.csv \
--output=$EC2_LOGS --timedelta=10 --number=10000

# where number - the number of generated items for the views.log, 
# timedelta - random generated time for the user. 
# users.csv - the file generated on the 1st Step
# reviews.csv - randomly generated file which contains pre-defined user's reviews
```
This script generates next files:  views.log, see sample:  
Pay attention: timestamp is random generated time between script running time and minus delta 10 minutes  
```
{"ISBN": "0345376595", "timestamp": "15.06.2020 15:51:02", "device_type": "IOS", "device_id": "2fb3d05c-9ce2-45ef-8e10-709338bf7268", "ip": "186.20.254.35"}
...
```
and reviews.log
```
{"ISBN": "0072294337", "timestamp": "15.06.2020 15:50:00", "device_type": "ANDROID", "device_id": "7f5dd778-c4e9-4d8b-823e-6edb196977c7", 
"ip": "24.65.107.103", "review": {"source": ....Gotta entertain yourselves somehow!"}, "rating": "5"}
...
```
These files simulates visiting online bookstore and we can use these files for AWS processing  

Preparing environment:  
1) clone the project: git clone ...  
2) cd {cloned project} // Example: cd aws-project  
3) Create folder inside the project: mkdir ./auth,  
4) Add file: touch ./auth/pwd.id  // this file contains login and passwords //  
   Fill up the file: pwd.id, follow the next rules:  
   - Every row contains information in the columns: 1st: service type; 2nd: username; 3rd: password  
   - Example: rds user password  

aws/main_init.sh is a first script we use in our project:   
- Prepares and deploys working AWS environment, to run this script, must be AWS CLI installed locally,  
please be sure you configured - AWS_PROFILE="aws-gridu" and you have enough rights and permissions to create objects on AWS cloud   
Also you should edit next variables, change it with your values: 
```
# ### script: aws/main_init.sh
USER="ykumarbekov"
SG_EC2="yk-ec2-534348" ### Security Group for EC2 instance
SG_RDS="yk-rds-534348" ### Security Group for RDS instance
BUCKET="ykumarbekov-534348"

# ### script: aws/configurator.sh
USER="ykumarbekov"
```  
This script performs next actions:  
- creates EC2 instance, deploys project, configures CRON job for generating log files, starts kinesis-agent and configures RDS PostgreSQL database  
  more details you can find at aws/configurator.sh which uses as a bootstrap script  
- creates AWS Role, Security groups, Bucket with all necessary folders, RDS instance and DynamoDB tables  
After it successfully finished we receive generated log files on the Bucket at folders: logs/views; logs/reviews  

Detailed instructions and descriptions related to the project:  
- Generating source data:  
  aws/main_init.sh - responsible for this point  
- Identify and filter suspicious IPs:  
  - Implement EMR Spark application, which should identify fraudulent IPs and store them into DynamoDB  
  aws/emr - contains all necessary to perform this point  
  - After that filter data from blocked IPs via Glue and store into S3 bucket  
  aws/glue - contains all necessary to perform this point  
- Get the most popular items and categories  
  - Use Kinesis Data Streams and Kinesis Analytics to identify the most popular 10 items and categories by views  
  - Use Lambda to set up SNS email notification, if number of views exceeds 1000 for top 10 items  
  aws/kinesis - contains all necessary to perform this point  
- Get views distribution by device type
  - Use Athena to calculate distribution of views by device types. Render collected statistics in QuickSight  
  aws/athena - contains all necessary to perform this point  
- Detect spam in reviews  
  - Use any open dataset with training data to build spam detection classifier using SageMaker ML models  
  - Set up batch transform job and generate predictions for reviews, based on concatenated title and text of review  
  - Use CloudWatch event (new input in S3) to trigger Lambda function which should launch batch transform job.  
  aws/sagemaker - contains all necessary to perform this point  
  
All sub-folders contain README.md file which helps to clarify details and algorithms uses to realize that point  
  


 