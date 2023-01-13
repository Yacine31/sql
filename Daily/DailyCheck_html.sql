SET TERMOUT OFF
SET ECHO OFF
SET SERVEROUTPUT OFF
set feedback off
set echo off pagesize 1000 markup html on ENTMAP OFF spool on -
TABLE BORDER='1'
spool /home/oracle/Daily/logs/DailyCheck.html
prompt 1)
prompt********************************Current DATE********************************************************
select to_char(sysdate,'DD-MON-YYYY:HH24:MI:SS') "CURRENT DATE" from dual;


prompt 2)
prompt********************************DB SIZE********************************************************
select sum(bytes)/1024/1024/1024 TOTAL_SIZE_GB from dba_data_files;


prompt 3)
prompt********************************INSTANCE STATUS********************************************************
select inst_id,instance_name, status, database_status, active_state, startup_time FROM  gv$instance;


prompt 4)
prompt**************************ARCHIVE LOG MODE****************************************************************************

SELECT inst_id,name, open_mode, log_mode FROM gv$database;
prompt Archive Log Sequence :
archive log list;
prompt 5)

prompt**************************Number of tablespaces************************************************************************

SELECT COUNT (0) "No. of tablespaces" FROM v$tablespace;


prompt 6)
prompt**************************Number of Datafiles********************************************************************
SELECT COUNT (0) "No. of Data Files" FROM dba_data_files;


prompt 7)
prompt**************************ASM Disk, space and Archive Log Details********************************************************************

select GROUP_NUMBER,NAME,STATE,OFFLINE_DISKS from v$asm_diskgroup;


set lines 300
select name, state, type, total_mb/1024/1024 "Total Space in TB", free_mb/1024/1024 "Free space in TB", Usable_file_mb/1024/1024 "Useable Space in TB" from v$asm_diskgroup ;

set lines 300
select * from v$flash_recovery_area_usage;

prompt 8)
prompt********************************INVALID OBJECTS DETAILS************************************************************
col owner format a20
col object_name format a50
col status format a10
select owner,OBJECT_NAME, status FROM dba_objects WHERE status = 'INVALID';

prompt 9)
prompt********************************Locked Sessions**************************************************************
set feedback off;
alter session set nls_date_format='DD-MON-YY hh24:MI:SS';
set feedback on;
select 'SID '||a.sid||' is blocking the sessions '||b.sid from     gv$lock a, gv$lock b where a.block=1 and b.request >0;
prompt Lock Holder and Waiter details :
col "Lock Type" for a10;
SELECT DECODE(request,0,'Holder: ','Waiter: '), sid, lmode "Lock Mode", type "Lock Type", block FROM V$LOCK WHERE (id1, id2, type) IN
(SELECT id1, id2, type FROM GV$LOCK WHERE request>0) ORDER BY id1, request;
prompt Session locking time in minutes :
select sid,serial#,status,logon_time,sysdate,round( (sysdate-logon_time)*24*60 ) "Locking Minutes"
from gv$session where sid IN (select a.sid from v$lock a, v$lock b where a.block=1 and b.request >0);

prompt 10)
prompt****************************** Active Session Details running more than 60 minutes **********************************************************
select p.spid spid,s.sid sid, s.serial# "serial", s.status "status", s.username "oracle username", s.action,
to_char(s.logon_time, 'DD-MON-YY, HH24:MI') "logon time",
s.module "MODULE",s.program "PROGRAM",round(s.last_call_et/60,0) "Running since Minutes" ,s.process "client process",s.machine "client machine",s.osuser  "osuser"
from gv$session s, gv$process p
where p.addr=s.paddr
and s.type!='BACKGROUND'
and s.status='ACTIVE'
and last_call_et/60  > 60
and rownum < 150
order by 10 desc;

prompt 11)
prompt******************************* TABLE SPACE Details and DB Size ****************************************************************

set linesize 132 tab off trimspool on
set pagesize 105
set pause off
set echo off
set feedb on

column TABLESPACE_NAME format a30 
select TABLESPACE_NAME,USED_PERCENT from DBA_TABLESPACE_USAGE_METRICS order by USED_PERCENT;

