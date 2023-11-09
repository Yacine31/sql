prompt <h2>Database Size </h2>
-- set head off
-- col "Database Size" format 99,999.99
-- select 'Database Size (Go) : ' || (
--     SELECT ROUND(SUM(TAILLE_BYTES)/1024/1024/1024,2) "Database Size" FROM
--         (
--             SELECT SUM(FILE_SIZE_BLKS*BLOCK_SIZE) TAILLE_BYTES FROM V$CONTROLFILE
--             UNION ALL
--             SELECT SUM(BYTES) FROM V$TEMPFILE
--             UNION ALL
--             SELECT SUM(BYTES) FROM V$DATAFILE
--             UNION ALL
--             SELECT SUM(MEMBERS*BYTES) FROM V$LOG
--             UNION ALL
--             SELECT BYTES FROM V$STANDBY_LOG SL, V$LOGFILE LF WHERE SL.GROUP# = LF.GROUP#
--         )
--     )
-- from dual;

WITH
sizes AS (
SELECT /*+  MATERIALIZE NO_MERGE  */ /* 1f.60 */
       'Data' file_type,
       SUM(bytes) bytes
  FROM v$datafile
 UNION ALL
SELECT 'Temp' file_type,
       SUM(bytes) bytes
  FROM v$tempfile
 UNION ALL
SELECT 'Log' file_type,
       SUM(bytes) * MAX(members) bytes
  FROM v$log
 UNION ALL
SELECT 'Control' file_type,
       SUM(block_size * file_size_blks) bytes
  FROM v$controlfile
),
dbsize AS (
SELECT /*+  MATERIALIZE NO_MERGE  */ /* 1f.60 */
       'Total' file_type,
       SUM(bytes) bytes
  FROM sizes
)
SELECT d.dbid,
       d.name db_name,
       s.file_type,
       s.bytes,
       CASE
       WHEN s.bytes > POWER(10,15) THEN ROUND(s.bytes/POWER(10,15),3)||' P'
       WHEN s.bytes > POWER(10,12) THEN ROUND(s.bytes/POWER(10,12),3)||' T'
       WHEN s.bytes > POWER(10,9) THEN ROUND(s.bytes/POWER(10,9),3)||' G'
       WHEN s.bytes > POWER(10,6) THEN ROUND(s.bytes/POWER(10,6),3)||' M'
       WHEN s.bytes > POWER(10,3) THEN ROUND(s.bytes/POWER(10,3),3)||' K'
       WHEN s.bytes > 0 THEN s.bytes||' B' END approx
  FROM v$database d,
       sizes s
 UNION ALL
SELECT d.dbid,
       d.name db_name,
       s.file_type,
       s.bytes,
       CASE
       WHEN s.bytes > POWER(10,15) THEN ROUND(s.bytes/POWER(10,15),3)||' P'
       WHEN s.bytes > POWER(10,12) THEN ROUND(s.bytes/POWER(10,12),3)||' T'
       WHEN s.bytes > POWER(10,9) THEN ROUND(s.bytes/POWER(10,9),3)||' G'
       WHEN s.bytes > POWER(10,6) THEN ROUND(s.bytes/POWER(10,6),3)||' M'
       WHEN s.bytes > POWER(10,3) THEN ROUND(s.bytes/POWER(10,3),3)||' K'
       WHEN s.bytes > 0 THEN s.bytes||' B' END approx
  FROM v$database d,
       dbsize s;
exit