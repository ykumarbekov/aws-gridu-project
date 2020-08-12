#!/bin/bash

#BUCKET="ykumarbekov-534348"
BUCKET="ykumarbekov-318557"
#EC2_LOGS="/opt/logs"
EC2_LOGS="./logs"
#KINESIS_LOGS="/opt/logs_kinesis"
TARGET_FOLDER="/logs"
#PROJECT_FOLDER="/opt/aws-gridu-project"
PROJECT_FOLDER="."

# ##### LOGS GENERATING #####
# Step 1. USERS
python3 $PROJECT_FOLDER/code/users_list_gen.py --number 100 > $PROJECT_FOLDER/user_data/users.csv
# Step 2. LOGS
python3 $PROJECT_FOLDER/code/runner.py \
--catalog=$PROJECT_FOLDER/catalog/books.csv \
--users_list=$PROJECT_FOLDER/user_data/users.csv \
--reviews=$PROJECT_FOLDER/user_data/reviews.csv \
--output=$EC2_LOGS --timedelta=10 --number=10000

# Move/copy LOGS to S3 BUCKET and KINESIS_LOGS
for i in $(find $EC2_LOGS -type f -iname "*.log")
do
  t1=$(basename -- $i)
#  Parse filename => year/month/day/hhmmss.log
  t0=${t1#*.}; y=${t0:4:4}; m=${t0:2:2}; d=${t0:0:2}; fname=${t0:8:10}
  folder=${t1%%.*}
#  target=${TARGET_FOLDER}"/"${folder}"/"${t1#*.}
  target=${TARGET_FOLDER}"/"${folder}"/year="${y}"/month="${m}"/day="${d}"/"${fname}
#  kinesis_log=${KINESIS_LOGS}"/"${t1#*.}
  if [ ${folder} == "views" ]
  then
#    cp $i ${kinesis_log}
    echo "Kinesis logs commented"
  fi
#  aws s3 mv $i s3://${BUCKET}${target}
  aws s3 cp $i s3://${BUCKET}${target}
#  echo s3://${BUCKET}${target}
done


