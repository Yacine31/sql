#!/bin/sh
#------------------------------------------------------------------------------
# ORACLE DATABASE : BACKUP RMAN DB + AL
#------------------------------------------------------------------------------
# Historique :
#       14/09/2011 : YOU - Creation
#       13/10/2015 : YOU - ajout des params en ligne de commande
#       24/10/2017 : YOU - ajout de level 0 + stby ctlfile + spfile including ctrl file
#       12/01/2023 : YOU - modification pour les bases non archivelog
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
	export BKP_LOCATION=/u03/backup/${ORACLE_SID}/backup_rman

	# nombre de canaux de sauvegarde en parallel
	export BKP_PARALLELISM=3
	# nombre de sauvegarde RMAN en ligne a garder
	export BKP_REDUNDANCY=2
	export DATE_JOUR=$(date +%Y%m%d-%H%M)
	export BKP_LOG_FILE=${BKP_LOG_DIR}/backup_rman_${ORACLE_SID}_${DATE_JOUR}.log
	export RMAN_CMD_FILE=${SCRIPTS_DIR}/rman_cmdfile_${ORACLE_SID}.rman
	# nombre de jours de conservation des logs de la sauvegarde
	export BKP_LOG_RETENTION=15

} # f_init

#------------------------------------------------------------------------------
# fonction d'aide
#------------------------------------------------------------------------------
f_help() {

        cat <<CATEOF
------------------------------------------------------------------------------
syntax : $O -s ORACLE_SID
------------------------------------------------------------------------------

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


#----------------------------------------
#------------ MAIN ----------------------
#----------------------------------------

while getopts s:h o
do
        case $o in
        s) ORACLE_SID=$OPTARG;
        ;;
        h) f_help 0;
        ;;
        *) f_help 2;
        ;;
        esac
done


[ "${ORACLE_SID}" ] || f_help 2;

# inititalisation des variables d'environnement
f_init

# vérifier si ORACLE_SID est pésente dans le fichier /etc/oratab
if [ "$(grep -v '^$|^#' /etc/oratab | grep -c "^${ORACLE_SID}:")" -ne 1 ]; then
    echo "Base ${ORACLE_SID} absente du fichier /etc/oratab ... fin du script"
    exit 2
fi

# positionner les variables d'environnement ORACLE
export ORACLE_SID
ORAENV_ASK=NO
PATH=/usr/local/bin:$PATH
. oraenv -s


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
CONFIGURE DEVICE TYPE DISK PARALLELISM ${BKP_PARALLELISM} ;
CONFIGURE RETENTION POLICY TO REDUNDANCY ${BKP_REDUNDANCY};

CONFIGURE CONTROLFILE AUTOBACKUP ON;
CONFIGURE CONTROLFILE AUTOBACKUP FORMAT FOR DEVICE TYPE DISK TO '${BKP_LOCATION}/ctrlfile_auto_%F';

SHUTDOWN IMMEDIATE;
STARTUP MOUNT;
BACKUP DEVICE TYPE DISK FORMAT '${BKP_LOCATION}/data_%T_%t_%s_%p' TAG 'DATA_${DATE_JOUR}' as compressed backupset database;
BACKUP CURRENT CONTROLFILE FORMAT '${BKP_LOCATION}/control_%T_%t_%s_%p' TAG 'CTLFILE_${DATE_JOUR}';
BACKUP SPFILE INCLUDE CURRENT CONTROLFILE FORMAT '${BKP_LOCATION}/spfile_ctrlfile_%T_%t_%s_%p' TAG 'SPFILE_CTRLFILE_${DATE_JOUR}';
ALTER DATABASE OPEN;

CROSSCHECK BACKUPSET;
DELETE NOPROMPT OBSOLETE;
DELETE NOPROMPT EXPIRED BACKUPSET;

SQL \"ALTER DATABASE BACKUP CONTROLFILE TO TRACE as ''${BKP_LOCATION}/controlfile_${ORACLE_SID}.trc'' reuse\";
SQL \"CREATE PFILE=''${BKP_LOCATION}/pfile_${ORACLE_SID}.ora'' FROM SPFILE\";

}
" > ${RMAN_CMD_FILE}

# Execution du script RMAN
f_print "------------------------- DEBUT DE LA BACKUP -------------------------"
${ORACLE_HOME}/bin/rman target / cmdfile=${RMAN_CMD_FILE} log=${BKP_LOG_FILE}

# Nettoyage auto des logs : duree de concervation determinee par la variable : ${BKP_LOG_RETENTION}
f_print "------------------------- NETTOYAGE DES LOGS -------------------------"
find ${BKP_LOG_DIR} -type f -iname "backup_rman_${ORACLE_SID}*.log" -mtime +${BKP_LOG_RETENTION} -exec rm -fv "{}" \; >> $BKP_LOG_FILE

f_print "------------------------- BACKUP ${ORACLE_SID} TERMINE -------------------------"
