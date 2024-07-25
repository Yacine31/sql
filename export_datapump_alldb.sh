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

export SCRIPTS_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" &>/dev/null && pwd -P)

#------------------------------------------------------------------------------
# toutes les bases ouvertes sont sauvegardées par le expdp
#------------------------------------------------------------------------------

for i in $(ps -ef | grep pmon | grep -v grep | cut -d_ -f3 | egrep -v '+ASM|+APX')
do
        sh ${SCRIPTS_DIR}/export_datapump.sh $i
done
