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
exit
