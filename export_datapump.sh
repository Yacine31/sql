#!/bin/bash
#------------------------------------------------------------------------------
# Historique :
#       14/09/2011 : YOU - Creation
#       14/10/2015 : YOU - script générique pour toutes les bases
#       15/12/2022 : YOU - retention de 1 jour
#       25/09/2023 : YOU - simplification du passage des paramètres
#       05/11/2026 : YOU - gestion des erreurs, ancien export conservé jusqu'au nouveau
#------------------------------------------------------------------------------

# Ajout de set -o pipefail pour la gestion des erreurs dans les pipes
set -o pipefail

#------------------------------------------------------------------------------
# fonction d'aide
#------------------------------------------------------------------------------
f_help() {

echo "

syntaxe : $0 ORACLE_SID
------
"
exit 

} #f_help

#------------------------------------------------------------------------------
# fonction d'erreur : affiche le message, envoie la notification et quitte
#------------------------------------------------------------------------------
f_erreur() {
        echo "$1" >&2
        curl -H "t: Erreur expdp base ${ORACLE_SID} sur le serveur $(hostname)" -d "$1" -L ${NTFY_URL}
        exit 1
} #f_erreur

#----------------------------------------
#------------ MAIN ----------------------
#----------------------------------------

ORACLE_SID=$1

[ "${ORACLE_SID}" ] || f_help 2;

#------------------------------------------------------------------------------
# initialisation des variables d'environnement
#------------------------------------------------------------------------------
export SCRIPTS_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" &>/dev/null && pwd -P)

# Nom du fichier .env
ENV_FILE=${SCRIPTS_DIR}"/.env"

# Vérifier si le fichier .env existe
if [ ! -f "$ENV_FILE" ]; then
    echo "Erreur : Le fichier $ENV_FILE n'existe pas."
    echo "Erreur : Impossible de charger les variables d'environnement."
    exit 1
fi

# Charger les variables d'environnement depuis le fichier .env
source "$ENV_FILE"

#------------------------------------------------------------------------------
# Variables attendues dans le fichier .env :
#------------------------------------------------------------------------------
# ORACLE_OWNER : propritaire des binaires oracle (ex: oracle)
# EXP_LOCATION : répertoire de stockage des exports (ex: /u01/export)
# DPDIR : nom de l'objet DIRECTORY oracle (ex: DATA_PUMP_DIR)
# NTFY_URL : URL pour les notifications d'erreur (service ntfy.sh)
# NLS_LANG : partie base de la variable NLS_LANG (ex: FRENCH_FRANCE)
#------------------------------------------------------------------------------

#------------------------------------------------------------------------------
# si ce n'est pas le user oracle qui lance le script, on quitte
#------------------------------------------------------------------------------
if [[ "$(whoami)" != "$ORACLE_OWNER" ]]; then
  echo "Vous devez etre $ORACLE_OWNER pour lancer ce script"
  exit 1
fi

#------------------------------------------------------------------------------
# positionner les variables d'environnement ORACLE
# et vérifier si ORACLE_SID est dans /etc/oratab
#------------------------------------------------------------------------------

# vérifier si ORACLE_SID est présente dans le fichier /etc/oratab
if [ "$(grep -v '^$|^#' /etc/oratab | grep -c "^${ORACLE_SID}:")" -ne 1 ]; then
        echo "Base ${ORACLE_SID} absente du fichier /etc/oratab ... fin du script"
        exit 2
fi

export ORACLE_SID
ORAENV_ASK=NO
PATH=/usr/local/bin:$PATH
. oraenv -s >/dev/null

# si la base est standby on sort
${SCRIPTS_DIR}/is_standby.sh ${ORACLE_SID} && exit 2

#------------------------------------------------------------------------------
# recuperation du NLS_CHARACTERSET
# cette requête vérifie aussi que la base répond, avant de toucher aux fichiers
#------------------------------------------------------------------------------
if ! NLS_CHARACTERSET=$($ORACLE_HOME/bin/sqlplus -S -L / as sysdba <<'SQL'
        whenever sqlerror exit failure
        whenever oserror exit failure
        set heading off
        set feedback off
        set echo off
        select VALUE from nls_database_parameters where PARAMETER='NLS_CHARACTERSET';
        exit
SQL
); then
        f_erreur "Échec de la lecture du NLS_CHARACTERSET : ${NLS_CHARACTERSET}"
