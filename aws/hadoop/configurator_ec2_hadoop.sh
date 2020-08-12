#!/bin/bash

USER="ykumarbekov"

yum update -y
yum install git -y
wget https://corretto.aws/downloads/latest/amazon-corretto-8-x64-linux-jdk.rpm
wget https://downloads.apache.org/hadoop/common/hadoop-2.9.2/hadoop-2.9.2.tar.gz
yum localinstall amazon-corretto-8-x64-linux-jdk.rpm -y
tar -xf hadoop-2.9.2.tar.gz -C /usr/local
# ##########
echo "export JAVA_HOME=/usr/lib/jvm/java-1.8.0-amazon-corretto" >> /root/.bash_profile
test -d /usr/local/hadoop-2.9.2 &&
echo "export HADOOP_HOME=/usr/local/hadoop-2.9.2" >> /root/.bash_profile && \
echo "export HADOOP_CONF_DIR=/usr/local/hadoop-2.9.2/etc/hadoop" >> /root/.bash_profile && \
echo "export HADOOP_MAPRED_HOME=/usr/local/hadoop-2.9.2" >> /root/.bash_profile && \
echo "export HADOOP_HDFS_HOME=/usr/local/hadoop-2.9.2" >> /root/.bash_profile && \
echo "export YARN_HOME=/usr/local/hadoop-2.9.2" >> /root/.bash_profile && \
#echo "PATH=$PATH:$HADOOP_HOME/bin" >> /root/.bash_profile
# ##########
git clone https://github.com/ykumarbekov/aws-gridu-project.git /opt/aws-gridu-project
# ##########
/bin/cp /opt/aws-gridu-project/aws/hadoop/core-site.xml /usr/local/hadoop-2.9.2/etc/hadoop/
/bin/cp /opt/aws-gridu-project/aws/hadoop/hdfs-site.xml /usr/local/hadoop-2.9.2/etc/hadoop/
/bin/cp /opt/aws-gridu-project/aws/hadoop/mapred-site.xml /usr/local/hadoop-2.9.2/etc/hadoop/
/bin/cp /opt/aws-gridu-project/aws/hadoop/yarn-site.xml /usr/local/hadoop-2.9.2/etc/hadoop/

sed -i 's/export JAVA_HOME=${JAVA_HOME}/export JAVA_HOME=\/usr\/lib\/jvm\/java-1.8.0-amazon-corretto/' /usr/local/hadoop-2.9.2/etc/hadoop/hadoop-env.sh
