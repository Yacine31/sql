col osuser format a15
col pid format 9999
col program format a20
col sid format 99999
col spid format a6
col username format a12

SELECT p.spid,p.pid,s.sid,s.serial#,s.status,p.pga_alloc_mem,p.PGA_USED_MEM,s.username,s.osuser,s.program
FROM v$process p,v$session s
WHERE s.paddr ( + ) = p.addr
-- AND p.background IS NULL      -- comment if need to monitor background processes
ORDER BY p.pga_alloc_mem DESC;

