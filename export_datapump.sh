#!/bin/bash
#------------------------------------------------------------------------------
# Historique :
#       14/09/2011 : YOU - Creation
#       14/10/2015 : YOU - script générique pour toutes les bases
#       15/12/2022 : YOU - retention de 1 jour
#       25/09/2023 : YOU - simplification du passage des paramètres
#       10/11/2025 : Gemini - Améliorations : lisibilité, robustesse et bonnes pratiques
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

#----------------------------------------
#------------ MAIN ----------------------
#----------------------------------------

ORACLE_SID=

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
#------------------------------------------------------------------------------
NLS_CHARACTERSET=$($ORACLE_HOME/bin/sqlplus -S / as sysdba <<EOF
set heading off
set feedback off
set echo off
select VALUE from nls_database_parameters where PARAMETER='NLS_CHARACTERSET';
EOF
)
NLS_CHARACTERSET=$(echo $NLS_CHARACTERSET | sed 's/^\s*//g')

# on complète la variable NLS_LANG qui vient du fichier .env avec la variable NLS_CHARACTERSET
export NLS_LANG="${NLS_LANG}.${NLS_CHARACTERSET}"

# creation du repertoire de sauvegarde. S'il existe la commande ne fait rien
mkdir -p ${EXP_LOCATION}

#------------------------------------------------------------------------------
# creation du répertoire DPDIR au niveau de la base
#------------------------------------------------------------------------------
$ORACLE_HOME/bin/sqlplus -S / as sysdba <<EOF
set heading off
set feedback off
set echo off
create or replace directory $DPDIR as '${EXP_LOCATION}';
grant read, write on directory $DPDIR to public;
exit
EOF

#------------------------------------------------------------------------------
# export des données
#------------------------------------------------------------------------------
# suppression des anciens fichier tar, dump et log du répertoire
rm -f ${EXP_LOCATION}/export_${ORACLE_SID}.{log,dmp,tgz}

# export datapump
$ORACLE_HOME/bin/expdp \'/ as sysdba\' full=y directory=$DPDIR dumpfile=export_${ORACLE_SID}.dmp logfile=export_${ORACLE_SID}.log flashback_time=systimestamp reuse_dumpfiles=yes

# compression du dump et son log dans un seul fichier et suppression des fichiers d'origine
cd ${EXP_LOCATION}
tar cfz export_${ORACLE_SID}.tgz export_${ORACLE_SID}.{dmp,log} && rm -f export_${ORACLE_SID}.dmp

#------------------------------------------------------------------------------
# Notification en cas d'erreur dans le fichier de sauvegarde
#------------------------------------------------------------------------------
EXPDP_LOG_FILE=${EXP_LOCATION}/export_${ORACLE_SID}.log
ERR_COUNT=$(grep -E "^EXP-[0-9]*|^ORA-[0-9]:" ${EXPDP_LOG_FILE} | wc -l)
MSG=$(grep -E "^EXP-[0-9]*|^ORA-[0-9]:" ${EXPDP_LOG_FILE})

if [ ${ERR_COUNT} -ne 0 ]; then
        curl -H "t: Erreur expdp base ${ORACLE_SID} sur le serveur $(hostname)" -d "$MSG" -L ${NTFY_URL}
fi