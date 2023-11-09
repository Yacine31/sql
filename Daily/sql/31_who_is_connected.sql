-- Qui est connecté à la base :
prompt <h2>Sessions Aggregate per User and Type</h2>
WITH x as (
SELECT COUNT(*),
	   --con_id,
       username,
       inst_id,
       type,
       server,
       status,
       state
  FROM gv$session
 GROUP BY
	   --con_id,
       username,
       inst_id,
       type,
       server,
       status,
       state
)
SELECT x.*
       --,c.name con_name
FROM   x
       --LEFT OUTER JOIN v$containers c ON c.con_id = x.con_id
 ORDER BY
       1 DESC,
	   --x.con_id,
	   x.username, x.inst_id, x.type, x.server, x.status, x.state;


prompt <h2>Sessions Aggregate per Module and Action</h2>
WITH x AS (
SELECT COUNT(*),
	   --con_id,
       module,
       action,
       inst_id,
       type,
       server,
       status,
       state
  FROM gv$session
 GROUP BY
	   --con_id,
       module,
       action,
       inst_id,
       type,
       server,
       status,
       state
)
SELECT x.*
      --,c.name con_name
FROM   x
       --LEFT OUTER JOIN v$containers c ON c.con_id = x.con_id
 ORDER BY
       1 DESC,
	   --x.con_id,
	   x.module, x.action, x.inst_id, x.type, x.server, x.status, x.state;

prompt <h2>Who is connected ? </h2>

set pages 999 lines 200
col PROGRAM for a35
col MACHINE for a20
col OSUSER for a10
alter session set nls_date_format='YYYY/MM/DD HH24:MI:SS';
select OSUSER, MACHINE, PROGRAM, STATE, LOGON_TIME, EVENT from v$session order by LOGON_TIME asc;
exit
