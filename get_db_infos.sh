#!/bin/bash
#------------------------------------------------------------------------
# Historique :
#       10/11/2025 : Gemini - Améliorations : performance et robustesse
#------------------------------------------------------------------------
# Script pour récupérer les paramètres des bases avant migration
# Exemple de sortie :
# 
# db_name,db_unique_name,global_names,db_domain,compatible,service_names,memory_target,sga_target,pga_aggregate_target,processes,open_cursors
# ora12os7.local,DBSE,DBSE,FALSE,,11.2.0.4.0,DBSE,0,1241513984,412090368,150,300
# ora12os7.local,orcl1120,orcl1120,FALSE,,11.2.0.4.0,orcl1120,1660944384,0,0,150,300
# ---------
# db_name,db_unique_name,NLS_CHARACTERSET,NLS_NCHAR_CHARACTERSET,NLS_SORT,NLS_LANGUAGE,NLS_TERRITORY
# ora12os7.local,DBSE,DBSE,WE8MSWIN1252,AL16UTF16,BINARY,AMERICAN,AMERICA
# ora12os7.local,orcl1120,orcl1120,WE8MSWIN1252,UTF8,BINARY,AMERICAN,AMERICA
# ---------
# db_name,db_unique_name,LOG_MODE,FORCE_LOGGING,SUPPLEMENTAL_LOG_DATA_PL,FLASHBACK_ON
# ora12os7.local,DBSE,DBSE,ARCHIVELOG,YES,NO,NO
# ora12os7.local,orcl1120,orcl1120,NOARCHIVELOG,NO,NO,NO
#------------------------------------------------------------------------

export ORAENV_ASK=NO 

# Consolidate SID discovery
# Exclude ASM and APX instances
ORACLE_SIDS=($(ps -ef | grep pmon | grep -Ev 'grep|\+ASM|\+APX' | awk '{print $8}' | cut -d_ -f3))

# SQL query for the first block of parameters
SQL_BLOCK1="
set pagesize 0 feedback off heading off verify off
select
    (select host_name from v\$instance) || ',' ||
    (select value from v\$parameter where name='db_name') || ',' ||
    (select value from v\$parameter where name='db_unique_name') || ',' ||
    (select value from v\$parameter where name='global_names') || ',' ||
    (select value from v\$parameter where name='db_domain') || ',' ||
    (select value from v\$parameter where name='compatible') || ',' ||
    (select value from v\$parameter where name='service_names') || ',' ||
    (select value from v\$parameter where name='memory_target') || ',' ||
    (select value from v\$parameter where name='sga_target') || ',' ||
    (select value from v\$parameter where name='pga_aggregate_target') || ',' ||
    (select value from v\$parameter where name='processes') || ',' ||
    (select value from v\$parameter where name='open_cursors')
from dual;
"

# SQL query for the second block of parameters
SQL_BLOCK2="
set pagesize 0 feedback off heading off verify off
select
    (select host_name from v\$instance) || ',' ||
    (select value from v\$parameter where name='db_name') || ',' ||
    (select value from v\$parameter where name='db_unique_name') || ',' ||
    (select value from nls_database_parameters where PARAMETER='NLS_CHARACTERSET') || ',' ||
    (select value from nls_database_parameters where PARAMETER='NLS_NCHAR_CHARACTERSET') || ',' ||
    (select value from nls_database_parameters where PARAMETER='NLS_SORT') || ',' ||
    (select value from nls_database_parameters where PARAMETER='NLS_LANGUAGE') || ',' ||
    (select value from nls_database_parameters where PARAMETER='NLS_TERRITORY')
from dual;
"

# SQL query for the third block of parameters
SQL_BLOCK3="
set pagesize 0 feedback off heading off verify off
select
    (select host_name from v\$instance) || ',' ||
    (select value from v\$parameter where name='db_name') || ',' ||
    (select value from v\$parameter where name='db_unique_name') || ',' ||
    LOG_MODE || ',' ||
    FORCE_LOGGING || ',' ||
    SUPPLEMENTAL_LOG_DATA_PL || ',' ||
    FLASHBACK_ON
from v\$database;
"

# Print headers
echo "db_name,db_unique_name,global_names,db_domain,compatible,service_names,memory_target,sga_target,pga_aggregate_target,processes,open_cursors"

# Loop through each discovered SID
for sid in "${ORACLE_SIDS[@]}"; do
    export ORACLE_SID="${sid}"
    . oraenv -s > /dev/null 2>&1 # Suppress oraenv output

    # Check if the database is actually up and accessible
    if sqlplus -s / as sysdba <<< "select 1 from dual;" >/dev/null 2>&1; then
        sqlplus -s / as sysdba <<< "$SQL_BLOCK1" | sed 's/^\s*//;s/\s*$//'
    else
        echo "ERROR: Could not connect to ${ORACLE_SID}. Skipping." >&2
    fi
done

echo "---------"
echo "db_name,db_unique_name,NLS_CHARACTERSET,NLS_NCHAR_CHARACTERSET,NLS_SORT,NLS_LANGUAGE,NLS_TERRITORY"

for sid in "${ORACLE_SIDS[@]}"; do
    export ORACLE_SID="${sid}"
    . oraenv -s > /dev/null 2>&1

    if sqlplus -s / as sysdba <<< "select 1 from dual;" >/dev/null 2>&1; then
        sqlplus -s / as sysdba <<< "$SQL_BLOCK2" | sed 's/^\s*//;s/\s*$//'
    fi
done

echo "---------"
echo "db_name,db_unique_name,LOG_MODE,FORCE_LOGGING,SUPPLEMENTAL_LOG_DATA_PL,FLASHBACK_ON"

for sid in "${ORACLE_SIDS[@]}"; do
    export ORACLE_SID="${sid}"
    . oraenv -s > /dev/null 2>&1

    if sqlplus -s / as sysdba <<< "select 1 from dual;" >/dev/null 2>&1; then
        sqlplus -s / as sysdba <<< "$SQL_BLOCK3" | sed 's/^\s*//;s/\s*$//'
    fi
done

