sqlplus -S / as sysdba << EOF
alter session set nls_date_format='YYYY/MM/DD HH24:MI';
set pages 999 lines 150
col message for a60
col OPNAME for a20
col ELASEC for 999999
select OPNAME, START_TIME, LAST_UPDATE_TIME, ELAPSED_SECONDS ELASEC, MESSAGE from v\$session_longops where opname like '%IMP%' order by LAST_UPDATE_TIME asc;
exit;
EOF

