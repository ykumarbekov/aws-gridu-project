#!/bin/bash

python3 /opt/aws-gridu-project/code/runner.py \
--catalog=/opt/aws-gridu-project/catalog/books.csv \
--users_list=/opt/aws-gridu-project/user_data/users.csv \
--reviews=/opt/aws-gridu-project/user_data/reviews.csv \
--output=/opt/logs --timedelta=10 --number=10000