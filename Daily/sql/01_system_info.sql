prompt <h2>System Information</h2>
WITH /* 1a.1 */
 rac AS (SELECT /*+  MATERIALIZE NO_MERGE  */ COUNT(*) instances, CASE COUNT(*) WHEN 1 THEN 'Single-instance' ELSE COUNT(*)||'-node RAC cluster' END db_type FROM gv$instance),
hrac AS (SELECT /*+  MATERIALIZE NO_MERGE  */ CASE 1 WHEN 1 THEN ' (historically Single-instance in AWR)' ELSE ' (historicly 1-node RAC cluster in AWR)' END db_type
           FROM rac WHERE TO_CHAR(RAC.instances)<>1),
mem AS (SELECT /*+  MATERIALIZE NO_MERGE  */ SUM(value) target FROM gv$system_parameter2 WHERE name = 'memory_target'),
sga AS (SELECT /*+  MATERIALIZE NO_MERGE  */ SUM(value) target FROM gv$system_parameter2 WHERE name = 'sga_target'),
pga AS (SELECT /*+  MATERIALIZE NO_MERGE  */ SUM(value) target FROM gv$system_parameter2 WHERE name = 'pga_aggregate_target'),
db_block AS (SELECT /*+  MATERIALIZE NO_MERGE  */ value bytes FROM v$system_parameter2 WHERE name = 'db_block_size'),
db AS (SELECT /*+  MATERIALIZE NO_MERGE  */ name, platform_name FROM v$database),
 pdbs AS (SELECT /*+  MATERIALIZE NO_MERGE  */ * FROM v$pdbs), -- need 12c flag
inst AS (SELECT /*+  MATERIALIZE NO_MERGE  */ host_name, version db_version FROM v$instance),
data AS (SELECT /*+  MATERIALIZE NO_MERGE  */ SUM(bytes) bytes, COUNT(*) files, COUNT(DISTINCT ts#) tablespaces FROM v$datafile),
temp AS (SELECT /*+  MATERIALIZE NO_MERGE  */ SUM(bytes) bytes FROM v$tempfile),
log AS (SELECT /*+  MATERIALIZE NO_MERGE  */ SUM(bytes) * MAX(members) bytes FROM v$log),
control AS (SELECT /*+  MATERIALIZE NO_MERGE  */ SUM(block_size * file_size_blks) bytes FROM v$controlfile),
core AS (SELECT /*+  MATERIALIZE NO_MERGE  */ SUM(value) cnt FROM gv$osstat WHERE stat_name = 'NUM_CPU_CORES'),
cpu AS (SELECT /*+  MATERIALIZE NO_MERGE  */ SUM(value) cnt FROM gv$osstat WHERE stat_name = 'NUM_CPUS'),
pmem AS (SELECT /*+  MATERIALIZE NO_MERGE  */ SUM(value) bytes FROM gv$osstat WHERE stat_name = 'PHYSICAL_MEMORY_BYTES')
SELECT /*+  NO_MERGE  */ /* 1a.1 */
       'Database name:' system_item, db.name system_value FROM db
UNION ALL
 SELECT '    pdb:'||name, 'Open Mode:'||open_mode FROM pdbs -- need 12c flag
  UNION ALL
SELECT 'Oracle Database version:', inst.db_version FROM inst
 UNION ALL
SELECT 'Database block size:', TRIM(TO_CHAR(db_block.bytes / POWER(2,10), '90'))||' KB' FROM db_block
 UNION ALL
SELECT 'Database size:', TRIM(TO_CHAR(ROUND((data.bytes + temp.bytes + log.bytes + control.bytes) / POWER(10,12), 3), '999,999,990.000'))||' TB'
  FROM db, data, temp, log, control
 UNION ALL
SELECT 'Datafiles:', data.files||' (on '||data.tablespaces||' tablespaces)' FROM data
 UNION ALL
SELECT 'Instance configuration:', rac.db_type||(select hrac.db_type FROM hrac ) FROM rac
 UNION ALL
SELECT 'Database memory:',
CASE WHEN mem.target > 0 THEN 'MEMORY '||TRIM(TO_CHAR(ROUND(mem.target / POWER(2,30), 1), '999,990.0'))||' GB, ' END||
CASE WHEN sga.target > 0 THEN 'SGA '   ||TRIM(TO_CHAR(ROUND(sga.target / POWER(2,30), 1), '999,990.0'))||' GB, ' END||
CASE WHEN pga.target > 0 THEN 'PGA '   ||TRIM(TO_CHAR(ROUND(pga.target / POWER(2,30), 1), '999,990.0'))||' GB, ' END||
CASE WHEN mem.target > 0 THEN 'AMM' ELSE CASE WHEN sga.target > 0 THEN 'ASMM' ELSE 'MANUAL' END END
  FROM mem, sga, pga
 UNION ALL
SELECT 'Hardware:', 'Unknown' FROM dual
 UNION ALL
SELECT 'Storage:','' FROM DUAL WHERE '' IS NOT NULL
 UNION ALL
SELECT 'Storage Version:','' FROM DUAL WHERE '' IS NOT NULL
 UNION ALL
SELECT 'Processor:', 'Common KVM processor' FROM DUAL
 UNION ALL
SELECT 'Physical CPUs:', core.cnt||' cores'||CASE WHEN rac.instances > 0 THEN ', on '||rac.db_type END FROM rac, core
 UNION ALL
SELECT 'Oracle CPUs:', cpu.cnt||' CPUs (threads)'||CASE WHEN rac.instances > 0 THEN ', on '||rac.db_type END FROM rac, cpu
 UNION ALL
SELECT 'Physical RAM:', TRIM(TO_CHAR(ROUND(pmem.bytes / POWER(2,30), 1), '999,990.0'))||' GB'||CASE WHEN rac.instances > 0 THEN ', on '||rac.db_type END FROM rac, pmem
 UNION ALL
SELECT 'Operating system:', db.platform_name FROM db;
exit 
