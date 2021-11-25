--
-- Le script prend en parametre un compte utilisateur
-- ensuite il retourne les requetes pour creer les grants associe a ce compte
-- un fichier grant_USER.lst est généré dans le répertoire courant
--
set heading off pages 0 feedback off echo off verify off
ACCEPT v_user CHAR PROMPT 'compte utilisateur pour lequel on va extraire les GRANTS : '

SPOOL grant_&v_user
SELECT 'REM Les roles :' FROM DUAL;
SELECT DISTINCT 'CREATE ROLE '||GRANTED_ROLE||';' FROM DBA_ROLE_PRIVS WHERE GRANTEE IN &v_users;

SELECT 'REM Les GRANTs depuis DBA_ROLE_PRIVS  :' FROM DUAL;
SELECT DISTINCT 'GRANT '||GRANTED_ROLE||' TO '||GRANTEE|| CASE WHEN ADMIN_OPTION='YES' THEN ' WITH ADMIN OPTION;' ELSE ';' END "Granted Roles" FROM DBA_ROLE_PRIVS WHERE GRANTEE IN &v_users ORDER BY 1;

SELECT 'REM Les GRANTs depuis DBA_SYS_PRIVS  :' FROM DUAL;
SELECT DISTINCT 'GRANT '||PRIVILEGE||' TO '||GRANTEE|| CASE WHEN ADMIN_OPTION='YES' THEN ' WITH ADMIN OPTION;' ELSE ';' END "Granted System Privileges" FROM DBA_SYS_PRIVS WHERE GRANTEE IN &v_users;

SELECT 'REM Les GRANTs depuis DBA_TAB_PRIVS  :' FROM DUAL;
SELECT DISTINCT 'GRANT '||PRIVILEGE||' ON '||OWNER||'.'||TABLE_NAME||' TO '||GRANTEE||CASE WHEN GRANTABLE='YES' THEN ' WITH GRANT OPTION;' ELSE ';' END "Granted Object Privileges" FROM DBA_TAB_PRIVS WHERE GRANTEE IN &v_users;

SELECT 'REM Les GRANTs depuis DBA_TAB_PRIVS pour le compte PUBLIC sur les objets SYS.DBMS_XXX :' FROM DUAL;
SELECT DISTINCT 'GRANT '||PRIVILEGE||' ON '||OWNER||'.'||TABLE_NAME||' TO '||GRANTEE||CASE WHEN GRANTABLE='YES' THEN ' WITH GRANT OPTION;' ELSE ';' END "Granted Object Privileges" FROM DBA_TAB_PRIVS WHERE GRANTEE IN ('PUBLIC') and OWNER='SYS' and TABLE_NAME like '%DBMS_%' order by 1;

SPOOL OFF
EXIT

