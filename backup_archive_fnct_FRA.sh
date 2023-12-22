#
# retourne le porucentage d'occupation de la FRA
# 

#------------------------------------------------------------------------------
# fonction d'aide
#------------------------------------------------------------------------------
f_help() {

echo 
echo syntax : $0 ORACLE_SID
echo
exit $1

} #f_help

#------------------------------------------------------------------------------
ORACLE_SID=$1

[ "${ORACLE_SID}" ] || f_help 2;

# positionner les variables d'environnement ORACLE
export ORACLE_SID
ORAENV_ASK=NO
PATH=/usr/local/bin:$PATH
. oraenv -s >/dev/null

fra_usage=$(sqlplus -s '/ as sysdba' << EOF
    set pages 0 feedback off;
    select round(sum(percent_space_used),0) from v\$flash_recovery_area_usage;
EOF
) 

pct_fra_used=$(echo ${fra_usage} | egrep -o "[0-9]*")

if [ ${pct_fra_used} gt 65 ]
then
    echo ${pct_fra_used} : backup des archivelog necessaire
else
    echo ${pct_fra_used} : backup des archivelog NON necessaire
fi


