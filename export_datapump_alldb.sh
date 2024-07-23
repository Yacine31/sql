#!/bin/sh
#------------------------------------------------------------------------------
# ORACLE DATABASE : EXPDP ALL DB 
#------------------------------------------------------------------------------
# Historique :
#       21/04/2023 : YOU - Creation : export datapump de toutes les bases ouvertes
#------------------------------------------------------------------------------

# toutes les bases ouvertes sont sauvegardées par le expdp

for i in $(ps -ef | grep pmon | grep -v grep | cut -d_ -f3 | egrep -v '+ASM|+APX)
do
        sh /home/oracle/scripts/export_datapump.sh $i
done
