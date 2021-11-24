--
-- Le script prend en parametre un compte utilisateur
-- ensuite il retourne les requetes pour creer les grants associe a ce compte
-- un fichier grant_USER.lst est généré dans le répertoire courant
--
SET PAGES 999 HEAD OFF FEEDBACK OFF
ACCEPT v_user CHAR PROMPT 'compte utilisateur pour lequel on va extraire les GRANTS : '
set verify off

SPOOL grant_&v_user
SELECT '-- Les roles pour le compte &v_user :' FROM DUAL;
SELECT DISTINCT 'CREATE ROLE '||GRANTED_ROLE||';' FROM DBA_ROLE_PRIVS WHERE GRANTEE=upper('&v_user');

SELECT '-- Les GRANTs depuis DBA_ROLE_PRIVS pour le compte &v_user :' FROM DUAL;
SELECT DISTINCT 'GRANT '||GRANTED_ROLE||' TO '||GRANTEE|| CASE WHEN ADMIN_OPTION='YES' THEN ' WITH ADMIN OPTION;' ELSE ';' END "Granted Roles" FROM DBA_ROLE_PRIVS WHERE GRANTEE=upper('&v_user') ORDER BY 1;

SELECT '-- Les GRANTs depuis DBA_SYS_PRIVS pour le compte &v_user :' FROM DUAL;
SELECT 'GRANT '||PRIVILEGE||' TO '||GRANTEE|| case when ADMIN_OPTION='YES' THEN ' WITH ADMIN OPTION;' ELSE ';' END "Granted System Privileges" FROM DBA_SYS_PRIVS WHERE GRANTEE=upper('&v_user');

SELECT '-- Les GRANTs depuis DBA_TAB_PRIVS pour le compte &v_user :' FROM DUAL;
SELECT DISTINCT 'GRANT '||PRIVILEGE||' ON '||OWNER||'.'||TABLE_NAME||' TO '||GRANTEE||CASE WHEN GRANTABLE='YES' THEN ' WITH GRANT OPTION;' ELSE ';' END "Granted Object Privileges" FROM DBA_TAB_PRIVS WHERE GRANTEE=upper('&v_user');

SPOOL OFF
EXIT

