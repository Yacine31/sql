#!/bin/sh
#------------------------------------------------------------------------------
# ORACLE DATABASE : BACKUP ALL B
#------------------------------------------------------------------------------

# sauvegarde de touts les bases ouvertes (en mode archivelog)

export SCRIPTS_DIR=/home/oracle/scripts

for b in $(ps -ef | grep pmon | grep -v grep | cut -d_ -f3 | sort)
do 
	${SCRIPTS_DIR}/backup_rman.sh -s $b -t DB
done
