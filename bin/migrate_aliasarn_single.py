#!/usr/local/bin/python3
#migrate_aliasarn_single.py
#Stephen Mathis
#Helper python script to run modified version of github.com/aws-samples/amazon-connect-copy
#originally authored by kjacky Jacky Ko

import json
import sys

with open("aliasarn_cross_reference.json") as file:
    aliasarn_cross_reference = json.load(file)

fname = sys.argv[1]
fname = str(fname).strip()

lnes =[]
with open(fname) as infile:
    for lne in infile:
        for src, trget in aliasarn_cross_reference.items():
            lne = lne.replace(src, trget)
        lnes.append(lne)

with open(fname, 'w') as outfile:
    for lne in lnes:
        outfile.write(lne)
