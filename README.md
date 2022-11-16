Amazon-Connect-Copy User Guide
Variant of The Amazon-Connect-Copy script (v1.2) copies components from the source Amazon Connect instance to the target instance safely, fixing all internal references.

You may use Amazon-Connect-Copy to deploy an Amazon Connect instance across environments (AWS accounts or regions), or to save a backup copy of the instance for restoration when required, reducing an hours-long error-prone manual job to a few minutes of automated and reliable processing.

Ids and Arns of components copied from the source instance will be re-mapped to their corresponding components in the new instance, including:

Instance (pre-existing)
Lambda functions (pre-deployed)
Lex bots (Version 2 only) (pre-deployed)
Prompts (pre-uploaded)
Hours of operations
Queues
#Routing profiles -- Note:  routing profiles migration does not currently work and is disabled
Contact flow modules
Contact flows
The following components are not copied by Amazon-Connect-Copy (to avoid any impact on other contact centres that may happen to be using the same target instance):

Users (agents) related settings, statuses and the hierarchy
Security profiles
Phone numbers
Inbound Contact flow/IVR mappings
Outbound caller ID number for queues
Quick connects
Settings for existing queues
Note: Settings for new queues will still be copied
Historical metrics and reports
Contact Trace Records (CTRs)
Custom vocabularies
Rules for Contact lens and Third-party integration
Amazon-Connect-Copy was designed for deployment across environments (e.g., from non-prod to prod). Considering the target instance may accommodate multiple contact centres, Amazon-Connect-Copy does not remove any target instance components which are not found in the source instance. If there are multiple contact centres sharing the same Amazon Connect instance, it is a good practice to prefix contact centre specific components with their individual Contact Centre Codes (CCCs).

