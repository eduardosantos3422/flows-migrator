#!/bin/bash
#build_lex_json.sh
#Stephen Mathis
#Helper shell to assit in running modified version of github.com/aws-samples/amazon-connect-copy
#originally authored by kjacky Jacky Ko

source_profile=$1
target_profile=$2
source_instance=$3
target_instance=$4

if [ -z "$source_profile" ] || [ -z "$target_profile" ] || [ -z "$source_instance" ] || [ -z "$target_instance" ]; then
    echo "The build_lex_json.sh shell was called with one or more null arguments that are required -- aborting"
    exit 1
fi

aws lexv2-models list-bots --profile $source_profile | jq > source_lexv2_listbots.json
aws lexv2-models list-bots --profile $target_profile | jq > target_lexv2_listbots.json

aws connect list-bots --profile $source_profile --instance-id $source_instance --lex-version V2 | jq > source_connect_listbots.json 

aws connect list-bots --profile $target_profile --instance-id $target_instance --lex-version V2 | jq > target_connect_listbots.json 

aws connect describe-instance --profile $target_profile --instance-id $target_instance | jq > target_connect_instance.json

cat target_lexv2_listbots.json | jq ".botSummaries[].botId" > target_lexv2_botnames_temp.txt
sleep 5
sed 's/\"//g' target_lexv2_botnames_temp.txt > target_lexv2_botnames.txt
sleep 1
rm -f target_lexv2_botnames_temp.txt
#wait long enough to ensure file is finished writing before reading it
targetba=target_botid_alias_temp.json
targetba_final=target_botid_alias.json
echo "{" > $targetba

while read botId; do
    aws lexv2-models list-bot-aliases \
	    --profile $target_profile \
	    --bot-id $botId | jq ".botAliasSummaries[] | select(.botAliasName == \"live\") | .botAliasId" > $botId.txt.temp
    sleep 5
    sed 's/\"//g' $botId.txt.temp > $botId.txt
    sleep 1
    rm -f $botId.txt.temp
    echo "\"$botId\":\"$botId/" >> $targetba
    cat $botId.txt >> $targetba
    echo "\"," >> $targetba
    rm -f $botId.txt
done < target_lexv2_botnames.txt

sed '$s/,/}/' $targetba > $targetba_final
rm -f $targetba
echo -n $(tr -d "\n" < $targetba_final) > $targetba_final
rm -f target_lexv2_botnames.txt
sleep 5
build_lex_json.py ${source_profile} ${target_profile} ${source_instance} ${target_instance}
return_status=$?
if [ $return_status -ne 0 ]; then
    echo "The build_lex_json.py python script returned an error -- aborting"
    exit 1
else
    exit 0
fi
