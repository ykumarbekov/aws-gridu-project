#!/bin/bash

USER="ykumarbekov"
KINESIS_DSTREAM=${USER}"-dstream"

yum update -y
yum install python36 -y
yum install postgresql96.x86_64 -y
yum install git -y
yum install aws-kinesis-agent -y
# ##########
echo "{ \"flows\": [ { \"filePattern\": \"/opt/logs_kinesis/*.log\", \"kinesisStream\": \"${KINESIS_DSTREAM}\" } ] }" \
> /etc/aws-kinesis/agent.json
# ##########
git clone https://github.com/ykumarbekov/aws-gridu-project.git /opt/aws-gridu-project
mkdir /opt/logs
mkdir /opt/logs_kinesis
chmod +x /opt/aws-gridu-project/code/runner.sh
chmod +x /opt/aws-gridu-project/aws/rds/rds_init.sh
echo "*/30 * * * * /opt/aws-gridu-project/code/runner.sh" > /tmp/usrcrontab
echo "*/5 * * * * /opt/aws-gridu-project/aws/rds/rds_init.sh" >> /tmp/usrcrontab
crontab /tmp/usrcrontab



