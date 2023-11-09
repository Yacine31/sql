-- Qui est connecté à la base :
prompt <h2>Who is connected ? </h2>

set pages 999 lines 200
col PROGRAM for a35
col MACHINE for a20
col OSUSER for a10
alter session set nls_date_format='YYYY/MM/DD HH24:MI:SS';
select OSUSER, MACHINE, PROGRAM, STATE, LOGON_TIME from v$session order by LOGON_TIME asc;
exit
