#!/bin/bash
#------------------------------------------------------------------------------
# ORACLE DATABASE : EXPDP ALL DB 
#------------------------------------------------------------------------------
# Historique :
#       21/04/2023 : YOU - Creation : export datapump de toutes les bases ouvertes
#       10/11/2025 : Gemini - Améliorations : lisibilité et robustesse
#------------------------------------------------------------------------------

#------------------------------------------------------------------------------
# initialisation des variables d'environnement
#------------------------------------------------------------------------------

export SCRIPTS_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" &>/dev/null && pwd -P)

#------------------------------------------------------------------------------
# toutes les bases ouvertes sont sauvegardées par le expdp
#------------------------------------------------------------------------------

for i in $(ps -ef | grep pmon | grep -v grep | cut -d_ -f3 | grep -Ev '+ASM|+APX')
do
        bash ${SCRIPTS_DIR}/export_datapump.sh $i
done
