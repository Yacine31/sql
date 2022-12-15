#!/bin/sh

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

f_sql_param() {
    param=$(sqlplus -s '/ as sysdba' << EOF
    set pages 0 feedback off;
    select value from v\$parameter where name='$1';
EOF
)
    echo "$param"
} #f_sql_param


f_nls_param() {
    param=$(sqlplus -s '/ as sysdba' << EOF
    set pages 0 feedback off;
    select value from nls_database_parameters where PARAMETER='$1';
EOF
)
    echo "$param"
} #f_nls_param

f_db_param() {
    param=$(sqlplus -s '/ as sysdba' << EOF
    set pages 0 feedback off;
    select $1 from v\$database;
EOF
)
    echo "$param"
} #f_db_param

f_ins_host_name() {
    param=$(sqlplus -s '/ as sysdba' << EOF
    set pages 0 feedback off;
    select host_name from v\$instance;
EOF
)
    echo "$param"
}

export ORAENV_ASK=NO 


echo db_name,db_unique_name,global_names,db_domain,compatible,service_names,memory_target,sga_target,pga_aggregate_target,processes,open_cursors
ps -ef | grep pmon | grep -v grep | awk '{print $8}' | cut -d_ -f3 | while read sid
do
    export ORACLE_SID=${sid}
    . oraenv -s

    echo $(f_ins_host_name),$(f_sql_param "db_name"),$(f_sql_param "db_unique_name"),$(f_sql_param "global_names"),$(f_sql_param "db_domain"),$(f_sql_param "compatible"),$(f_sql_param "service_names"),$(f_sql_param "memory_target"),$(f_sql_param "sga_target"),$(f_sql_param "pga_aggregate_target"),$(f_sql_param "processes"),$(f_sql_param "open_cursors")
done

echo "---------"
echo db_name,db_unique_name,NLS_CHARACTERSET,NLS_NCHAR_CHARACTERSET,NLS_SORT,NLS_LANGUAGE,NLS_TERRITORY
ps -ef | grep pmon | grep -v grep | awk '{print $8}' | cut -d_ -f3 | while read sid
do
    export ORACLE_SID=${sid}
    . oraenv -s

    echo $(f_ins_host_name),$(f_sql_param "db_name"),$(f_sql_param "db_unique_name"),$(f_nls_param "NLS_CHARACTERSET"),$(f_nls_param "NLS_NCHAR_CHARACTERSET"),$(f_nls_param "NLS_SORT"),$(f_nls_param "NLS_LANGUAGE"),$(f_nls_param "NLS_TERRITORY")
done

echo "---------"
echo db_name,db_unique_name,LOG_MODE,FORCE_LOGGING,SUPPLEMENTAL_LOG_DATA_PL,FLASHBACK_ON
ps -ef | grep pmon | grep -v grep | awk '{print $8}' | cut -d_ -f3 | while read sid
do
    export ORACLE_SID=${sid}
    . oraenv -s

    echo $(f_ins_host_name),$(f_sql_param "db_name"),$(f_sql_param "db_unique_name"),$(f_db_param "LOG_MODE"),$(f_db_param "FORCE_LOGGING"),$(f_db_param "SUPPLEMENTAL_LOG_DATA_PL"),$(f_db_param "FLASHBACK_ON")
done

