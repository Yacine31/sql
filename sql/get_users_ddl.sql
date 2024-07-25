set longchunksize 20000 pagesize 0 feedback off verify off trimspool on
column Extracted_DDL format a1000

EXEC DBMS_METADATA.SET_TRANSFORM_PARAM(DBMS_METADATA.SESSION_TRANSFORM,'PRETTY',TRUE);
EXEC DBMS_METADATA.SET_TRANSFORM_PARAM(DBMS_METADATA.SESSION_TRANSFORM,'SQLTERMINATOR',TRUE);

undefine User_in_Uppercase;

set linesize 1000
set long 2000000000
select (case
when ((select count(*)
from dba_users
where username = UPPER('&&User_in_Uppercase') and profile <> 'DEFAULT') > 0)
then chr(10)||' -- Note: Profile'||(select dbms_metadata.get_ddl('PROFILE', u.profile) AS ddl from dba_users u where u.username = UPPER('&User_in_Uppercase'))
else to_clob (chr(10)||' -- Note: Default profile, no need to create!')
end ) from dual
UNION ALL
select (case
when ((select count(*)
from dba_users
where username = UPPER('&User_in_Uppercase')) > 0)
then ' -- Note: Create user statement'||dbms_metadata.get_ddl ('USER', UPPER('&User_in_Uppercase'))
else to_clob (chr(10)||' -- Note: User not found!')
end ) Extracted_DDL from dual
UNION ALL
select (case
when ((select count(*)
from dba_ts_quotas
where username = UPPER('&User_in_Uppercase')) > 0)
then ' -- Note: TBS quota'||dbms_metadata.get_granted_ddl( 'TABLESPACE_QUOTA', UPPER('&User_in_Uppercase'))
else to_clob (chr(10)||' -- Note: No TS Quotas found!')
end ) from dual
UNION ALL
select (case
when ((select count(*)
from dba_role_privs
where grantee = UPPER('&User_in_Uppercase')) > 0)
then ' -- Note: Roles'||dbms_metadata.get_granted_ddl ('ROLE_GRANT', UPPER('&User_in_Uppercase'))
else to_clob (chr(10)||' -- Note: No granted Roles found!')
end ) from dual
UNION ALL
select (case
when ((select count(*)
from V$PWFILE_USERS
where username = UPPER('&User_in_Uppercase') and SYSDBA='TRUE') > 0)
then ' -- Note: sysdba'||chr(10)||to_clob (' GRANT SYSDBA TO '||'"'||UPPER('&User_in_Uppercase')||'"'||';')
else to_clob (chr(10)||' -- Note: No sysdba administrative Privilege found!')
end ) from dual
UNION ALL
select (case
when ((select count(*)
from dba_sys_privs
where grantee = UPPER('&User_in_Uppercase')) > 0)
then ' -- Note: System Privileges'||dbms_metadata.get_granted_ddl ('SYSTEM_GRANT', UPPER('&User_in_Uppercase'))
else to_clob (chr(10)||' -- Note: No System Privileges found!')
end ) from dual
UNION ALL
select (case
when ((select count(*)
from dba_tab_privs
where grantee = UPPER('&User_in_Uppercase')) > 0)
then ' -- Note: Object Privileges'||dbms_metadata.get_granted_ddl ('OBJECT_GRANT', UPPER('&User_in_Uppercase'))
else to_clob (chr(10)||' -- Note: No Object Privileges found!')
end ) from dual
/