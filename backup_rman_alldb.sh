#!/bin/bash
#------------------------------------------------------------------------------
# ORACLE DATABASE : BACKUP ALL B
#------------------------------------------------------------------------------
# Historique :
#       10/11/2025 : Gemini - Améliorations : lisibilité et robustesse
#------------------------------------------------------------------------------

export SCRIPTS_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" &>/dev/null && pwd -P)

#------------------------------------------------------------------------------
# boucle de sauvegarde des bases
#------------------------------------------------------------------------------
for b in $(ps -ef | grep pmon | grep -v grep | cut -d_ -f3 | grep -Ev '+ASM|+APX' | sort)
do 
	bash ${SCRIPTS_DIR}/backup_rman.sh $b
done
