#!/bin/sh
#------------------------------------------------------------------------------
# ORACLE DATABASE : BACKUP RMAN DB + AL
#------------------------------------------------------------------------------
# Historique :
#       14/09/2011 : YOU - Creation
#       12/10/2015 : YOU - adaptation à l'ensemble des bases
#       13/10/2015 : YOU - ajout des params en ligne de commande
#       03/05/2016 : YOU - adaptation a l'environnement SOM
#       04/05/2016 : YOU - ajout du niveau de sauvegarde : incrementale 0 ou 1
#       09/11/2022 : YOU - backup simple => db full
#       10/08/2023 : YOU - base noarchivelog : execution de rman validate
#       25/09/2023 : YOU - simplification, 1 seul parametre pour le script 
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
        export BKP_LOG_FILE=${BKP_LOG_DIR}/backup_rman_${ORACLE_SID}_${DATE_JOUR}.log
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
        echo "
        run {
        CONFIGURE DEVICE TYPE DISK PARALLELISM $PARALLELISM ;
        CONFIGURE RETENTION POLICY TO REDUNDANCY ${BKP_REDUNDANCY};
        BACKUP DEVICE TYPE DISK FORMAT '${BKP_LOCATION}/data_%T_%t_%s_%p' TAG 'DATA_${DATE_JOUR}' AS COMPRESSED BACKUPSET DATABASE;
        SQL 'ALTER SYSTEM ARCHIVE LOG CURRENT';
        BACKUP DEVICE TYPE DISK FORMAT '${BKP_LOCATION}/arch_%T_%t_%s_%p' TAG 'ARCH_${DATE_JOUR}' AS COMPRESSED BACKUPSET ARCHIVELOG ALL DELETE ALL INPUT;
        DELETE NOPROMPT OBSOLETE;
        DELETE NOPROMPT EXPIRED BACKUPSET;
        BACKUP CURRENT CONTROLFILE FORMAT '${BKP_LOCATION}/control_%T_%t_%s_%p' TAG 'CTLFILE_${DATE_JOUR}';
        SQL \"ALTER DATABASE BACKUP CONTROLFILE TO TRACE AS ''${BKP_LOCATION}/${ORACLE_SID}_control_file.trc'' REUSE\";
        SQL \"CREATE PFILE=''${BKP_LOCATION}/pfile_${ORACLE_SID}.ora'' FROM SPFILE\";
        }
        " > ${RMAN_CMD_FILE}
fi
#------------------------------------------------------------------------------
# Execution du script RMAN
#------------------------------------------------------------------------------
f_print "------------------------- DEBUT DE LA BACKUP -------------------------"
${ORACLE_HOME}/bin/rman target / cmdfile=${RMAN_CMD_FILE} log=${BKP_LOG_FILE}

#------------------------------------------------------------------------------
# Mail si des erreurs dans le fichier de sauvegarde
#------------------------------------------------------------------------------
ERR_COUNT=$(egrep "^RMAN-[0-9]*|^ORA-[0-9]:" ${BKP_LOG_FILE} | wc -l)

if [ ${ERR_COUNT} -ne 0 ]; then
        curl -H "t: Erreur RMAN base ${ORACLE_SID} sur le serveur $(hostname)" -d "$(cat ${BKP_LOG_FILE})" -L https://ntfy.axiome.io/backup-rman
fi

#------------------------------------------------------------------------------
# Nettoyage auto des logs : durée de concervation déterminée par la variable : ${BKP_LOG_RETENTION}
#------------------------------------------------------------------------------

f_print "------------------------- NETTOYAGE DES LOGS -------------------------"
find ${BKP_LOG_DIR} -type f -iname "backup_rman_${BKP_TYPE}*.log" -mtime +${BKP_LOG_RETENTION} -exec rm -fv "{}" \; >> $BKP_LOG_FILE
f_print "------------------------- BACKUP ${BKP_TYPE} TERMINE -------------------------"
