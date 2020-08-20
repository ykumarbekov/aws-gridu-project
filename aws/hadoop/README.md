Hadoop single node cluster for Test purposes based on EC2 instances  
---
Steps:  
1. Run: aws/hadoop/init_ec2.sh // don't forget to add your public IP address (you see it during script running)  
   Open script init_ec2.sh and find next variable: INSTANCE_TYPE="t3.micro"  
   You can change it according with your requirements (view all options on AWS official documentation)  
2. Open SSH session (use ./auth/[user-key].pem) and perform next steps manually: 
   cd $HADOOP_HOME  
   bin/hdfs namenode -format  
   // Start Hadoop  
   sbin/start-dfs.sh  
   sbin/start-yarn.sh  
   // Create Hive warehouse dir  
   hdfs dfs -mkdir -p /user/hive/warehouse  
   hdfs dfs -mkdir /tmp  
   // Start Derby  
   cd /usr/local/derby && nohup ./bin/startNetworkServer -h 0.0.0.0 &  
   // Init Hive schema && check version  
   cd /usr/local/hive/bin && ./schematool -initSchema -dbType derby  
   hive --version  
   // Now your cluster is ready to work  
   // Explore HDFS FS: http://[EC2 DNS Name]:50070  
    