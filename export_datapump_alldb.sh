#!/bin/sh
#------------------------------------------------------------------------------
# ORACLE DATABASE : EXPDP ALL DB 
#------------------------------------------------------------------------------
# Historique :
#       21/04/2023 : YOU - Creation : export datapump de toutes les bases ouvertes
#------------------------------------------------------------------------------

#------------------------------------------------------------------------------
# inititalisation des variables d'environnement
#------------------------------------------------------------------------------

# Nom du fichier .env
ENV_FILE=".env"

# Vérifier si le fichier .env existe
if [ ! -f "$ENV_FILE" ]; then
    echo "Erreur : Le fichier $ENV_FILE n'existe pas."
    echo "Erreur : Impossible de charger les variables d'environnement."
    exit 1
fi

# Charger les variables d'environnement depuis le fichier .env
source "$ENV_FILE"

#------------------------------------------------------------------------------
# toutes les bases ouvertes sont sauvegardées par le expdp
#------------------------------------------------------------------------------

for i in $(ps -ef | grep pmon | grep -v grep | cut -d_ -f3 | egrep -v '+ASM|+APX')
do
        sh ${SCRIPTS_DIR}/export_datapump.sh $i
done
