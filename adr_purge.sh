#!/bin/bash
#------------------------------------------------------------------------------
# Historique :
#       10/11/2025 : Gemini - Améliorations : lisibilité et robustesse
#------------------------------------------------------------------------------
#
# Purge ADR contents (adr_purge.sh)
# 00 05 * * 0 adr_purge.sh
# Add the above line with `crontab -e` to the oracle user's cron

# --- Configuration de la rétention en JOURS ---
ALERT_RET_DAYS=90
INCIDENT_RET_DAYS=30
TRACE_RET_DAYS=30
CDUMP_RET_DAYS=30
HM_RET_DAYS=30

# --- Calcul de la rétention en MINUTES pour adrci ---
ALERT_RET_MINUTES=$((ALERT_RET_DAYS * 24 * 60))
INCIDENT_RET_MINUTES=$((INCIDENT_RET_DAYS * 24 * 60))
TRACE_RET_MINUTES=$((TRACE_RET_DAYS * 24 * 60))
CDUMP_RET_MINUTES=$((CDUMP_RET_DAYS * 24 * 60))
HM_RET_MINUTES=$((HM_RET_DAYS * 24 * 60))

echo "INFO: adrci purge started at $(date)"
adrci exec="show homes"|grep -v 'ADR Homes' | while read file_line
do
    echo "INFO: adrci purging diagnostic destination \"$file_line\""
    echo "INFO: purging ALERT older than $ALERT_RET_DAYS days"
    adrci exec="set homepath '$file_line';purge -age $ALERT_RET_MINUTES -type ALERT"
    echo "INFO: purging INCIDENT older than $INCIDENT_RET_DAYS days"
    adrci exec="set homepath '$file_line';purge -age $INCIDENT_RET_MINUTES -type INCIDENT"
    echo "INFO: purging TRACE older than $TRACE_RET_DAYS days"
    adrci exec="set homepath '$file_line';purge -age $TRACE_RET_MINUTES -type TRACE"
    echo "INFO: purging CDUMP older than $CDUMP_RET_DAYS days"
    adrci exec="set homepath '$file_line';purge -age $CDUMP_RET_MINUTES -type CDUMP"
    echo "INFO: purging HM older than $HM_RET_DAYS days"
    adrci exec="set homepath '$file_line';purge -age $HM_RET_MINUTES -type HM"
    echo ""
    echo ""
done
echo
echo "INFO: adrci purge finished at $(date)"

