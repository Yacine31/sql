#!/bin/sh
#------------------------------------------------------------------------------
# ORACLE DATABASE : BACKUP RMAN DB + AL
#------------------------------------------------------------------------------
# Historique :
#       14/09/2011 : YAO - Creation
#       13/10/2015 : YAO - ajout des params en ligne de commande
#       24/10/2017 : YAO - ajout de level 0 + stby ctlfile + spfile including ctrl file
#------------------------------------------------------------------------------

#------------------------------------------------------------------------------
# fonction init : c'est ici qu'il faut modifier toutes les variables liees
# a l'environnement
#------------------------------------------------------------------------------
f_init() {

	export ORACLE_OWNER=oracle
	export NLS_DATE_FORMAT="YYYY/MM/DD HH24:MI:SS"

	# les differents repertoires
	export SCRIPTS_DIR=/home/oracle/scripts
	export BKP_LOG_DIR=$SCRIPTS_DIR/logs
	export BKP_LOCATION=/u04/backup/${ORACLE_SID}/backup_rman

	# nombre de sauvegarde RMAN en ligne a garder
	export BKP_REDUNDANCY=2
	export DATE_JOUR=$(date +%Y%m%d-%H%M)
	export BKP_LOG_FILE=${BKP_LOG_DIR}/backup_rman_${ORACLE_SID}_${BKP_TYPE}_${DATE_JOUR}.log
	export RMAN_CMD_FILE=${SCRIPTS_DIR}/rman_cmdfile_${ORACLE_SID}_${BKP_TYPE}.rman
	# nombre de jours de conservation des logs de la sauvegarde
	export BKP_LOG_RETENTION=15
	# nombre de jours de conservation des archivelog sur disque
	export ARCHIVELOG_RETENTION=0

} # f_init

#------------------------------------------------------------------------------
# fonction d'aide
#------------------------------------------------------------------------------
f_help() {

        cat <<CATEOF
syntax : $O -s ORACLE_SID -t DB|AL

-s ORACLE_SID

-t
	-t DB => backup full (database + archivelog)
	-t AL => backup des archivelog seulement

CATEOF
exit $1

} #f_help

#------------------------------------------------------------------------------
# fonction backup_is_running
#------------------------------------------------------------------------------
f_is_running() {

	RUNNING_BKP=$($ORACLE_HOME/bin/sqlplus -s / as sysdba <<EOF
	-- set echo off heading off
	-- select distinct status from v\$rman_status where status like 'RUNNING%';
	SET ECHO OFF NEWP 0 SPA 0 PAGES 0 FEED OFF HEAD OFF TRIMS ON lines 132
	SELECT COUNT(*) FROM V\$RMAN_STATUS WHERE SUBSTR(STATUS,1,7)='RUNNING';
	exit
EOF
) 

	if [[ "$RUNNING_BKP" -ne 0 ]]; then
		f_print "Backup RMAN en cours ... on quitte"
		echo "Backup RMAN en cours ... on quitte"
		exit $1
	fi

} #f_help

#------------------------------------------------------------------------------
# fonction d'affichage de la date ds les logs
#------------------------------------------------------------------------------
f_print()
{
        echo "[`date +"%Y/%m/%d %H:%M:%S"`] : $1" >> $BKP_LOG_FILE
} #f_print

#------------------------------------------------------------------------------
# fonction de traitement des options de la ligne de commande
#------------------------------------------------------------------------------
f_options() {

        case ${BKP_TYPE} in
        [dD][bB]) 
			BKP_DB_PLUS_AL=TRUE;
        ;;
        [aA][lL])
			BKP_DB_PLUS_AL=FALSE;
        ;;
        *) f_help 2;
        ;;
        esac

} #f_options


#----------------------------------------
#------------ MAIN ----------------------
#----------------------------------------

while getopts s:t:h o
do
        case $o in
        t) BKP_TYPE=$OPTARG;
        ;;
        s) ORACLE_SID=$OPTARG;
        ;;
        h) f_help 0;
        ;;
        *) f_help 2;
        ;;
        esac
done

# traitement de la ligne de commande
f_options


