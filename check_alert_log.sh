#!/bin/bash
#---------------------------------------------------------------------------
# 03/05/2023 - YOU : Premiere version pour lister les erreurs depuis l'alert
# log sur les 30 derniers jours
#---------------------------------------------------------------------------
# Environnement Variables
export NLS_DATE_FORMAT='DD/MM/YYYY HH24:MI:SS'
export ORAENV_ASK=NO
unset NLS_LANG

#---------------------------------------------------------------------------
# Fonction test_dba : teste si l'utilisateur est DBA
#---------------------------------------------------------------------------
if test "$(id|grep dba)"
  then
    echo > /dev/null 
  else
    echo ""
    echo "============================================================="
    echo " Abandon, l'utilisateur doit appartenir au groupe DBA        "
    echo "============================================================="
    exit 1
fi

#---------------------------------------------------------------------------
# reporter toutes les instances préntes sur ce serveur
#---------------------------------------------------------------------------

for r in $(ps -eaf | grep pmon | egrep -v 'grep|ASM1|APX1' | cut -d '_' -f3)
do
echo "-----------------------------------------------------"
echo " Base de donnee a traiter: " $r
echo "-----------------------------------------------------"
export ORACLE_SID=$r
. oraenv -s > /dev/null
sqlplus -S / as sysdba << EOF
set head off pages 0 feedback off 
set linesize 250 heading off;
alter session set nls_date_format='DD/MM/YYYY HH24:MI:SS' ;
set heading on pagesize 999;
column status format a25;
column input_bytes_display format a12;
column output_bytes_display format a12;
column device_type format a10;
declare
        base varchar2(40) ;
        serv varchar2(40) ;
begin
        select instance_name  into base from v\$instance ;
        select host_name  into serv from v\$instance ;
        dbms_output.put_line (' Rapport pour la base de donnee :' || base || ' sur le serveur : '|| serv );
end ;
/
set pages 999 lines 200
col ORIGINATING_TIMESTAMP for a35
col MESSAGE_TEXT for a120

select to_char(ORIGINATING_TIMESTAMP,'YYYY-MM-DD HH24:MI:SS'), MESSAGE_TEXT 
  from V\$DIAG_ALERT_EXT 
  where MESSAGE_TEXT like 'ORA-%' AND originating_timestamp >= SYSDATE - 30 
  order by ORIGINATING_TIMESTAMP;
EOF
done

