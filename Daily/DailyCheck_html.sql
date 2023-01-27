SET TERMOUT OFF
SET ECHO OFF
SET SERVEROUTPUT OFF
set feedback off
set echo off pagesize 1000 markup html on ENTMAP OFF spool on TABLE BORDER='1'
-- spool ./DailyCheck.html

-- ---------------------------------------------------
prompt 1 - Current DATE
-- ---------------------------------------------------
select to_char(sysdate,'DD/MM/YYYY HH24:MI:SS') "CURRENT DATE" from dual;

-- ---------------------------------------------------
prompt 2 - DB SIZE
-- ---------------------------------------------------
col TOTAL_SIZE_GB format 99,999.99
select sum(bytes)/1024/1024/1024 TOTAL_SIZE_GB from dba_data_files;

-- ---------------------------------------------------
prompt 3 - INSTANCE STATUS
-- ---------------------------------------------------
select inst_id,
 instance_name,
 status,
 VERSION_FULL,
 EDITION,
 ARCHIVER,
 INSTANCE_ROLE,
 database_status,
 active_state,
 to_char(startup_time,'DD/MM/YYYY HH24:MI:SS') startup_time 
FROM  gv$instance;

-- ---------------------------------------------------
prompt 4 - Database Status 
-- ---------------------------------------------------
SELECT inst_id, name, to_char(CREATED ,'DD/MM/YYYY') CREATED , open_mode, DATABASE_ROLE, log_mode, FORCE_LOGGING, CURRENT_SCN FROM gv$database;

-- ---------------------------------------------------
prompt 5 - Database non default parameters
-- ---------------------------------------------------
set pages 999 lines 150
col name for a50
col value for a90
col display_value for a90
select NAME, DISPLAY_VALUE from v$parameter where ISDEFAULT='FALSE' order by name;

-- ---------------------------------------------------
prompt 6 - Users
-- ---------------------------------------------------
set pages 999 lines 150
ALTER SESSION SET NLS_DATE_FORMAT ='YYYY/MM/DD HH24:MI';
col USERNAME for a25
col DEF_TBS for a15
col TMP_TBS for a10
col PROFILE for a10
col ACCOUNT_STATUS for a20
select USERNAME, ACCOUNT_STATUS, PROFILE, DEFAULT_TABLESPACE DEF_TBS, TEMPORARY_TABLESPACE TMP_TBS, CREATED, PASSWORD_VERSIONS from dba_users order by created;

-- ---------------------------------------------------
prompt 6 - NLS Database parameters
-- ---------------------------------------------------
col parameter for a30
col value for a30
select * from nls_database_parameters ;

-- ---------------------------------------------------
prompt 8 - FRA
-- ---------------------------------------------------
set lines 300
SELECT VALUE/1024/1024 TAILLE_FRA_MiB, ROUND((VALUE*TOT_PCT/100)/1024/1024,0) ESPACE_UTILISE_MiB, 
  TOT_PCT POURCENTAGE_UTILISE
FROM
  V$PARAMETER P,
  (SELECT SUM(PERCENT_SPACE_USED) TOT_PCT FROM V$FLASH_RECOVERY_AREA_USAGE) PCT_U
WHERE NAME='db_recovery_file_dest_size';

SELECT * FROM V$FLASH_RECOVERY_AREA_USAGE; 

-- ---------------------------------------------------
prompt 8 - INVALID OBJECTS DETAILS
-- ---------------------------------------------------
col owner format a20
col object_name format a50
col status format a10
select owner,OBJECT_NAME, status FROM dba_objects WHERE status = 'INVALID';


-- ---------------------------------------------------
prompt 11 - TABLE SPACE Details and DB Size
-- ---------------------------------------------------

SELECT ROUND(SUM(TAILLE_BYTES)/1024/1024/1024,2) TAILLE_GIB FROM
(
    SELECT SUM(FILE_SIZE_BLKS*BLOCK_SIZE) TAILLE_BYTES FROM V$CONTROLFILE
    UNION ALL
    SELECT SUM(BYTES) FROM V$TEMPFILE
    UNION ALL
    SELECT SUM(BYTES) FROM V$DATAFILE
    UNION ALL
    SELECT SUM(MEMBERS*BYTES) FROM V$LOG
    UNION ALL
    SELECT BYTES FROM V$STANDBY_LOG SL, V$LOGFILE LF WHERE SL.GROUP# = LF.GROUP#
);