set linesize 110
COLUMN dummy    NOPRINT
COLUMN pct_used FORMAT 99.9       HEADING "% Used"
COLUMN name     FORMAT a30         HEADING "Tablespace"
COLUMN Kbytes   FORMAT 99,999,999,999 HEADING "KBytes"
COLUMN used     FORMAT 99,999,999,999 HEADING "Used"
COLUMN free     FORMAT 99,999,999,999 HEADING "Free"
COLUMN largest  FORMAT 9,999,999,999 HEADING "Largest"
COLUMN largest_rq  FORMAT 99,999,999 HEADING "Largest_rq"
BREAK ON report
COMPUTE SUM OF kbytes ON REPORT
COMPUTE SUM OF free   ON REPORT
COMPUTE SUM OF used   ON REPORT
col tablespace format a60
set lines 200 pages 50
SELECT SYSDATE FROM DUAL 
/
SELECT NVL(b.tablespace_name,NVL(a.tablespace_name,'UNKOWN')) name,
           kbytes_alloc kbytes,
           kbytes_alloc-nvl(kbytes_free,0) used,
           NVL(kbytes_free,0) free,
           ((kbytes_alloc-nvl(kbytes_free,0))/kbytes_alloc)*100 pct_used,
           NVL(largest,0) largest, NVL (c.largest_req,0) largest_rq,
           decode(substr(((nvl(largest,0) - nvl (c.largest_req,0) * 5)),1,1),'-','FAILED') 
FROM ( SELECT SUM(bytes)/1024 Kbytes_free,
                          max(bytes)/1024 largest,
                          tablespace_name
           FROM sys.dba_free_space
           GROUP BY tablespace_name ) a,
     ( SELECT SUM(bytes)/1024 Kbytes_alloc,
                          tablespace_name
           FROM sys.dba_data_files
           GROUP BY tablespace_name ) b,
      (select max(next_extent)/1024 largest_req,tablespace_name from dba_segments
        group by tablespace_name ) c
WHERE a.tablespace_name (+) = b.tablespace_name
and a.tablespace_name = c.tablespace_name 
order by pct_used desc
/
select tablespace_name,sum(bytes)/(1024*1024*1024) "Size Gig"
from dba_temp_files
group by tablespace_name
/
select 2 * (sum(bytes)/(1024*1024*1024)) "Redo size Gig"
from v$log
/

prompt 12)
prompt***************************TEMP TABLESPACE UTILIZATION****************************************************************
SELECT A.tablespace_name tablespace, D.mb_total,SUM (A.used_blocks * D.block_size) / 1024 / 1024 mb_used,
D.mb_total - SUM (A.used_blocks * D.block_size) / 1024 / 1024 mb_free
FROM v$sort_segment A,
(
SELECT B.name, C.block_size, SUM (C.bytes) / 1024 / 1024 mb_total
FROM v$tablespace B, v$tempfile C
WHERE B.ts#= C.ts# GROUP BY B.name, C.block_size
) D
WHERE A.tablespace_name = D.name        GROUP by A.tablespace_name, D.mb_total;

prompt 12A)
prompt****************************** Details of XX_LOGON_RECORDS Table  **********************************************************

select count(*) number_of_records from xlcaudit.XX_LOGON_RECORDS having count(*) > 110000;

col segment_name format a20
col owner format a15
select OWNER,segment_name, sum(bytes)/1024/1024 "Size in MB" from dba_segments where segment_name = 'XX_LOGON_RECORDS' and owner='XLCAUDIT' group by segment_name,owner;

prompt******************************  Count for the past 24 Hours from XX_LOGON_RECORDS Table  **********************************************************

select count (*) from xlcaudit.XX_LOGON_RECORDS where sample_time > sysdate -1 order by sample_time;

prompt 13)
prompt****************************LAST 90 RMAN BACKUP STATUS****************************************************************
set linesize 150
set pages 300
column "SIZE" format a10
select to_char(start_time,'yyyy-mm-dd hh24:mi') start_time,TO_CHAR(end_time, 'yyyy-mm-dd hh24:mi') End_Time, input_type,   
output_bytes_display "SIZE",round(sum(elapsed_seconds)/60) "Time taken in Min", status 
from v$rman_backup_job_details where end_time>trunc(sysdate)-90 
group by to_char(start_time,'yyyy-mm-dd hh24:mi'),TO_CHAR(end_time, 'yyyy-mm-dd hh24:mi'),output_bytes_display, input_type,status 
order by 2 desc;


prompt 14)
prompt******************************** Production Alert Log Error ********************************************************
select to_char(ORIGINATING_TIMESTAMP, 'DD-MON-YYYY HH-MM-SS') "ORIGINATING_TIMESTAMP",  message_text
FROM X$DBGALERTEXT
WHERE originating_timestamp > systimestamp - 1  AND regexp_like(message_text, '(ORA-)');

prompt 15)
prompt******************************** Current sequence no in Production ********************************************************

select thread#, max(sequence#) from gv$archived_log group by thread#;

prompt 16)
prompt********************************Archive Gaps between Production and DROBIXP ********************************************************
ALTER SESSION SET NLS_DATE_FORMAT = 'DD-MON-YYYY HH24:MI:SS';

