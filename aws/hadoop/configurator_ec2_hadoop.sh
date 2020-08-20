#!/bin/bash

USER="ykumarbekov"

yum update -y
yum install git -y
# AWS JDK Coretto 8
wget https://corretto.aws/downloads/latest/amazon-corretto-8-x64-linux-jdk.rpm
yum localinstall amazon-corretto-8-x64-linux-jdk.rpm -y
echo "export JAVA_HOME=/usr/lib/jvm/java-1.8.0-amazon-corretto" >> /root/.bash_profile
# Apache Derby
wget https://downloads.apache.org/db/derby/db-derby-10.14.2.0/db-derby-10.14.2.0-bin.tar.gz
tar -xf db-derby-10.14.2.0-bin.tar.gz -C /usr/local
test -d /usr/local/db-derby-10.14.2.0-bin && mv /usr/local/db-derby-10.14.2.0-bin /usr/local/derby
# Apache Hadoop
wget https://downloads.apache.org/hadoop/common/hadoop-2.9.2/hadoop-2.9.2.tar.gz
tar -xf hadoop-2.9.2.tar.gz -C /usr/local
test -d /usr/local/hadoop-2.9.2 &&
echo "export HADOOP_HOME=/usr/local/hadoop-2.9.2" >> /root/.bash_profile && \
echo "export HADOOP_CONF_DIR=/usr/local/hadoop-2.9.2/etc/hadoop" >> /root/.bash_profile && \
echo "export HADOOP_MAPRED_HOME=/usr/local/hadoop-2.9.2" >> /root/.bash_profile && \
echo "export HADOOP_HDFS_HOME=/usr/local/hadoop-2.9.2" >> /root/.bash_profile && \
echo "export YARN_HOME=/usr/local/hadoop-2.9.2" >> /root/.bash_profile
# Apache Hive
wget https://downloads.apache.org/hive/hive-2.3.7/apache-hive-2.3.7-bin.tar.gz
tar -xf apache-hive-2.3.7-bin.tar.gz -C /usr/local
test -d /usr/local/apache-hive-2.3.7-bin && \
mv /usr/local/apache-hive-2.3.7-bin /usr/local/hive && \
echo "export HIVE_HOME=/usr/local/hive" >> /root/.bash_profile && \
echo "export HIVE_CONF_DIR=/usr/local/hive/conf" >> /root/.bash_profile && \
/bin/cp /opt/aws-gridu-project/aws/hadoop/hive-default.xml /usr/local/hive/conf/
# ##########
git clone https://github.com/ykumarbekov/aws-gridu-project.git /opt/aws-gridu-project
# ##########
/bin/cp /opt/aws-gridu-project/aws/hadoop/core-site.xml /usr/local/hadoop-2.9.2/etc/hadoop/
/bin/cp /opt/aws-gridu-project/aws/hadoop/hdfs-site.xml /usr/local/hadoop-2.9.2/etc/hadoop/
/bin/cp /opt/aws-gridu-project/aws/hadoop/mapred-site.xml /usr/local/hadoop-2.9.2/etc/hadoop/
/bin/cp /opt/aws-gridu-project/aws/hadoop/yarn-site.xml /usr/local/hadoop-2.9.2/etc/hadoop/
# ##########
sed -i 's/export JAVA_HOME=${JAVA_HOME}/export JAVA_HOME=\/usr\/lib\/jvm\/java-1.8.0-amazon-corretto/' /usr/local/hadoop-2.9.2/etc/hadoop/hadoop-env.sh
# ##########
ssh-keygen -t rsa -N '' -f /root/.ssh/id_rsa
cat /root/.ssh/id_rsa.pub >> /root/.ssh/authorized_keys
ssh-keyscan -H localhost >> /root/.ssh/known_hosts
# ##########
# Disable secondary namenode starting
/bin/cp /usr/local/hadoop-2.9.2/sbin/start-dfs.sh /usr/local/hadoop-2.9.2/sbin/start-dfs.sh.copy
sed -i 's/SECONDARY_NAMENODES=\$(\$HADOOP_PREFIX\/bin\/hdfs getconf -secondarynamenodes 2>\/dev\/null)/SECONDARY_NAMENODES=""/' /usr/local/hadoop-2.9.2/sbin/start-dfs.sh
# ##########

