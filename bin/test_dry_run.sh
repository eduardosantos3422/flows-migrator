#!/bin/bash
#test_dry_run.sh
#Stephen Mathis
#Wrapper shell to run modified version of github.com/aws-samples/amazon-connect-copy
#originally authored by kjacky Jacky Ko

function askProceed
{
    read -p "Enter Y or y if all of the above is correct, else enter anything else to abort and correct: " proceed
}

counter=0
while read line; do
    ((counter++))
    if [ $counter -eq 1 ]; then
        source_profile=$line
    elif [ $counter -eq 2 ]; then
        target_profile=$line
    elif [ $counter -eq 3 ]; then
        source_instance=$line
    elif [ $counter -eq 4 ]; then
        target_instance=$line
    elif [ $counter -eq 5 ]; then
        source_alias_name=$line
    elif [ $counter -eq 6 ]; then
        target_alias_name=$line
    elif [ $counter -eq 7 ]; then
        flow_prefix=$line
    else
        :
    fi
done

if [ $counter -gt 7 ]; then
    echo "Greater than 7 lines found in input file -- may be superfluous blank lines -- please correct and try again"
    exit 1
elif [ $counter -lt 7 ]; then 
    echo "Less than 7 lines found in input file -- input file must contain the following items and IN THIS ORDER:" 
    echo "Each data item must be on its own line with no leading or trailing spaces and must have no extra blank lines"
    echo ""
    echo "Source profile name (used by AWS CLI)"
    echo "Target profile name (used by AWS CLI)"
    echo "Source connect instance ID"
    echo "Target connect instance ID"
    echo "Source connect Alias Name"
    echo "Target connect Alias Name"
    echo "Prefix for contact flow and module names to be migrated -- ex. IVR for flow names beginning with IVR"
    exit 1
else
    :
fi

source_profile=`echo ${source_profile//[$'\t\r\n ']}`
target_profile=`echo ${target_profile//[$'\t\r\n ']}`
source_instance=`echo ${source_instance//[$'\t\r\n ']}`
target_instance=`echo ${target_instance//[$'\t\r\n ']}`
source_alias_name=`echo ${source_alias_name//[$'\t\r\n ']}`
target_alias_name=`echo ${target_alias_name//[$'\t\r\n ']}`
flow_prefix=`echo ${flow_prefix//[$'\t\r\n ']}`

echo "Please verify that the following is correct from the input file and answer the question at the end:"
echo "Source profile is $source_profile"
echo "Target profile is $target_profile"
echo "Source connect instance ID is $source_instance"
echo "Target connect instance ID is $target_instance"
echo "Source connect alias name is $source_alias_name"
echo "Target connect alias name is $target_alias_name"
echo "Contact flow and module name prefix value is $flow_prefix"
echo ""

askProceed </dev/tty

if [[ "$proceed" != [Yy] ]]; then
    echo "Aborting..."
    exit 1
fi

rm -rf $source_alias_name
rm -rf $target_alias_name
rm -rf helper

build_lex_json.sh $source_profile $target_profile $source_instance $target_instance 
return_code=$?
if [ $return_code -ne 0 ]; then
    echo "The build_lex_json.sh shell returned an error -- aborting"
    exit 1
fi
sleep 3

connect_save -p $source_profile -c $flow_prefix $source_alias_name
connect_save -p $target_profile -c $flow_prefix $target_alias_name
connect_diff $source_alias_name $target_alias_name helper
connect_copy -d helper
exit 0
