#!/bin/bash

yum update -y
yum install python36 -y
yum install postgresql96.x86_64 -y
yum install git -y
git clone https://github.com/ykumarbekov/aws-gridu-project.git /opt/aws-gridu-project
mkdir /opt/logs
chmod +x /opt/aws-gridu-project/code/runner.sh
chmod +x /opt/aws-gridu-project/aws/rds_init.sh
echo "*/30 * * * * /opt/aws-gridu-project/code/runner.sh" > /tmp/usrcrontab
echo "*/5 * * * * /opt/aws-gridu-project/aws/rds_init.sh >> /opt/rds_init.log" >> /tmp/usrcrontab
crontab /tmp/usrcrontab



