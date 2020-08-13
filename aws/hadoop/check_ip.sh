#!/bin/bash


echo "Opening additional ports: HDFS: 50070; YARN RESOURCE MANAGER: 8088"
read -p "Please enter your public IP ADDRESS, visit: https://www.showmyip.com/ :" ip
test -z ${ip} && echo "Cannot identify IP address" && exit 1
test -z $(echo ${ip}|grep -oE "\b([0-9]{1,3}\.){3}[0-9]{1,3}\b") && echo "Incorrect IP address" && exit 1

echo ${ip}