#!/bin/bash
#. /home/oracle/.bash_profile

MOI=`basename ${0}`
LANG=C
#############
test_instance()
{
        ps -ef | grep pmon_${ORACLE_SID}\$ | grep -v grep | grep -- ${ORACLE_SID} >/dev/null
        if [ $? -eq 1 ]; then
                return 1
        else
                return 0
        fi
}

usage()
{
cat << EOF
usage: ${MOI} options

This script show the Flash Recovery Area usage (if any)

OPTIONS:
   -h      Show this message
   -i      Instance name (default \$ORACLE_SID)
EOF
}

VERBOSE=0
while getopts "hi:" OPTION; do
	case ${OPTION} in
	  h)
	  	usage
		exit 0
		;;
	  i)
	  	ORACLE_SID=${OPTARG}
		;;
	  ?)
	  	usage
		exit 0
		;;
	esac
done


if [ -z "${ORACLE_SID}" ];
then
	echo "\$ORACLE_SID not set and no INSTANCE Supplied on the command line."
	exit 1
fi
# Set up the environment
export ORACLE_SID
export ORAENV_ASK=NO
. oraenv -s >/dev/null


test_instance || { echo "Instance ${ORACLE_SID} not started !!";  exit 1 ; }

SIZE=`${ORACLE_HOME}/bin/sqlplus -s / as sysdba <<EOF
set lines 150 feedback off pages 0
select value from v\\$parameter where name='db_recovery_file_dest_size';
EOF`

if [[ ${SIZE} -eq 0 ]];
then
	exit
fi


$ORACLE_HOME/bin/sqlplus -s / as sysdba <<EOF
set lines 150 feedback off pages 0
select
'Database: '||v\$database.name||'
Instance: '||instance_name||'
Role:     '||database_role from v\$database, v\$instance;
select 'FRA size: '||round(value/1024/1024/1024)||' GB' from v\$parameter where name='db_recovery_file_dest_size';
select 'Used:     '||sum(PERCENT_SPACE_USED)||'%  ('||sum(PERCENT_SPACE_RECLAIMABLE)||'% reclaimable)' from v\$flash_recovery_area_usage;
set pages 60
select * from v\$flash_recovery_area_usage;
exit
EOF
echo "-----------------------------------------------------------------------------------------------------"