Installation
Install AWS CLI.
Recommend installing the latest version of AWS CLI.
Install jq (if not already installed on your platform).
For the next line you need to copy bin/* /usr/local/bin.  However, you must NOT copy /usr/bin/sudo to /usr/local/bin
That will break your ability to sudo su.  So do not do a cp bin/* /usr/local/bin.  Instead copy everything except
/usr/bin/sudo.  Work this out however you wish.  But when done you must not end up with a /usr/bin/sudo and a 
/usr/local/bin/sudo.  If you inadvertantly do this, then you will need to check out the following link to correct 
it: https://unix.stackexchange.com/questions/419122/sudo-must-be-owned-by-uid-0-and-have-the-setuid-bit-set?newreg=b2490740fb214ce79c316ad76f859e0a
Copy bin/* to your Shell search path (e.g., cp bin/* /usr/local/bin/).

Create an input file with the following 7 data items in the following order on separate lines each:
You may name your input file whatever you like but for the example below it will be named aws_input.txt.
Also create this file in your amazon-connect-copy/bin directory and then cd to that directory.

The seven data items will be as follows and in this order (no blank lines between these lines):

source AWS CLI profile name -- if default then you must explicitly enter default as the value

target AWS CLI profile name

source AWS Connect instance ID -- the 36 character string at the end of your instance's ARN

target AWS Connect instance ID -- the 36 character string at the end of your instance's ARN

source AWS Connect instance alias name -- must be spelled EXACTLY the same as is in the console UI

target AWS Connect instance alias name -- must be spelled EXACTLY the same as is in the console UI

Flows prefix name -- example if migrating all flow names starting with IVR, then this value would be IVR

In the above you must have EXACTLY 7 lines. No preceeding/trailing headers or preceeding/trailing blank lines
Also, it may be possible that the first two lines of your source and target profile names may be the same.  
This could be a case where your source and target connect instances are in the same AWS account.  This is 
a normal use case and you must still enter both the source and target profile names even if the same.  The 
migrator will know the difference based on the source and target instance ID's and source and target alias names.
Also, on the above lines in your file make sure that each data item has no preceding or trailing spaces.

Example usage:
As noted previously, you must first cd to your amazon-connect-copy/bin directory. Additionally, as noted before
we will use aws_input.txt as the name of the input file, but your input file can be named whatever you want.
Type the following:
./test_dry_run.sh < ./aws_input.txt

Once you hit enter and depending on the sheer number of flows being migrated, the terminal may not return 
anything to stdout for several minutes potentially.  But once it does you will see the progress where 
it creates json contact flow/module exports in both the source and target instances from which it 
uses these as a comparison basis to determine if anything is different/missing in the target and from that
determine what needs to be migrated/changed.  The migrator will also auto associate the lambda's and lex bots
for the target connect instance as well if these are not already associated.

One VERY important note:  the test_dry_run.sh gets everything set for the actual copy/migrate short of actually
executing it.  Assuming we get no errors in the stdout, then after it finishes you need to execute the following
command which will do that actual migration.  While still in the amazon-connect-copy/bin directory type 
the following:
./connect_copy helper

After this finishes and returns be sure to observe the messages for any errors.  Assuming there are none,
then go to your target connect instance and your flows should be there and your Lambda's and Lex bots 
should also be associated.  

Please note that after the initial migration, the same process above can be reran to push changes that you 
may make to the source back to the target post initial migration.  It knows which flows have changes and 
will only push the newest changes on subsequent runs.  

Also, if you have a use case where there are several different flow prefix names to be pushed, then you
will need to do separate migration runs for each different flow prefix name.  

Note: The following notes give more information regarding core components such as connect_save and connect_diff.
However, due to modifications specific to this installation, the connect_copy script CANNOT be ran directly
in dry run mode.  It can ONLY be ran initially from the test_dry_run.sh shell as that incorporates and calls
other pre-processing shells and python scripts necessary for handling the migration of Lex bot (version 2).
Then as noted above when the test_dry_run.sh has bee executed, then you only run it for the live run as noted 
above.

In this example:

We copy from instance source-connect-alias to instance target-connect-alias.
Credentials for the source and target instances are in AWS profiles source-profile and target-profile respectively.
You may use the same profile for source-profile and target-profile, as long as that profile allows access to both the source and the target instances (typically when they are in the same AWS account).
Only contact flows and modules with names prefixed by the CCC Contact Centre Code will be copied to the target instance.
Differences of the two instances (including profile specifications) will be saved in directory helper.
Copying process
Note: All names in Amazon Connect are case sensitive.

Pre-steps
Make sure no one else is making changes to either the source or the target instances, or any Lambda functions or Lex bots (Version 2) they integrate with.
Deploy all Lambda functions required by the target instance.
Build all Lex bots (Version 2) required by the target instance.
Upload all required prompts to the target instance.
The prompt names need to be exactly the same as their counterparts in the source instance.
For an incremental instance update with contact flow or module name changes, before the copying please manually change the corresponding flow or module names in the target instance. Otherwise, contact flows and modules with new names will be created in the target instance, and those with old names will be left untouched.
Copying
Set up named profiles for AWS CLI access to Amazon Connect.
<source_profile> for the source instance
<target_profile> for the target instance
This step is optional if your default profile already has access to both the source and the target instances. If not sure, skip this step for now. You only need to set up the profiles if connect_save fail due to a permission error.
cd to an empty working directory (e.g., md <dir>; cd <dir>).
Optionally, run connect_save with no arguments to show the help message:
Usage: connect_save [-?fsev] [-p aws_profile] [-c contact_flow_prefix] [-G ignore_prefix] instance_alias
    Retrieve components from an Amazon Connect instance into plain files

    instance_alias          Alias of the Connect instance (or path to the directory to save, with the alias being the basename)
    -f                      Force removal of existing instance_alias directory
    -s                      Skip unpublished contact flow modules and contact flows with an error (instead of failing)
    -e                      Proceed even when the system may not encode Extended ASCII characters properly
    -v                      Show version of this script
    -p profile              AWS Profile to use
    -c contact_flow_prefix  Prefix of Contact Flows and Modules to be copied (all others will be ignored) - Default is to copy all
    -G ignore_prefix        Ignore hours, queues, routing profiles, flows or modules with names prefixed with ignore_prefix
    -C codepage             Override the auto-detected codepage (e.g., use '-C CP1252' for Gitbash ANSI if experiencing encoding issues)
    -?                      Help
<instance_alias> can be a directory path.
<instance_alias>.log will be produced by connect_save.
Run connect_save -p <source_profile> -c <contact_flow_prefix> <source_instance_alias> .
Run connect_save -p <target_profile> -c <contact_flow_prefix> <target_instance_alias> .
Optionally, run connect_diff with no arguments to show the help message:
Usage: connect_diff [-?fev] [-l lambda_prefix_a=lambda_prefix_b] [-b lex_bot_prefix_a=lex_bot_prefix_b] instance_alias_a instance_alias_b helper
    Based on connect_save result on Amazon Connect instance A and B,
    find the differences and produce helper files to safely copy components from A to B.

    instance_alias_a    Alias of the Connect instance A
    instance_alias_b    Alias of the Connect instance B
                        (Aliases can be a path to the directory where the instance was saved using connect_save.)
    helper              Name of the helper directory
    -f                  Force removal of existing helper directory
    -e                  Proceed even when the system may not encode Extended ASCII characters properly
    -v                  Show version of this script
    -l lambda_prefix_a=lambda_prefix_b
                        Lambda function name prefixes for instances A and B (if different) to be replaced during copying
    -b lex_bot_prefix_a=lex_bot_prefix_b
                        Lex bot (Version 2) name prefixes for instances A and B (if different) to be replaced during copying
    -?                  Help

    Note: This script create files in the helper directory without changing any instance component files.
Run connect_diff -l <source_lambda_prefix>=<target_lambda_prefix> -b <source_lex_bot_prefix>=<target_lex_bot_prefix> <source_instance_alias> <target_instance_alias> <helper> .
Optionally, check under the helper directory <helper> to find the four helper files:
helper.new - components to create (those found in the source but not in the target); You may remove components that you do not want to be created from helper.new.
helper.old - components to update (those found in the source and also in the target); You may remove components that you do not want to be updated from helper.old.
helper.sed - SED script to fix references (so target components will not refer to any components in the source)
helper.var - variables of the two instances (instance A is the source, and instance B is the target)
Optionally, run connect_copy with no arguments to show the help message:
Usage: connect_copy [-?dev] helper
    Copy Amazon Connect instance A to instance B safely, based on the
    connect_save and connect_diff results, under the helper directory
    creating new components in helper.new, updating old components in helper.old,
    and updating references defined in helper.sed.

    helper  Name of the helper directory
    -d      Dry run - Run through the script but not updating the target instance
    -e      Proceed even when the system may not encode Extended ASCII characters properly
    -v      Show version of this script
    -?      Help
Optionally, verify the helper by dry-running connect_copy -d <helper> .
Check if the proposed changes are as what you would expect from the output.
AWS CLI commands to execute can be found in <helper>.log for your reference.
Please do not run the log file as an executable. Run connect_copy without -d (dry-run) to perform the actual copying.
Run connect_copy <helper> .
Verify if the target instance contains all source instance components of the latest version, with all internal references, Lambda invocations and Lex bot (Classic) input properly adjusted.
Post-steps
Login to Amazon Connect target instance.
Open Phone numbers.
Check Contact flow/IVR of all phone numbers.
If required, re-map phone numbers to the new Inbound Contact flows/IVR.
Open Queues.
For new outbound queues created, set these if required:
Outbound caller ID name
Outbound caller ID number
Outbound whisper flow
Backup an Amazon Connect instance using Amazon-Connect-Copy
You may restore an Amazon Connect instance from a previous backup copy saved by connect_save.

Example:

Save a backup copy of the Amazon Connect instance.
connect_save -p <profile> <backup_dir>/<connect_instance_alias>
Restore the same instance from the backup copy.
Save the current copy (the one to be restored).
connect_save -p <profile> <working_dir>/<connect_instance_alias>
Diff the current copy with the backup copy.
connect_diff <backup_dir>/<connect_instance_alias> <working_dir>/<connect_instance_alias> <helper_dir>
Optionally, dry run to verify restoration changes.
connect_copy -d <helper_dir>
Restore the instance.
connect_copy <helper_dir>
Useful Tips
This script has been tested with AWS CLI 2.4.1, which supports the latest Amazon Connect features, including Contact Flow Modules. (Even your instances may not be using all latest Amazon Connect features, the script will check them and therefore require the latest AWS CLI.)
Make sure both the source instance and the target instance remain unaltered by anyone during the entire copying process (save, diff and copy).
connect_diff only creates the helper directory and will not change anything in the source and the target instance directories.
connect_copy will change files in the helper directory, and when in non-dry-run mode, will change the target instance directory as well. i.e., connect_copy is not idempotent to the target and helper directory.
DO NOT reuse the target instance directory and the helper directory. Remove these two directories after copying.
If you want to keep a backup of the target instance after copying, run connect_save again on the target instance.
connect_diff and connect_copy do not change the source instance directory, so the source can serve as a backup or be used to copy to multiple target instances.
If relative paths are specified in instance aliases, make sure you are running connect_diff and connect_copy from the same directory, so that connect_copy will resolve the relative paths correctly.
The Amazon-Connect-Copy script does not affect any instance-specific settings outside of the Amazon Connect console, such as Amazon Connect service quotas.
