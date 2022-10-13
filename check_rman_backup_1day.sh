export SCRIPTS_DIR=/home/oracle/exploit
/home/oracle/scripts/running_instances.sh | while read d
do 
	export ORAENV_ASK=NO
	export ORACLE_SID=$d
    . oraenv > /dev/null
	sqlplus -S / as sysdba @${SCRIPTS_DIR}/check_rman_backup_1day.sql
done
