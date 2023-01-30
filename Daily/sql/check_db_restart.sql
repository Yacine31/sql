alter session set nls_date_format='YYYY/MM/DD HH24:MI:SS';
col host_name format a15
SELECT instance_name, host_name, startup_time, status, logins FROM gv$instance ORDER BY 1;

