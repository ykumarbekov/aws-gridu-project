Identify and filter suspicious IPs  
Description:  
aws/emr/init.sh - script for initializing EMR cluster and running script: fraud_ip_job_ec2.py  
fraud_ip_job_ec2.py - identifies fraudulent IPs  
Be sure you changed these values from the script: aws/emr/init.sh:  
```  
USER="ykumarbekov"
BUCKET="ykumarbekov-534348"
SG_EC2="yk-ec2-534348"
```
