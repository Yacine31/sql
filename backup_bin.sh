#!/bin/sh
#------------------------------------------------------------------------------
# Historique :
#       25/09/2023 : YOU - premiere version pour sauvegarder les binaires
#------------------------------------------------------------------------------

#----------------------------------------
#------------ MAIN ----------------------
#----------------------------------------

#------------------------------------------------------------------------------
# inititalisation des variables d'environnement
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


# creation du repertoire de sauvegarde. S'il existe la commande install ne fait rien
install -d ${BKP_APP_LOCATION}

#------------------------------------------------------------------------------
# sauvegarde
#------------------------------------------------------------------------------

cd ${BKP_APP_LOCATION}
# suppression des anciennes sauvegardes
rm -fv backup_bin_oraapp_*.tgz
# compression du repertoire oracle app avec exclusion des répertoires admin, diag et audit
sudo tar cfz ${BKP_APP_LOCATION}/backup_bin_oraapp_$(date +%Y%m%d).tgz \
--exclude="${ORA_APP_LOCATION}/oracle/admin" \
--exclude="${ORA_APP_LOCATION}/oracle/audit" \
--exclude="${ORA_APP_LOCATION}/oracle/diag" \
${ORA_APP_LOCATION}

# notification
curl -d "$(hostname) - backup des binaires terminée" ${NTFY_URL}

