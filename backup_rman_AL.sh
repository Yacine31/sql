#!/bin/sh
#------------------------------------------------------------------------------
# ORACLE DATABASE : BACKUP RMAN AL
#------------------------------------------------------------------------------
# Historique :
#       22/12/2023 : YOU - backup des AL seulement
#------------------------------------------------------------------------------

#------------------------------------------------------------------------------
# fonction init : c'est ici qu'il faut modifier toutes les variables liées
# à l'environnement
#------------------------------------------------------------------------------
f_init() {

        export ORACLE_OWNER=oracle

        # les différents répertoires
        export SCRIPTS_DIR=/home/oracle/scripts
        export BKP_LOG_DIR=$SCRIPTS_DIR/logs
        export BKP_LOCATION=/u04/backup/${ORACLE_SID}/rman

        # nombre de sauvegarde RMAN en ligne à garder
        export BKP_REDUNDANCY=1
        export DATE_JOUR=$(date +%Y.%m.%d-%H.%M)
        export BKP_LOG_FILE=${BKP_LOG_DIR}/backup_rman_AL_${ORACLE_SID}_${DATE_JOUR}.log
        export RMAN_CMD_FILE=${BKP_LOG_DIR}/rman_cmd_file_${ORACLE_SID}.rman

        # nombre de jours de conservation des logs de la sauvegarde
        export BKP_LOG_RETENTION=15

        # nombre de canaux à utiliser
        export PARALLELISM=1

} # f_init

#------------------------------------------------------------------------------
# fonction d'aide
#------------------------------------------------------------------------------
f_help() {

        cat <<CATEOF
syntax : $O ORACLE_SID

CATEOF
exit $1

} #f_help

#------------------------------------------------------------------------------
# fonction d'affichage de la date ds les logs
#------------------------------------------------------------------------------
f_print()
{
        echo "[`date +"%Y/%m/%d %H:%M:%S"`] : $1" >> $BKP_LOG_FILE
} #f_print


#------------------------------------------------------------------------------
# traitement de la ligne de commande
#------------------------------------------------------------------------------

ORACLE_SID=$1

[ "${ORACLE_SID}" ] || f_help 2;

# positionner les variables d'environnement ORACLE
export ORACLE_SID
ORAENV_ASK=NO
PATH=/usr/local/bin:$PATH
. oraenv -s >/dev/null

#------------------------------------------------------------------------------
# inititalisation des variables d'environnement
#------------------------------------------------------------------------------
f_init

# si la base est standby on sort
${SCRIPTS_DIR}/is_standby.sh ${ORACLE_SID} && exit 2

#------------------------------------------------------------------------------
# si ce n'est pas le user oracle qui lance le script, on quitte
#------------------------------------------------------------------------------
if (test `whoami` != $ORACLE_OWNER)
then
        echo
        echo "-----------------------------------------------------"
        echo "Vous devez etre $ORACLE_OWNER pour lancer ce script"
        echo "-----------------------------------------------------"
        exit 2
fi

#------------------------------------------------------------------------------
# initialisation des chemins, s'ils n'existent pas ils seront créés par la commande install
#------------------------------------------------------------------------------
install -d ${BKP_LOCATION}
install -d ${BKP_LOG_DIR}

#------------------------------------------------------------------------------
# génération du script de la sauvegarde RMAN
#------------------------------------------------------------------------------

#
# si une autre sauvegarde est en cours, on quitte
#
RUNNING_RMAN=$($ORACLE_HOME/bin/sqlplus -S / as sysdba <<EOF
set heading off
set feedback off
set echo off
select count(*) from v\$rman_backup_job_details where STATUS IN ('RUNNING', 'EXECUTING');
EOF
)
RUNNING_RMAN=$(echo ${RUNNING_RMAN} | sed 's/^\s*//g')

if [ ${RUNNING_RMAN} -eq 0 ]; then
    # RUNNING_RMAN n'est pas vide, donc backup RMAN en cours ... on quitte
    f_print("Sauvegarde RMAN en cours ... fin du script")
    exit 2
fi

# récupération du mode archive ou pas 
LOG_MODE=$($ORACLE_HOME/bin/sqlplus -S / as sysdba <<EOF
set heading off
set feedback off
set echo off
select LOG_MODE from V\$DATABASE;
EOF
)
LOG_MODE=$(echo $LOG_MODE | sed 's/^\s*//g')

if [ "$LOG_MODE" == "NOARCHIVELOG" ]; then
        echo "validate check logical database;" > ${RMAN_CMD_FILE}
else
        # run {
        echo "
        CONFIGURE DEVICE TYPE DISK PARALLELISM $PARALLELISM ;
        CONFIGURE RETENTION POLICY TO REDUNDANCY ${BKP_REDUNDANCY};
        SQL 'ALTER SYSTEM ARCHIVE LOG CURRENT';
        BACKUP DEVICE TYPE DISK FORMAT '${BKP_LOCATION}/arch_%T_%t_%s_%p' TAG 'ARCH_${DATE_JOUR}' AS COMPRESSED BACKUPSET ARCHIVELOG ALL DELETE ALL INPUT;
        CROSSCHECK ARCHIVELOG ALL;
        DELETE NOPROMPT OBSOLETE;
        DELETE NOPROMPT EXPIRED ARCHIVELOG ALL;
        BACKUP CURRENT CONTROLFILE FORMAT '${BKP_LOCATION}/control_%T_%t_%s_%p' TAG 'CTLFILE_${DATE_JOUR}';
        " > ${RMAN_CMD_FILE}
        # }
fi
#------------------------------------------------------------------------------
# Execution du script RMAN
#------------------------------------------------------------------------------
f_print "------------------------- DEBUT DE LA BACKUP -------------------------"
${ORACLE_HOME}/bin/rman target / cmdfile=${RMAN_CMD_FILE} log=${BKP_LOG_FILE}

#------------------------------------------------------------------------------
# Mail si des erreurs dans le fichier de sauvegarde
#------------------------------------------------------------------------------
# ERR_COUNT=$(egrep "^RMAN-[0-9]*|^ORA-[0-9]:" ${BKP_LOG_FILE} | wc -l)
ERR_COUNT=$(egrep "^ORA-[0-9]:" ${BKP_LOG_FILE} | wc -l)

if [ ${ERR_COUNT} -ne 0 ]; then
        curl -H "t: Erreur RMAN base ${ORACLE_SID} sur le serveur $(hostname)" -d "$(cat ${BKP_LOG_FILE})" -L https://ntfy.axiome.io/backup-rman
fi

#------------------------------------------------------------------------------
# Nettoyage auto des logs : durée de concervation déterminée par la variable : ${BKP_LOG_RETENTION}
#------------------------------------------------------------------------------

f_print "------------------------- NETTOYAGE DES LOGS -------------------------"
find ${BKP_LOG_DIR} -type f -iname "backup_rman_${BKP_TYPE}*.log" -mtime +${BKP_LOG_RETENTION} -exec rm -fv "{}" \; >> $BKP_LOG_FILE
f_print "------------------------- BACKUP ${BKP_TYPE} TERMINE -------------------------"
