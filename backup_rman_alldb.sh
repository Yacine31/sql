#!/bin/sh
#------------------------------------------------------------------------------
# ORACLE DATABASE : BACKUP ALL B
# sauvegarde de touts les bases ouvertes (en mode archivelog)
#------------------------------------------------------------------------------

export SCRIPTS_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" &>/dev/null && pwd -P)

#------------------------------------------------------------------------------
# boucle de sauvegarde des bases
#------------------------------------------------------------------------------
for b in $(ps -ef | grep pmon | grep -v grep | cut -d_ -f3 | sort)
do 
	${SCRIPTS_DIR}/backup_rman.sh $b
done
