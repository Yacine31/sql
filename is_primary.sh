#
# retourne true si la base est primaire
# 

#------------------------------------------------------------------------------
# fonction d'aide
#------------------------------------------------------------------------------
f_help() {

        cat <<CATEOF
syntax : $O ORACLE_SID

CATEOF
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
