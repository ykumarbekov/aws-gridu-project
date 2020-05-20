#!/bin/bash

PROJECT=/opt/aws-gridu-project

python3 $PROJECT/code/runner.py \
--catalog=$PROJECT/catalog/books.csv \
 --users_list=$PROJECT/user_data/users.csv \
 --reviews=$PROJECT/user_data/reviews.csv \
 --output=/opt/logs --timedelta=10 --number=10000