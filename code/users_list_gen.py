#!/usr/bin/env python
import argparse as arg
import uuid
from util.tools import *
import random as rnd


def cmd_parser():
    result = {}
    try:
        p = arg.ArgumentParser(prog="user generator", usage="%(prog)s parameters", description="")
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


def ip_generator():
    '''
    IP Generator: xxx.xxx.xxx.xxx
    Excluded: 1st octet: 10,192,172,127,224,255,0 / 2nd, 3rd: 255 / 4th: 0,1,255
    :return: example: 56.10.18.25
    '''
    ip_1, ip_2, ip_3, ip_4 = 0, 0, 0, 0
    while ip_1 in (10, 192, 172, 127, 224, 255, 0) or ip_2 == 255 or ip_3 == 255 or ip_4 in (0, 1, 255):
        ip_1 = rnd.randint(0, 255)
        ip_2 = rnd.randint(0, 255)
        ip_3 = rnd.randint(0, 255)
        ip_4 = rnd.randint(0, 255)
    return '.'.join([str(ip_1), str(ip_2), str(ip_3), str(ip_4)])


if __name__ == "__main__":
    data = cmd_parser()
    if data and int_validator(data['nm']):
        nm = int(data['nm'])
        device_type = ['ANDROID', 'IOS', 'MacOS', 'LINUX', 'WINDOWS']
        print('device_type,device_id,ip')
        while nm > 0:
            print(','.join((rnd.choice(device_type), str(uuid.uuid4()), ip_generator())))
            nm = nm - 1
