#!/usr/local/bin/python3
#build_lex_json.py
#Stephen Mathis
#Helper python script to run modified version of github.com/aws-samples/amazon-connect-copy
#originally authored by kjacky Jacky Ko

import json
import boto3
import sys

# Retrieve command line arguments
source = target = source_instance = target_instance = None

for i, arg in enumerate(sys.argv):
    if i == 0:
        continue
    elif i == 1:
        source = arg.strip()
    elif i == 2:
        target = arg.strip()
    elif i == 3:
        source_instance = arg.strip()
    elif i == 4:
        target_instance = arg.strip()
    else:
        break

for item in [source, target, source_instance, target_instance]:
    if item == None:
        print("Invalid or null input arguments sent to build_lex_json.py script -- aborting")
        sys.exit(1)

migration_lst = [{'profile':source, 'instance':source_instance}, {'profile':target, 'instance':target_instance}]

with open("source_connect_listbots.json") as file:
    source_connect_listbots = json.load(file)

with open("source_lexv2_listbots.json") as file:
    source_lexv2_listbots = json.load(file)

with open("target_connect_listbots.json") as file:
    target_connect_listbots = json.load(file)

with open("target_lexv2_listbots.json") as file:
    target_lexv2_listbots = json.load(file)

with open("target_connect_instance.json") as file:
    target_connect_instance = json.load(file)

with open("target_botid_alias.json") as file:
    target_botid_alias = json.load(file)

source_botnames_list = []
source_botnames_dict ={}
target_botnames_list = []
target_botnames_dict = {}
aliasarn_cross_reference = {}

for item in source_lexv2_listbots['botSummaries']:
    if item['botName'] not in source_botnames_list:
        for item2 in source_connect_listbots['LexBots']:
            if item2['LexV2Bot']['AliasArn'].split('bot-alias/')[1].split('/')[0] == item['botId']:
                source_botnames_dict[item['botName']] = item2['LexV2Bot']['AliasArn']
                source_botnames_list.append(item['botName'])

target_arn_prefix = target_connect_instance['Instance']['Arn'].split('instance')[0].replace('connect', 'lex') + 'bot-alias/'

for item in target_lexv2_listbots['botSummaries']:
    if item['botName'] not in target_botnames_list:
        if item['botId'] in target_botid_alias:
            target_botnames_dict[item['botName']] = str(target_arn_prefix) + str(target_botid_alias[item['botId']])
            target_botnames_list.append(item['botName'])

for source_name in source_botnames_list:
    if source_name in target_botnames_list:
        aliasarn_cross_reference[source_botnames_dict[source_name]] = target_botnames_dict[source_name]

with open('aliasarn_cross_reference.json', 'w') as file:
    json.dump(aliasarn_cross_reference, file, default=str)

sys.exit(0)