[ "${BKP_TYPE}" ] || f_help 2;
BKP_TYPE=$(echo ${BKP_TYPE} | tr [a-z] [A-Z])
[ "${ORACLE_SID}" ] || f_help 2;

# positionner les variables d'environnement ORACLE
export ORACLE_SID
ORAENV_ASK=NO
PATH=/usr/local/bin:$PATH
. oraenv -s

# inititalisation des variables d'environnement
f_init


# si ce n'est pas le user oracle qui lance le script, on quitte
if (test `whoami` != $ORACLE_OWNER)
then
	echo
	echo "-----------------------------------------------------"
	echo "Vous devez etre $ORACLE_OWNER pour lancer ce script"
	echo "-----------------------------------------------------"
	exit 2
fi

# initialisation des chemins, s'ils n'existent pas ils seront crees par la commande install
install -d ${BKP_LOCATION}
install -d ${BKP_LOG_DIR}

# verifier si un backup RMAN est en cours
f_is_running

# generation du script de la sauvegarde RMAN
echo "
run {
CONFIGURE DEVICE TYPE DISK PARALLELISM 1 ;
CONFIGURE RETENTION POLICY TO REDUNDANCY ${BKP_REDUNDANCY};

CONFIGURE CONTROLFILE AUTOBACKUP ON;
CONFIGURE CONTROLFILE AUTOBACKUP FORMAT FOR DEVICE TYPE DISK TO '${BKP_LOCATION}/ctrlfile_auto_%F';
" > ${RMAN_CMD_FILE}

# si sauvegarde DB (-t db) on ajoute cette ligne
if [ "${BKP_DB_PLUS_AL}" == "TRUE" ]; then
echo "
BACKUP INCREMENTAL LEVEL 0 DEVICE TYPE DISK FORMAT '${BKP_LOCATION}/data_%T_%t_%s_%p' TAG 'DATA_${DATE_JOUR}' as compressed backupset database;
" >> ${RMAN_CMD_FILE}
fi

# on continue avec la partie commune : backup des archivelog + spfile + controlfile
echo "
SQL 'ALTER SYSTEM ARCHIVE LOG CURRENT';
BACKUP DEVICE TYPE DISK FORMAT '${BKP_LOCATION}/arch_%T_%t_%s_%p' TAG 'ARCH_${DATE_JOUR}' AS COMPRESSED BACKUPSET ARCHIVELOG ALL DELETE ALL INPUT;

BACKUP SPFILE INCLUDE CURRENT CONTROLFILE FORMAT '${BKP_LOCATION}/spfile_ctrlfile_%T_%t_%s_%p' TAG 'SPFILE_CTRLFILE_${DATE_JOUR}';
BACKUP CURRENT CONTROLFILE FOR STANDBY FORMAT '${BKP_LOCATION}/standby_ctrlfile_%T_%t_%s_%p' TAG 'STBY-CTLFILE_${DATE_JOUR}';

CROSSCHECK ARCHIVELOG ALL;
DELETE NOPROMPT ARCHIVELOG ALL;
DELETE NOPROMPT OBSOLETE;
DELETE NOPROMPT EXPIRED BACKUPSET;

sql \"ALTER DATABASE BACKUP CONTROLFILE TO TRACE as ''${BKP_LOCATION}/controlfile_${ORACLE_SID}.trc'' reuse\";
SQL \"CREATE PFILE=''${BKP_LOCATION}/pfile_${ORACLE_SID}.ora'' FROM SPFILE\";
}
" >> ${RMAN_CMD_FILE}

# Execution du script RMAN
f_print "------------------------- DEBUT DE LA BACKUP -------------------------"
${ORACLE_HOME}/bin/rman target / cmdfile=${RMAN_CMD_FILE} log=${BKP_LOG_FILE}

# Nettoyage auto des logs : duree de concervation determinee par la variable : ${BKP_LOG_RETENTION}
f_print "------------------------- NETTOYAGE DES LOGS -------------------------"
find ${BKP_LOG_DIR} -type f -iname "backup_rman_${BKP_TYPE}*.log" -mtime +${BKP_LOG_RETENTION} -exec rm -fv "{}" \; >> $BKP_LOG_FILE

f_print "------------------------- BACKUP ${BKP_TYPE} TERMINE -------------------------"
