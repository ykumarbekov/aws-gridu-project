import argparse as arg
import random as rnd
from datetime import datetime
from util.tools import *


def cmd_parser():
    '''
    runner.py --catalog=./catalog/books.csv --ip_list=./user_data/ip.csv --users_list=./user_data/users.csv --number=10
    runner.py --catalog=./catalog/books.csv --users_list=./user_data/users.csv --number=10
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
        # p.add_argument(
        #    "--ip_list",
        #    help="User ip addresses list file. Must be provided",
        #    required=True,
        #    dest="ip_list"
        # )
        p.add_argument(
            "--users_list",
            help="User devices list file. Must be provided",
            required=True,
            dest="users_list"
        )
        a = p.parse_args()
        result["nm"] = a.nm
        result["catalog"] = a.catalog
        # result["ip_list"] = a.ip_list
        result["users_list"] = a.users_list

    except Exception as ex:
        print(ex)
        return {}

    return result


def get_viewer(u_info, item, b):
    result = {item: b[item], 'timestamp': datetime.now().strftime("%d.%m.%Y %H:%M:%S")}
    result.update(u_info)
    return result


if __name__ == "__main__":
    data = cmd_parser()
    if data \
        and int_validator(data['nm']) \
            and file_validator(data['catalog']) \
            and file_validator(data['users_list']):
        nm = int(data['nm'])
        # ip_list = get_data_list(data['ip_list'])
        users_list = get_data_list(data['users_list'])
        catalog_list = get_data_list(data['catalog'])
        # *******
        while nm > 0:
            user_info = dict(rnd.choice(users_list))
            # user_info.update(dict(rnd.choice(ip_list)))
            book = dict(rnd.choice(catalog_list))
            viewer = get_viewer(user_info, 'ISBN', book)
            print(viewer)
            nm = nm - 1
        # *******
    print(f'Review title: {gen_text_row(3)}')
    print(f'Review Text: {gen_text_row(5, False)}')
    print(f'Review Stars: {rnd.randint(1, 5)}')
    # print(gen_text_block(3))




