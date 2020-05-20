import os
import csv
import string
import random as rnd


def int_validator(s):
    result = None
    try:
        result = int(s)
    except:
        print(f"Can't validate input string: {s}")
        return result
    return result


def file_validator(s):
    return os.path.exists(s) and os.path.isfile(s)


def folder_validator(s):
    return os.path.exists(s) and os.path.isdir(s)


def get_data_list(s, delimiter):
    out_list = []
    with open(s, newline='') as out_csv:
        reader = csv.DictReader(out_csv, delimiter=delimiter)
        for r in reader:
            out_list.append(r)
    return out_list


def gen_text(n):
    letters = string.ascii_lowercase
    return ''.join(rnd.choice(letters) for i in range(n))


def gen_random_review(title=True):
    row = []
    k = rnd.randint(1, 5)
    i = k
    while i > 0:
        if title and i == k:
            row.append(gen_text(rnd.randint(3, 10)).capitalize())
        else:
            row.append(gen_text(rnd.randint(3, 10)))
        i = i - 1
    return ' '.join(row)

