prompt <h2>Database Status</h2>
alter session set nls_date_format='YYYY/MM/DD HH24:MI:SS';
SELECT instance_name, host_name, startup_time, status, logins FROM gv$instance ORDER BY 1;
exit

