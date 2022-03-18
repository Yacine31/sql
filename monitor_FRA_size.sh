#Set Variables
LOGDIR=/home/oracle/scripts/logs
TMPDIR=/home/oracle/scripts/logs
HOST=$(hostname | awk -F "." '{print $1}')
DT=$(date)
export LOGDIR TMPDIR

declare -i FRA_USED_PERC=0
# seuil de 80% d'occupation, on déclenche une action
declare -i THRESHOLD=80

#Set Environment for database
export ORACLE_HOME=/u01/app/oracle/product/11.2.0/dbhome_1
export ORACLE_SID=DBSE
export PATH=${ORACLE_HOME}/bin:${PATH}

sqlplus -s / as sysdba <<!  > /dev/null
col name for a40
set pages 0 lines 150
set heading off echo off feedback off termout off
spool ${TMPDIR}/chk_${ORACLE_SID}_fra.log
select name, space_limit/1024/1024 "Limit(MB)", trunc(SPACE_USED/1024/1024,0) "Used(MB)", SPACE_RECLAIMABLE/1024/1024 "Reclaimable(MB)" from v\$recovery_file_dest;
spool off
exit
!

FRA_SIZE=$(tail -1 ${TMPDIR}/chk_${ORACLE_SID}_fra.log | awk '{print $2}')
FRA_USED=$(tail -1 ${TMPDIR}/chk_${ORACLE_SID}_fra.log | awk '{print $3}')
FRA_USED_PERC=$(echo $( echo "scale=2; ${FRA_USED}/${FRA_SIZE} * 100" |bc | awk -F "." '{print $1}'))

if [ ${FRA_USED_PERC} -lt ${THRESHOLD} ]
then
	echo $(date +%Y.%m.%d-%H:%M:%S) " == On ne fait rien : FRA_SIZE=${FRA_SIZE}, FRA_USED=${FRA_USED}, FRA_USED_PERC=${FRA_USED_PERC}, THRESHOLD=${THRESHOLD}"
else
	echo $(date +%Y.%m.%d-%H:%M:%S) " == SAUVEGARDE RMAN : FRA_SIZE=${FRA_SIZE}, FRA_USED=${FRA_USED}, FRA_USED_PERC=${FRA_USED_PERC}, THRESHOLD=${THRESHOLD}"
fi 
