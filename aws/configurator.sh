#!/bin/bash

PROJECT=/opt/aws-gridu-project

yum update -y
yum install python36 -y
yum install git -y
git clone https://github.com/ykumarbekov/aws-gridu-project.git $PROJECT
mkdir /opt/logs
chmod +x $PROJECT/code/runner.sh
touch /var/spool/cron/$USER
echo "10 * * * * $PROJECT/code/runner.sh"| tee -a /var/spool/cron/$USER
crontab -u $USER -l