SELECT   a.thread#,  b. last_seq, a.applied_seq, a.last_app_timestamp, b.last_seq-a.applied_seq   ARCHIVE_GAP
FROM (SELECT  thread#, MAX(sequence#) applied_seq, MAX(next_time) last_app_timestamp
FROM gv$archived_log WHERE applied = 'YES' and name='DROBIXP' GROUP BY thread#) a,
(SELECT  thread#, MAX (sequence#) last_seq FROM gv$archived_log where name='DROBIXP' GROUP BY thread#) b WHERE a.thread# = b.thread#;


prompt 17)
prompt********************************Archive Gaps between Production and DROBXPRD ********************************************************
ALTER SESSION SET NLS_DATE_FORMAT = 'DD-MON-YYYY HH24:MI:SS';


SELECT   a.thread#,  b. last_seq, a.applied_seq, a.last_app_timestamp, b.last_seq-a.applied_seq   ARCHIVE_GAP
FROM (SELECT  thread#, MAX(sequence#) applied_seq, MAX(next_time) last_app_timestamp
FROM gv$archived_log WHERE applied = 'YES' and name='DROBXPRD' GROUP BY thread#) a,
(SELECT  thread#, MAX (sequence#) last_seq FROM gv$archived_log where name='DROBXPRD' GROUP BY thread#) b WHERE a.thread# = b.thread#;


prompt 18)
prompt********************************Archive generated for the past 7 days ********************************************************
set echo off;
set pages 10000
set sqlbl on;
col day for a12
set lines 1000
set pages 999
col "00" for a3
col "01" for a3
col "02" for a3
col "03" for a3
col "04" for a3
col "05" for a3
col "06" for a3
col "07" for a3
col "08" for a3
col "09" for a3
col "10" for a3
col "11" for a3
col "12" for a3
col "13" for a3
col "14" for a3
col "15" for a3
col "16" for a4
col "17" for a3
col "18" for a4
col "19" for a3
col "20" for a3
col "21" for a3
col "22" for a3
col "23" for a3

SELECT
to_char(first_time,'DD-MON-YYYY') day,
to_char(sum(decode(to_char(first_time,'HH24'),'00',1,0)),'9999') "00",
to_char(sum(decode(to_char(first_time,'HH24'),'01',1,0)),'9999') "01",
to_char(sum(decode(to_char(first_time,'HH24'),'02',1,0)),'9999') "02",
to_char(sum(decode(to_char(first_time,'HH24'),'03',1,0)),'9999') "03",
to_char(sum(decode(to_char(first_time,'HH24'),'04',1,0)),'9999') "04",
to_char(sum(decode(to_char(first_time,'HH24'),'05',1,0)),'9999') "05",
to_char(sum(decode(to_char(first_time,'HH24'),'06',1,0)),'9999') "06",
to_char(sum(decode(to_char(first_time,'HH24'),'07',1,0)),'9999') "07",
to_char(sum(decode(to_char(first_time,'HH24'),'08',1,0)),'9999') "08",
to_char(sum(decode(to_char(first_time,'HH24'),'09',1,0)),'9999') "09",
to_char(sum(decode(to_char(first_time,'HH24'),'10',1,0)),'9999') "10",
to_char(sum(decode(to_char(first_time,'HH24'),'11',1,0)),'9999') "11",
to_char(sum(decode(to_char(first_time,'HH24'),'12',1,0)),'9999') "12",
to_char(sum(decode(to_char(first_time,'HH24'),'13',1,0)),'9999') "13",
to_char(sum(decode(to_char(first_time,'HH24'),'14',1,0)),'9999') "14",
to_char(sum(decode(to_char(first_time,'HH24'),'15',1,0)),'9999') "15",
to_char(sum(decode(to_char(first_time,'HH24'),'16',1,0)),'9999') "16",
to_char(sum(decode(to_char(first_time,'HH24'),'17',1,0)),'9999') "17",
to_char(sum(decode(to_char(first_time,'HH24'),'18',1,0)),'9999') "18",
to_char(sum(decode(to_char(first_time,'HH24'),'19',1,0)),'9999') "19",
to_char(sum(decode(to_char(first_time,'HH24'),'20',1,0)),'9999') "20",
to_char(sum(decode(to_char(first_time,'HH24'),'21',1,0)),'9999') "21",
to_char(sum(decode(to_char(first_time,'HH24'),'22',1,0)),'9999') "22",
to_char(sum(decode(to_char(first_time,'HH24'),'23',1,0)),'9999') "23",
count(*) Total
from
gv$log_history
WHERE first_time > sysdate -7
GROUP by
to_char(first_time,'DD-MON-YYYY'),trunc(first_time) order by trunc(first_time);

prompt*******************************************************************************************************************
prompt
spool off
set markup html off spool off
exit
 