COL TABLESPACE_NAME FORMAT A20 HEAD "Nom espace|disque logique"
COL PCT_OCCUPATION_THEORIQUE FORMAT 990.00 HEAD "%occ|Theo"
COL TAILLE_MIB FORMAT 99999990.00 HEAD "Taille|MiB"
COL TAILLE_MAX_MIB FORMAT 99999990.00 HEAD "Taille max|MiB"
COL TAILLE_OCCUPEE_MIB FORMAT 99999990.00 HEAD "Espace occupé|MiB"
WITH TS_FREE_SPACE AS
(select tablespace_name, file_id, sum(bytes) FREE_O from dba_free_space group by tablespace_name, file_id
), TEMP_ALLOC AS
(select tablespace_name, file_id, sum(bytes) USED_O from v$temp_extent_map group by tablespace_name, file_id
)
SELECT
  TABLESPACE_NAME,
  SUM(TAILLE_MIB) TAILLE_MIB,
  SUM(TAILLE_MAX_MIB) TAILLE_MAX_MIB,
  SUM(TAILLE_OCCUPEE_MIB) TAILLE_OCCUPEE_MIB,
  ROUND(SUM(TAILLE_OCCUPEE_MIB)*100/SUM(GREATEST(TAILLE_MAX_MIB,TAILLE_MIB)),2) PCT_OCCUPATION_THEORIQUE
FROM
(
    SELECT D.FILE_NAME, D.TABLESPACE_NAME, D.BYTES/1024/1024 TAILLE_MIB, DECODE(D.AUTOEXTENSIBLE,'NO',D.BYTES,D.MAXBYTES)/1024/1024 TAILLE_MAX_MIB,
      (D.BYTES-FO.FREE_O)/1024/1024 TAILLE_OCCUPEE_MIB
    FROM
      DBA_DATA_FILES D, TS_FREE_SPACE FO
    WHERE
        D.TABLESPACE_NAME=FO.TABLESPACE_NAME
    AND D.FILE_ID=FO.FILE_ID
    UNION ALL
    SELECT T.FILE_NAME, T.TABLESPACE_NAME, T.BYTES/1024/1024 TAILLE_MIB, DECODE(T.AUTOEXTENSIBLE,'NO',T.BYTES,T.MAXBYTES)/1024/1024 TAILLE_MAX_MIB,
      (TA.USED_O)/1024/1024 TAILLE_OCCUPEE_MIB
    FROM
      DBA_TEMP_FILES T, TEMP_ALLOC TA
    WHERE
        T.TABLESPACE_NAME=TA.TABLESPACE_NAME
    AND T.FILE_ID=TA.FILE_ID
)
GROUP BY TABLESPACE_NAME
ORDER BY TABLESPACE_NAME;
CLEAR COL
/

-- ---------------------------------------------------
prompt 12 - TEMP TABLESPACE UTILIZATION
-- ---------------------------------------------------
SELECT A.tablespace_name tablespace, D.mb_total,SUM (A.used_blocks * D.block_size) / 1024 / 1024 mb_used,
D.mb_total - SUM (A.used_blocks * D.block_size) / 1024 / 1024 mb_free
FROM v$sort_segment A,
(
SELECT B.name, C.block_size, SUM (C.bytes) / 1024 / 1024 mb_total
FROM v$tablespace B, v$tempfile C
WHERE B.ts#= C.ts# GROUP BY B.name, C.block_size
) D
WHERE A.tablespace_name = D.name        GROUP by A.tablespace_name, D.mb_total;

-- ---------------------------------------------------
prompt 13 - LAST RMAN BACKUP STATUS
-- ---------------------------------------------------
alter session set nls_date_format='DD/MM/YYYY HH24:MI:SS' ;
set serveroutput on
set linesize 250 heading off;
set heading on pagesize 999;
column status format a25;
column input_bytes_display format a12;
column output_bytes_display format a12;
column device_type format a10;
declare
        base varchar2(40) ;
        serv varchar2(40) ;
begin
        select instance_name  into base from v$instance ;
        select host_name  into serv from v$instance ;
        dbms_output.put_line (' Rapport pour la base de donnee :' || base || ' sur le serveur : '|| serv );
end ;
/
select
        b.input_type,
        b.status,
        to_char(b.start_time,'DD-MM-YY HH24:MI') "Start Time",
        to_char(b.end_time,'DD-MM-YY HH24:MI') "End Time",
        b.output_device_type device_type,
        b.input_bytes_display,
        b.output_bytes_display
FROM v$rman_backup_job_details b
WHERE b.start_time > (SYSDATE - 30)
ORDER BY b.start_time asc;

-- ---------------------------------------------------
prompt 14 - Production Alert Log Error
-- ---------------------------------------------------
set pages 999 lines 150
select to_char(ORIGINATING_TIMESTAMP, 'DD-MM-YYYY HH-MM-SS') || ' : ' || message_text "Last alertlog (30 days)"
FROM X$DBGALERTEXT
WHERE originating_timestamp > systimestamp - 30  AND regexp_like(message_text, '(ORA-)');

