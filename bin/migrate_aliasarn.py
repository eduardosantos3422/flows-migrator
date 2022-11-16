#!/usr/local/bin/python3
#migrate_aliasarn.py
#Stephen Mathis
#Helper python script to run modified version of github.com/aws-samples/amazon-connect-copy
#originally authored by kjacky Jacky Ko

import json

with open("aliasarn_cross_reference.json") as file:
    aliasarn_cross_reference = json.load(file)

target_dir = None

with open('target_directory.txt', 'r') as fin:
    lines = fin.readlines()
for line in lines:
    target_dir = line
    target_dir = str(target_dir).strip() + str('/')
    break

with open('flows_list.txt', 'r') as fin:
    lines = fin.readlines()

for line in lines:
    fname = line
    fname = str(target_dir) + str(fname).strip()
    lnes =[]
    with open(fname) as infile:
        for lne in infile:
            for src, trget in aliasarn_cross_reference.items():
                lne = lne.replace(src, trget)
            lnes.append(lne)

    with open(fname, 'w') as outfile:
        for lne in lnes:
            outfile.write(lne)
