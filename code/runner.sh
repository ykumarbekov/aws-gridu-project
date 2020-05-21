#!/bin/bash

BUCKET="ykumarbekov-534348"
EC2_LOGS="/opt/logs"
TARGET_FOLDER="/logs"

python3 /opt/aws-gridu-project/code/runner.py \
--catalog=/opt/aws-gridu-project/catalog/books.csv \
--users_list=/opt/aws-gridu-project/user_data/users.csv \
--reviews=/opt/aws-gridu-project/user_data/reviews.csv \
--output=$EC2_LOGS --timedelta=10 --number=10000

for i in $(find $EC2_LOGS -type f -iname "*.log")
do
  t1=$(basename -- $i)
  folder=${t1%%.*}
  target=${TARGET_FOLDER}"/"${folder}"/"${t1#*.}
  aws s3 mv $i s3://${BUCKET}${target}
done