-- ---------------------------------------------------
prompt 15 - Current sequence no in Production
-- ---------------------------------------------------

COL MEMBER FORMAT A90 WRAPPED
BREAK ON GROUP# SKIP 1 ON THREAD# ON SEQUENCE# ON TAILLE_MIB ON "STATUS(ARCHIVED)"
SELECT 'OnlineLog' T, G.GROUP#, G.THREAD#, G.SEQUENCE#, G.BYTES/1024/1024 TAILLE_MIB, G.STATUS||'('||G.ARCHIVED||')' "STATUS(ARCHIVED)", F.MEMBER
FROM V$LOG G, V$LOGFILE F
WHERE G.GROUP#=F.GROUP#
UNION ALL
SELECT 'StandbyLog',G.GROUP#, G.THREAD#, G.SEQUENCE#, G.BYTES/1024/1024 TAILLE_MIB, G.STATUS||'('||G.ARCHIVED||')' "STATUS(ARCHIVED)", F.MEMBER
FROM V$STANDBY_LOG G, V$LOGFILE F
WHERE G.GROUP#=F.GROUP#
ORDER BY 1,3,4,2;

-- ---------------------------------------------------
prompt 18 - Archive generated for the past 30 days
-- ---------------------------------------------------
set head off
select max('Taille des fichiers redolog (Mo) : ' || bytes/1024/1024) from v$log;

set head on
set pages 999 lines 200
col Date for a12
col Total for 9999
col 00 for 999
col 01 for 999
col 02 for 999
col 03 for 999
col 04 for 999
col 05 for 999
col 06 for 999
col 07 for 999
col 08 for 999
col 09 for 999
col 10 for 999
col 11 for 999
col 12 for 999
col 13 for 999
col 14 for 999
col 15 for 999
col 16 for 999
col 17 for 999
col 18 for 999
col 19 for 999
col 20 for 999
col 21 for 999
col 22 for 999
col 23 for 999
col 24 for 999


select to_char(first_time, 'YYYY/MM/dd') "Date",
count(1) "Total",
sum(decode(to_char(first_time, 'hh24'),'00',1,0)) "00",
sum(decode(to_char(first_time, 'hh24'),'01',1,0)) "01",
sum(decode(to_char(first_time, 'hh24'),'02',1,0)) "02",
sum(decode(to_char(first_time, 'hh24'),'03',1,0)) "03",
sum(decode(to_char(first_time, 'hh24'),'04',1,0)) "04",
sum(decode(to_char(first_time, 'hh24'),'05',1,0)) "05",
sum(decode(to_char(first_time, 'hh24'),'06',1,0)) "06",
sum(decode(to_char(first_time, 'hh24'),'07',1,0)) "07",
sum(decode(to_char(first_time, 'hh24'),'08',1,0)) "08",
sum(decode(to_char(first_time, 'hh24'),'09',1,0)) "09",
sum(decode(to_char(first_time, 'hh24'),'10',1,0)) "10",
sum(decode(to_char(first_time, 'hh24'),'11',1,0)) "11",
sum(decode(to_char(first_time, 'hh24'),'12',1,0)) "12",
sum(decode(to_char(first_time, 'hh24'),'13',1,0)) "13",
sum(decode(to_char(first_time, 'hh24'),'14',1,0)) "14",
sum(decode(to_char(first_time, 'hh24'),'15',1,0)) "15",
sum(decode(to_char(first_time, 'hh24'),'16',1,0)) "16",
sum(decode(to_char(first_time, 'hh24'),'17',1,0)) "17",
sum(decode(to_char(first_time, 'hh24'),'18',1,0)) "18",
sum(decode(to_char(first_time, 'hh24'),'19',1,0)) "19",
sum(decode(to_char(first_time, 'hh24'),'20',1,0)) "20",
sum(decode(to_char(first_time, 'hh24'),'21',1,0)) "21",
sum(decode(to_char(first_time, 'hh24'),'22',1,0)) "22",
sum(decode(to_char(first_time, 'hh24'),'23',1,0)) "23",
sum(decode(to_char(first_time, 'hh24'),'24',1,0)) "24"
from v$log_history
group by to_char(first_time, 'YYYY/MM/dd')
order by to_char(first_time, 'YYYY/MM/dd')
;

prompt Taille des redolog par jour 
select
        to_char(first_time, 'YYYY/MM/dd') "Jour",
    count(*) "Nbr de fichiers",
        ROUND(sum(BLOCKS*BLOCK_SIZE)/1024/1024, 0) "Taille_Mo"
from v$archived_log
group by to_char(first_time, 'YYYY/MM/dd')
order by to_char(first_time, 'YYYY/MM/dd')
;

prompt
-- spool off
set markup html off spool off
exit
 