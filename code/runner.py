import argparse as arg
import random as rnd
import json
from datetime import datetime, timedelta
from util.tools import *


def cmd_parser():
    '''
    Example:
    runner.py
    --catalog=./catalog/books.csv
    --users_list=./user_data/users.csv
    --reviews=./user_data/reviews.csv
    --output=./logs
    --timedelta=30
    --number=10
    where timedelta - randomly chosen time between current_time-30 and current_time
    :return:
    '''
    result = {}
    try:
        p = arg.ArgumentParser(prog="runner", usage="%(prog)s parameters", description="")
        p.add_argument(
            "--number",
            help="Output number. Must be provided",
            required=True,
            dest="nm"
        )
        p.add_argument(
            "--catalog",
            help="Path to catalog file. Must be provided",
            required=True,
            dest="catalog"
        )
        p.add_argument(
           "--reviews",
           help="Reviews list file. Must be provided",
           required=True,
           dest="reviews_list"
        )
        p.add_argument(
            "--output",
            help="Output folder. Must be provided",
            required=True,
            dest="output_folder"
        )
        p.add_argument(
            "--timedelta",
            help="Timedelta. Default = 60",
            required=False,
            default=60,
            dest="timedelta"
        )
        p.add_argument(
            "--users_list",
            help="User devices list file. Must be provided",
            required=True,
            dest="users_list"
        )
        a = p.parse_args()
        result["nm"] = a.nm
        result["catalog"] = a.catalog
        result["reviews_list"] = a.reviews_list
        result["users_list"] = a.users_list
        result["timedelta"] = a.timedelta
        result["output_folder"] = a.output_folder

    except Exception as ex:
        print(ex)
        return {}

    return result


def get_viewer(u_info, item, td, b):
    if td < 0 or td > 60:
        td = 60
    # result = {item: b[item], 'timestamp': datetime.now().strftime("%d.%m.%Y %H:%M:%S")}
    result = {item: b[item],
              'timestamp': (datetime.now()-timedelta(
                  minutes=rnd.randint(0, td),
                  seconds=rnd.randint(0, 5))).strftime("%d.%m.%Y %H:%M:%S")}
    result.update(u_info)
    return result


if __name__ == "__main__":
    data = cmd_parser()
    if data \
        and int_validator(data['nm']) \
            and int_validator(data['timedelta']) \
            and file_validator(data['catalog']) \
            and file_validator(data['reviews_list']) \
            and folder_validator(data['output_folder']) \
            and file_validator(data['users_list']):
        nm = int(data['nm'])
        # number of created reviews, as 20% from total number of views
        rp = round(nm * 10/100)
        tm = int(data['timedelta'])
        users_list = get_data_list(data['users_list'], delimiter='|')
        catalog_list = get_data_list(data['catalog'], delimiter='|')
        reviews_list = get_data_list(data['reviews_list'], delimiter='|')
        v_list = []
        # Convert to JSON and save
        view_log_fn_name = 'views.' + datetime.now().strftime("%d%m%Y%H%M%S") + '.logs'
        review_log_fn_name = 'reviews.' + datetime.now().strftime("%d%m%Y%H%M%S") + '.logs'
        # *******
        with open(os.path.join(data['output_folder'], view_log_fn_name), 'w+') as view_log:
            while nm > 0:
                user_info = dict(rnd.choice(users_list))
                book = dict(rnd.choice(catalog_list))
                viewer = get_viewer(user_info, 'ISBN', tm, book)
                v_list.append(viewer)
                json.dump(viewer, view_log)
                view_log.write("\n")
                nm = nm - 1
        # *******
        with open(os.path.join(data['output_folder'], review_log_fn_name), 'w') as review_log:
            while rp > 0:
                v = dict(rnd.choice(v_list))
                v.update(dict(rnd.choice(reviews_list)))
                json.dump(v, review_log)
                review_log.write("\n")
                rp = rp - 1
        # *******
        # print(f"View: {os.path.join(data['output_folder'], view_log_fn_name)}")
        # print(f"Review: {os.path.join(data['output_folder'], review_log_fn_name)}")








