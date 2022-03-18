#Set Variables
LOGDIR=/home/oracle/scripts/logs
TMPDIR=/home/oracle/scripts/logs
HOST=$(hostname | awk -F "." '{print $1}')
DT=$(date)
export LOGDIR TMPDIR

#Set Environment for database
ORACLE_HOME=/u01/app/oracle/product/11.2.0/dbhome_1
ORACLE_SID=DBSE
PATH=${ORACLE_HOME}/bin:${PATH}
export ORACLE_HOME ORACLE_SID PATH

sqlplus -s / as sysdba <<!
col name for a40
set pages 100 lines 150
set echo off feedback off
spool ${TMPDIR}/chk_${ORACLE_SID}_fra.log
select name, space_limit/1024/1024 "Limit(MB)", trunc(SPACE_USED/1024/1024,0) "Used(MB)", SPACE_RECLAIMABLE/1024/1024 "Reclaimable(MB)" from v\$recovery_file_dest;
spool off
exit
!

FRA_SIZE=$(tail -1 ${TMPDIR}/${HOST}/chk_${ORACLE_SID}_fra.log | awk "{print $2}")
FRA_USED=$(tail -1 ${TMPDIR}/${HOST}/chk_${ORACLE_SID}_fra.log | awk "{print $3}")
THRESHOLD=$(echo ${FRA_SIZE} \* 0.1 | bc | awk -F “.” "{print $1}")
FRA_USED_PERC=$(echo $( echo "scale=2; ${FRA_USED}/${FRA_SIZE} * 100" |bc | awk -F "." "{print $1}"))

if [ ${FRA_USED} -ge ${THRESHOLD} ]
then
	# 
	echo nail -s "Subject: DBPRODNODE: PROD: CLIENT FRA has reached" -S smtp=mail.smtp dbamustak@gmail.com < ${TMPDIR}/${HOST}/chk_${ORACLE_SID}_fra.log
fi 
