#!/bin/bash
#------------------------------------------------------------------------------
# Ce script effectue une sauvegarde des binaires d'une application Oracle.
# Il crée une archive tar compressée du répertoire de l'application,
# en excluant les sous-répertoires non essentiels (admin, audit, diag).
# Une notification est envoyée à la fin de l'opération (succès ou échec).
#------------------------------------------------------------------------------
# Historique :
#       25/09/2023 : YOU - premiere version pour sauvegarder les binaires
#------------------------------------------------------------------------------

#----------------------------------------
#------------ MAIN ----------------------
#----------------------------------------

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
# BKP_APP_LOCATION : répertoire de stockage des sauvegardes des binaires (ex: /backup/oracle_bin)
# ORA_APP_LOCATION : répertoire de base des binaires Oracle (ex: /u01/app/oracle)
# NTFY_URL : URL pour les notifications (service ntfy.sh)
#------------------------------------------------------------------------------

# S'assurer que toutes les variables utilisées sont définies
set -u
# Gérer les erreurs dans les pipelines
set -o pipefail


# creation du repertoire de sauvegarde. S'il existe la commande install ne fait rien
mkdir -p ${BKP_APP_LOCATION}

#------------------------------------------------------------------------------
# sauvegarde
#------------------------------------------------------------------------------

cd ${BKP_APP_LOCATION}
# suppression des anciennes sauvegardes (note: cette commande supprime TOUTES les anciennes sauvegardes)
rm -fv backup_bin_oraapp_*.tgz
# compression du repertoire oracle app avec exclusion des répertoires admin, diag et audit
if sudo tar cfz "${BKP_APP_LOCATION}/backup_bin_oraapp_$(date +%Y%m%d).tgz" \
--exclude="${ORA_APP_LOCATION}/oracle/admin" \
--exclude="${ORA_APP_LOCATION}/oracle/audit" \
--exclude="${ORA_APP_LOCATION}/oracle/diag" \
"${ORA_APP_LOCATION}"; then
    # notification de succès
    curl -d "$(hostname) - backup des binaires terminée" "${NTFY_URL}"
else
    # notification d'échec
    curl -d "$(hostname) - ERREUR: backup des binaires a échoué" "${NTFY_URL}"
    exit 1 # Quitter avec un code d'erreur
fi

