prompt <h2>Database Users </h2>
set pages 999
ALTER SESSION SET NLS_DATE_FORMAT ='YYYY/MM/DD HH24:MI';
-- select USERNAME, ACCOUNT_STATUS, PROFILE, DEFAULT_TABLESPACE DEF_TBS, TEMPORARY_TABLESPACE TMP_TBS, CREATED, PASSWORD_VERSIONS from dba_users order by created;
SELECT /*+  NO_MERGE  */ 
       x.username,
       x.user_id,
       x.account_status,
       x.lock_date,
       x.expiry_date,
       x.default_tablespace,
       x.temporary_tablespace,
       x.created,
       x.profile, x.password_versions, x.password_change_date
       --,c.name con_name
  FROM dba_users x
       --LEFT OUTER JOIN v$containers c ON c.con_id = x.con_id
 ORDER BY x.username
          --,x.con_id;
exit
