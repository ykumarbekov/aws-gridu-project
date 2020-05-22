#!/bin/bash

BUCKET="ykumarbekov-534348"
EC2_LOGS="/opt/logs"
TARGET_FOLDER="/logs"
PROJECT_FOLDER="/opt/aws-gridu-project"

python3 $PROJECT_FOLDER/code/runner.py \
--catalog=$PROJECT_FOLDER/catalog/books.csv \
--users_list=$PROJECT_FOLDER/user_data/users.csv \
--reviews=$PROJECT_FOLDER/user_data/reviews.csv \
--output=$EC2_LOGS --timedelta=10 --number=10000

for i in $(find $EC2_LOGS -type f -iname "*.log")
do
  t1=$(basename -- $i)
  folder=${t1%%.*}
  target=${TARGET_FOLDER}"/"${folder}"/"${t1#*.}
  aws s3 mv $i s3://${BUCKET}${target}
done