fi
NLS_CHARACTERSET=$(echo $NLS_CHARACTERSET | sed 's/^\s*//g')

# on complète la variable NLS_LANG qui vient du fichier .env avec la variable NLS_CHARACTERSET
export NLS_LANG="${NLS_LANG}.${NLS_CHARACTERSET}"

# creation du repertoire de sauvegarde. S'il existe la commande ne fait rien
mkdir -p ${EXP_LOCATION} || f_erreur "Impossible de créer le répertoire ${EXP_LOCATION}"

#------------------------------------------------------------------------------
# creation du répertoire DPDIR au niveau de la base
# marqueur <<SQL sans apostrophes : le bloc utilise les variables du shell
#------------------------------------------------------------------------------
if ! SQL_OUTPUT=$($ORACLE_HOME/bin/sqlplus -S -L / as sysdba <<SQL
        whenever sqlerror exit failure
        whenever oserror exit failure
        set heading off
        set feedback off
        set echo off
        create or replace directory $DPDIR as '${EXP_LOCATION}';
        grant read, write on directory $DPDIR to public;
        exit
SQL
); then
        f_erreur "Échec de la création du directory ${DPDIR} : ${SQL_OUTPUT}"
fi

#------------------------------------------------------------------------------
# export des données
#------------------------------------------------------------------------------
# suppression des anciens fichier dump et log du répertoire
# l'ancien tgz est conservé tant que le nouveau n'est pas complet
rm -f ${EXP_LOCATION}/export_${ORACLE_SID}.{log,dmp,tgz.tmp}

# export datapump
$ORACLE_HOME/bin/expdp \'/ as sysdba\' full=y directory=$DPDIR dumpfile=export_${ORACLE_SID}.dmp logfile=export_${ORACLE_SID}.log flashback_time=systimestamp reuse_dumpfiles=yes
EXPDP_RC=$?

# code retour expdp : 0 = succès, 5 = terminé avec des erreurs ou avertissements, autre = échec
if [ ${EXPDP_RC} -ne 0 ] && [ ${EXPDP_RC} -ne 5 ]; then
        f_erreur "Échec de expdp (code retour ${EXPDP_RC}), ancien export conservé. $(grep -E "^EXP-[0-9]+:|^ORA-[0-9]+:" ${EXP_LOCATION}/export_${ORACLE_SID}.log 2>/dev/null)"
fi

# compression du dump et son log dans un seul fichier et suppression des fichiers d'origine
# le tgz est créé sous un nom temporaire puis renommé : l'ancien reste valide si tar échoue
cd ${EXP_LOCATION} || f_erreur "Impossible d'accéder au répertoire ${EXP_LOCATION}"
if ! tar cfz export_${ORACLE_SID}.tgz.tmp export_${ORACLE_SID}.{dmp,log}; then
        rm -f export_${ORACLE_SID}.tgz.tmp
        f_erreur "Échec de la compression, ancien export conservé, dump disponible dans ${EXP_LOCATION}"
fi
mv -f export_${ORACLE_SID}.tgz.tmp export_${ORACLE_SID}.tgz || f_erreur "Échec du renommage de export_${ORACLE_SID}.tgz.tmp"
rm -f export_${ORACLE_SID}.dmp

#------------------------------------------------------------------------------
# Notification en cas d'erreur dans le fichier de sauvegarde
#------------------------------------------------------------------------------
EXPDP_LOG_FILE=${EXP_LOCATION}/export_${ORACLE_SID}.log
ERR_COUNT=$(grep -E "^EXP-[0-9]+:|^ORA-[0-9]+:" ${EXPDP_LOG_FILE} | wc -l)
MSG=$(grep -E "^EXP-[0-9]+:|^ORA-[0-9]+:" ${EXPDP_LOG_FILE})

if [ ${ERR_COUNT} -ne 0 ]; then
        curl -H "t: Erreur expdp base ${ORACLE_SID} sur le serveur $(hostname)" -d "$MSG" -L ${NTFY_URL}
fi

exit ${EXPDP_RC}
