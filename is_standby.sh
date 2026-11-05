#!/bin/bash
#------------------------------------------------------------------------------
# Historique :
#------------------------------------------------------------------------------
#
# retourne true si la base est standby
# codes retour : 0 = base standby, 1 = autre rôle,
#                2 = paramètre absent ou base absente de /etc/oratab,
#                3 = rôle illisible (erreur SQL*Plus)
# 

#------------------------------------------------------------------------------
# fonction d'aide
#------------------------------------------------------------------------------
f_help() {

echo 
echo "syntax : $0 ORACLE_SID"
echo
exit $1 

} #f_help

#------------------------------------------------------------------------------

ORACLE_SID=$1

[ -n "${ORACLE_SID}" ] || f_help 2;

# positionner les variables d'environnement ORACLE
export ORACLE_SID

# vérifier si ORACLE_SID est dans /etc/oratab
if [ "$(grep -v '^$|^#' /etc/oratab | grep -c "^${ORACLE_SID}:")" -ne 1 ]; then
    echo "Base ${ORACLE_SID} absente du fichier /etc/oratab ... fin du script" >&2
    exit 2
fi

ORAENV_ASK=NO
PATH=/usr/local/bin:$PATH
. oraenv -s >/dev/null

# le marqueur <<'SQL' protège le $ de V$DATABASE
if ! dbrole=$(sqlplus -s -L '/ as sysdba' <<'SQL'
    whenever sqlerror exit failure
    whenever oserror exit failure
    set pages 0 feedback off;
    SELECT DATABASE_ROLE FROM V$DATABASE;
    exit
SQL
); then
    echo "Impossible de lire le rôle de la base ${ORACLE_SID} : ${dbrole}" >&2
    exit 3
fi

if [ "$dbrole" == "PHYSICAL STANDBY" ]
then
    exit 0   # base standby
else
    exit 1   # base autre
fi
