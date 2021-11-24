set pages 25 lines 250
col HEURE_DEBUT for a20
col HEURE_FIN for a20
col LAST_BKP for a10
col status for a25
col IN_BYTES for a15
col OUT_BYTES for a15
set head off
select '----------------------------------  ' 
|| 'Database name : ' || name || ', Instance name = ' || instance_name 
|| '   ----------------------------------'
from v$database, v$instance;
set head on
select
        d.NAME || '_' || i.instance_name "DBNAME_INSTANCE"
        ,SESSION_KEY "KEY"
        ,INPUT_TYPE "BKP_TYPE"
        ,to_char(START_TIME,'DD-MM-YYYY HH24:MI:SS') "HEURE_DEBUT"
        ,to_char(END_TIME,'DD-MM-YYYY HH24:MI:SS') "HEURE_FIN"
	,to_char(trunc(sysdate) + numtodsinterval(ELAPSED_SECONDS, 'second'),'hh24:mi:ss') "DUREE"
    	,cast((floor(sysdate-start_time)) as int) || 'd ' || round((round(sysdate-start_time, 2) - cast(floor(sysdate-start_time) as int))*24,0) || 'h' as "LAST_BKP"
        ,INPUT_BYTES_DISPLAY "IN_BYTES"
        ,OUTPUT_BYTES_DISPLAY "OUT_BYTES"
        ,r.STATUS
from V$RMAN_BACKUP_JOB_DETAILS r, v$database d, v$instance i
where start_time > (SYSDATE - 7) 
order by SESSION_KEY 
;

exit

