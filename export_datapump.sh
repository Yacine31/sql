#!/bin/sh
#------------------------------------------------------------------------------
# Historique :
#       14/09/2011 : YOU - Creation
#       14/10/2015 : YOU - script générique pour toutes les bases
#------------------------------------------------------------------------------
#------------------------------------------------------------------------------
# fonction init : c'est ici qu'il faut modifier toutes les variables liées
# à l'environnement
#------------------------------------------------------------------------------
export ORACLE_OWNER=oracle

f_init() {

	# positionner les variables d'environnement
	export SCRIPTS_DIR=/home/oracle/scripts
	# paramètres de lang
	export LANG=en_US.UTF-8
	export NLS_LANG=AMERICAN_AMERICA.${NLS_CHARACTERSET}

	# répertoire destination de l'export
	export EXP_LOCATION=/u03/backup/$ORACLE_SID/export_dpump
	# nom du répertoire au niveau de la base de données
	export DPDIR=EXPDP_DIR

	# date = jour de la semaine : permet de garder 7 export en ligne
	export JOUR_SEMAINE=$(date +%A)
} #f_init

#------------------------------------------------------------------------------
# fonction d'aide
#------------------------------------------------------------------------------
f_help() {

echo "

syntaxe : $0 -s ORACLE_SID 
------
"
exit $1

} #f_help

#----------------------------------------
#------------ MAIN ----------------------
#----------------------------------------

unset ORACLE_SID

while getopts :s:h o
do
        case $o in
        s) ORACLE_SID=$OPTARG;
        ;;
        h) f_help 0;
        ;;
        *) f_help 2;
        ;;
        \?) f_help 2;
        ;;
        esac
done

[ "${ORACLE_SID}" ] || f_help 2;

#------------------------------------------------------------------------------
# si ce n'est pas le user oracle qui lance le script, on quitte
#------------------------------------------------------------------------------
if (test `whoami` != $ORACLE_OWNER)
then
  echo "Vous devez etre $ORACLE_OWNER pour lancer ce script"
  exit
fi

#------------------------------------------------------------------------------
# positionner les variables d'environnement ORACLE
#------------------------------------------------------------------------------
export ORACLE_SID
ORAENV_ASK=NO
PATH=/usr/local/bin:$PATH
. oraenv -s

#------------------------------------------------------------------------------
# recuperation du NLS_CHARACTERSET
#------------------------------------------------------------------------------
NLS_CHARACTERSET=$($ORACLE_HOME/bin/sqlplus -S / as sysdba <<EOF
set heading off
set feedback off
set echo off
select VALUE from nls_database_parameters where PARAMETER='NLS_CHARACTERSET';
EOF
)
NLS_CHARACTERSET=$(echo $NLS_CHARACTERSET | sed 's/^\s*//g')

#------------------------------------------------------------------------------
# inititalisation des variables d'environnement
#------------------------------------------------------------------------------
f_init

# creation du repertoire de sauvegarde. S'il existe la commande install ne fait rien
install -d ${EXP_LOCATION}

#------------------------------------------------------------------------------
# creation du répertoire DPDIR au niveau de la base
#------------------------------------------------------------------------------
$ORACLE_HOME/bin/sqlplus -S / as sysdba <<EOF
set heading off
set feedback off
set echo off
create or replace directory $DPDIR as '${EXP_LOCATION}';
grant read, write on directory $DPDIR to public;
exit
EOF


#------------------------------------------------------------------------------
# export des données
#------------------------------------------------------------------------------
$ORACLE_HOME/bin/expdp \'/ as sysdba\' full=y \
	directory=$DPDIR \ 
	dumpfile=export_${ORACLE_SID}_${JOUR_SEMAINE}.dmp \
	logfile=export_${ORACLE_SID}_${JOUR_SEMAINE}.log \
	flashback_time=systimestamp
	reuse_dumpfiles=yes
