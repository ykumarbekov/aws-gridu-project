#!/usr/bin/env python
import argparse as arg
import uuid
from util.tools import *
import random as rnd


def cmd_parser():
    result = {}
    try:
        p = arg.ArgumentParser(prog="spam_review_gen", usage="%(prog)s parameters", description="")
        p.add_argument(
            "--number",
            help="Output number. Must be provided",
            required=True,
            dest="nm"
        )
        a = p.parse_args()
        result["nm"] = a.nm
    except Exception as ex:
        print(ex)
        return {}

    return result


if __name__ == "__main__":
    data = cmd_parser()
    if data and int_validator(data['nm']):
        nm = int(data['nm'])
        print('review|stars')
        while nm > 0:
            print('|'.join((gen_random_review(), rnd.choice(('1', '2', '3', '4', '5')))))
            nm = nm - 1
