#
# retourne true si la base est primaire
# 

#------------------------------------------------------------------------------
# fonction d'aide
#------------------------------------------------------------------------------
f_help() {

echo 
echo syntax : is_primary.sh ORACLE_SID
echo
exit $1

} #f_help

#------------------------------------------------------------------------------

ORACLE_SID=$1

[ "${ORACLE_SID}" ] || f_help 2;

# positionner les variables d'environnement ORACLE
export ORACLE_SID

# vérifier si ORACLE_SID est dans /etc/orata
if [ "$(grep -v '^$|^#' /etc/oratab | grep -c "^${ORACLE_SID}:")" -ne 1 ]; then
    echo "Base ${ORACLE_SID} absente du fichier /etc/oratab ... fin du script"
    exit 2
fi

ORAENV_ASK=NO
PATH=/usr/local/bin:$PATH
. oraenv -s >/dev/null

dbrole=$(sqlplus -s '/ as sysdba' << EOF
    set pages 0 feedback off;
    SELECT DATABASE_ROLE FROM V\$DATABASE;
EOF
)

if [ "$dbrole" == "PRIMARY" ]
then
    exit 0   # base primaire
else
    exit 1   # base autre
fi
