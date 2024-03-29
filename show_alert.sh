#!/bin/bash

LANG=C
COL_NORMAL=$(tput sgr0)
COL_ROUGE=$(tput setaf 1)
COL_VERT=$(tput setaf 2)
COL_JAUNE=$(tput setaf 3)
COL_BLUE=$(tput setaf 4)
COL_VIOLET=$(tput setaf 5)
COL_CYAN=$(tput setaf 6)
COL_BLANC=$(tput setaf 7)
COL_GRIS=$(tput setaf 8)
GRAS=$(tput bold)

#--------------------------------------------
#--------------- fonction usage()
#--------------------------------------------
usage()
{
cat << EOF
usage: $(basename $0) options

Le script trouve le chemin vers le fichier alertlog et fait un "tail -f" sur ce fichier

OPTIONS:
   -h      Affiche ce message
   -i      Nom de l'instance (par default = \$ORACLE_SID)
EOF
}


#--------------------------------------------
#--------------- Fonction d'affichage coloré du fichier alertlog
#--------------------------------------------
show_alert()
{
        echo ${COL_ROUGE}
        echo ===========
        echo Fichier alert : ${F_ALERT}
        echo Ctrl + C pour quitter
        echo ===========
        echo ${COL_NORMAL}

        tail -20f ${F_ALERT} | sed -E \
                -e "s,^($(date +'%a %b')).*,${COL_JAUNE}&${COL_NORMAL},g" \
                -e "s,^($(date +'%Y-%m-%d')).*,${COL_JAUNE}&${COL_NORMAL},g" \
                -e "s,^(ALTER|alter|CREATE|create).*,${GRAS}${COL_VERT}&${COL_NORMAL},g" \
                -e "s,.*WARNING.*,${COL_VIOLET}&${COL_NORMAL},g" \
                -e "s,.*(ERROR:|ORA-|drop|DROP|Delete).*,${GRAS}${COL_ROUGE}&${COL_NORMAL},g" \
                -e "s,^(ARC|RFS|LNS|MRP).*,${COL_BLUE}&${COL_NORMAL},g" \
                -e "s,.*(Online Redo|online redo|Current log).*,${COL_CYAN}&${COL_NORMAL},g" \
                -e "s,.*,${COL_NORMAL}&${COL_NORMAL},"

}

#--------------------------------------------
#--------------- MAIN
#--------------------------------------------

INSTANCE=${ORACLE_SID}

#--------------------------------------------
# Traitement des paramètres de la ligne de commande
#--------------------------------------------
while getopts "hi:" OPTION; do
        case ${OPTION} in
          h)
                usage
                exit 0
                ;;
          i)
                ORACLE_SID=${OPTARG}
                ;;
          ?)
                usage
                exit 0
                ;;
        esac
done

if [ -z "${ORACLE_SID}" ];
then
        echo "\$ORACLE_SID non définie et pas d'INSTANCE en paramètre (-i)."
        exit 1
fi

#--------------------------------------------
# determiner si c'est une instance DB ou ASM
# si l'instant est ASM alors le sous reprtoire est asm, sinon rdbms
#--------------------------------------------
if [ "$(echo ${ORACLE_SID} | tr A-Z a-z | grep asm)" ]; then
        SUB_DIR="asm"
else
        SUB_DIR="rdbms"
fi

#--------------------------------------------
# determiner si l'instance est dans /etc/oratab
#--------------------------------------------
if [ $(cat /etc/oratab | grep "^${ORACLE_SID}:" | grep -v grep | wc -l) -eq 0 ] ;
then
        # pas d'entrée dans /etc/oratab
        echo "-----"
        echo "----- Pas d'entrée dans le fichier /etc/oratab"
        echo "-----"
        exit 1
fi

#--------------------------------------------
# determiner si l'instance est démarrée ou pas
#--------------------------------------------
if [ $(ps -ef | grep pmon_${ORACLE_SID}\$ | grep -v grep | wc -l) -eq 1 ] ;
then
        # instance démarrée, on lui demande le chemin vers l'alertlog

        # Potionner les variables d'environnement
        export ORACLE_SID
        export ORAENV_ASK=NO
        . oraenv -s >/dev/null

        SQL1="set head off"
        SQL2="select value from v\$parameter where name='diagnostic_dest';"
        DIAG_DEST=$(echo -e "$SQL1\n$SQL2" | sqlplus -s / as sysdba | grep -v "^$")

        SQL1="set head off"
        SQL2="select value from v\$parameter where name='db_unique_name';"
        DB_UNIQ_NAME=$(echo -e "$SQL1\n$SQL2" | sqlplus -s / as sysdba | grep -v "^$")

        F_ALERT="${DIAG_DEST}/diag/${SUB_DIR}/$(echo ${DB_UNIQ_NAME} | tr 'A-Z' 'a-z')/${ORACLE_SID}/trace/alert_${ORACLE_SID}.log"
else
        # la base n'est pas démarrée, on récupère le chemin par défaut "uniquename/INSTANCE_NAME" 

        DIAG_DEST=$($ORACLE_HOME/bin/adrci exec="SHOW BASE" | grep -o '".*"' | tr -d '"')
        F_ALERT="${DIAG_DEST}/diag/${SUB_DIR}/$(echo ${ORACLE_SID} | tr 'A-Z' 'a-z')/${ORACLE_SID}/trace/alert_${ORACLE_SID}.log"
fi


#--------------------------------------------
# affichage du fichier alertlog
#--------------------------------------------
if [ -e "${F_ALERT}" ]
then
        show_alert
else
        echo
        echo "-----"
        echo "----- le fichier : ${COL_ROUGE}${GRAS_ARR_PLAN}${F_ALERT}${COL_NORMAL} est introuvable !!"
        echo "-----"
        echo
        exit 1
echo
fi