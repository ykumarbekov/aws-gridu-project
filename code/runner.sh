#!/bin/bash

BUCKET="ykumarbekov-534348"
EC2_LOGS="/opt/logs"
TARGET_FOLDER="/logs"
PROJECT_FOLDER="/opt/aws-gridu-project"

# ##### LOGS GENERATING #####
# Step 1. USERS
python3 $PROJECT_FOLDER/code/users_list_gen.py --number 100 > $PROJECT_FOLDER/user_data/users.csv
# Step 2. LOGS
python3 $PROJECT_FOLDER/code/runner.py \
--catalog=$PROJECT_FOLDER/catalog/books.csv \
--users_list=$PROJECT_FOLDER/user_data/users.csv \
--reviews=$PROJECT_FOLDER/user_data/reviews.csv \
--output=$EC2_LOGS --timedelta=10 --number=10000

# Move LOGS to S3 BUCKET
for i in $(find $EC2_LOGS -type f -iname "*.log")
do
  t1=$(basename -- $i)
  folder=${t1%%.*}
  target=${TARGET_FOLDER}"/"${folder}"/"${t1#*.}
  aws s3 mv $i s3://${BUCKET}${target}
done


