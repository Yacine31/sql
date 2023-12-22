#!/bin/sh
#------------------------------------------------------------------------------
# ORACLE DATABASE : EXPDP ALL DB RMAN
#------------------------------------------------------------------------------
# Historique :
#       21/04/2023 : YAO - Creation : export datapump de toutes les bases ouvertes
#------------------------------------------------------------------------------

# toutes les bases ouvertes sont sauvegardées par le script RMAN

for i in $(ps -ef | grep pmon | grep -v grep | cut -d_ -f3)
do
        sh /home/oracle/scripts/export_datapump.sh $i
done
