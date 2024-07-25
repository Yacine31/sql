-- 
-- lorsqu'on vérifie les options utilisées par la base, "Automatic SQL Tuning Advisor" sort aussi 
-- même si la base n'est pas licenciée avec Tuning Pack
-- Ce script permet de voir et désactiver les tâches automatiques 
-- pour ne pas avoir à licencier Tuning Pack
-- 
set lines 180 pages 1000
col client_name for a40
col attributes for a60
col service_name for a20
select client_name, status,attributes,service_name from dba_autotask_client
/
 
BEGIN
  DBMS_AUTO_TASK_ADMIN.disable(
    client_name => 'auto space advisor',
    operation   => NULL,
    window_name => NULL);
END;
/
 
BEGIN
  DBMS_AUTO_TASK_ADMIN.disable(
    client_name => 'sql tuning advisor',
    operation   => NULL,
    window_name => NULL);
END;
/
 
-- BEGIN
--   DBMS_AUTO_TASK_ADMIN.disable
-- (
--     client_name => 'auto optimizer stats collection',
--     operation   => NULL,
--     window_name => NULL);
-- END;
-- /
 
select client_name, status,attributes,service_name from dba_autotask_client
/
 
-- pour réactiver les auto task remplacer DBMS_AUTO_TASK_ADMIN.disable par DBMS_AUTO_TASK_ADMIN.enable

-- BEGIN
-- dbms_auto_task_admin.enable(client_name => 'sql tuning advisor', operation => NULL, window_name => NULL);
-- END;
-- /

-- BEGIN
-- DBMS_AUTO_TASK_ADMIN.enable(client_name => 'sql tuning advisor', operation   => NULL, window_name => NULL);
-- END;
-- /
 
-- BEGIN
-- DBMS_AUTO_TASK_ADMIN.enable(client_name => 'auto optimizer stats collection', operation   => NULL, window_name => NULL);
-- END;
-- /

