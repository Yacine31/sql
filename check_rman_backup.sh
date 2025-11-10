#!/bin/bash
#---------------------------------------------------------------------------
# Historique :
#       24/01/2019 : YOU - Premiere version pour liter les backup RMAN de 30j
#       10/11/2025 : Gemini - Améliorations : syntaxe, lisibilité et robustesse
#---------------------------------------------------------------------------
# Environnement Variables
export NLS_DATE_FORMAT='DD/MM/YYYY HH24:MI:SS'
export ORAENV_ASK=NO
unset NLS_LANG

#---------------------------------------------------------------------------
# Fonction test_dba : teste si l'utilisateur est DBA
#---------------------------------------------------------------------------
if ! id | grep -q dba; then
    echo ""
    echo "============================================================="
    echo " Abandon, l'utilisateur doit appartenir au groupe DBA        "
    echo "============================================================="
    exit 1
fi

#---------------------------------------------------------------------------
# reporter toutes les instances préntes sur ce serveur
#---------------------------------------------------------------------------

for r in $(ps -eaf | grep pmon | grep -Ev 'grep|ASM1|APX1' | cut -d '_' -f3)
do
echo "-----------------------------------------------------"
echo " Base de donnee a traiter: " $r
echo "-----------------------------------------------------"
export ORACLE_SID=$r

# vérifier si ORACLE_SID est dans /etc/oratab
if ! grep -q "^${ORACLE_SID}:" /etc/oratab; then
    echo "Base ${ORACLE_SID} absente du fichier /etc/oratab ... fin du script"
    exit 2
fi

. oraenv -s > /dev/null
sqlplus -S / as sysdba << EOF
set head off pages 0 feedback off linesize 250;
alter session set nls_date_format='DD/MM/YYYY HH24:MI:SS' ;
set heading on pagesize 999;
column status format a25;
column input_bytes_display format a12;
column output_bytes_display format a12;
column device_type format a10;
SET SERVEROUTPUT ON;
declare
        base varchar2(40) ;
        serv varchar2(40) ;
begin
        select instance_name  into base from v\$instance ;
        select host_name  into serv from v\$instance ;
        dbms_output.put_line (' Rapport pour la base de donnee :' || base || ' sur le serveur : '|| serv );
end ;
/
select
        b.input_type,
        b.status,
        to_char(b.start_time,'DD-MM-YYYY HH24:MI') "Start Time",
        to_char(b.end_time,'DD-MM-YYYY HH24:MI') "End Time",
        b.output_device_type device_type,
        b.input_bytes_display,
        b.output_bytes_display
FROM v\$rman_backup_job_details b
WHERE b.start_time > (SYSDATE - 30)
ORDER BY b.start_time asc;
EOF
done

