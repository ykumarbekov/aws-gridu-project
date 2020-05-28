#!/bin/bash

yum update -y
yum install git -y
yum install wget -y
yum install java-1.8.0-openjdk.x86_64 -y
yum remove java-1.7.0-openjdk -y
git clone https://github.com/ykumarbekov/aws-gridu-project.git /opt/aws-gridu-project
# ######
cd /opt
wget http://mirror.linux-ia64.org/apache/spark/spark-2.4.5/spark-2.4.5-bin-hadoop2.7.tgz
tar zxf spark-2.4.5-bin-hadoop2.7.tgz --transform s/spark-2.4.5-bin-hadoop2.7/spark-2.4.5/
