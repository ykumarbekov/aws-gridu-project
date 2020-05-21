#!/bin/bash

yum update -y
yum install python36 -y
yum install git -y
git clone https://github.com/ykumarbekov/aws-gridu-project.git /opt/aws-gridu-project
mkdir /opt/logs
chmod +x /opt/aws-gridu-project/code/runner.sh
# touch /var/spool/cron/$USER
echo "10 * * * * /opt/aws-gridu-project/code/runner.sh" > /tmp/usrcrontab
# echo "10 * * * * /opt/aws-gridu-project/code/runner.sh"| tee -a /tmp/usrcrontab
crontab /tmp/usrcrontab