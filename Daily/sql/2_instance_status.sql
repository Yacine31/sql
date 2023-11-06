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

SELECT inst_id, name, to_char(CREATED ,'DD/MM/YYYY') CREATED , open_mode, DATABASE_ROLE, log_mode, FORCE_LOGGING, CURRENT_SCN FROM gv$database;

exit
