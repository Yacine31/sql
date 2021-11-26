#!/bin/bash

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

#--------------- fonction usage()
usage()
{
cat << EOF
usage: $(basename $0) options

Le script fait un "tail -f" sur le fichier alertlog

OPTIONS:
   -h      Affiche ce message
   -i      Nom de l'instance (par default = \$ORACLE_SID)
EOF
}

#--------------- Vérifier si l'instance est en cours d'exécution
test_instance()
{
        if [ $(ps -ef | grep pmon_${ORACLE_SID}\$ | grep -v grep | wc -l) -eq 1 ]; then
                return 0
        else
                return 1
        fi
}

#--------------- Fonction d'affichage coloré du fichier alertlog
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
                -e "s,.*(ALTER|alter).*,${GRAS}${COL_VERT}&${COL_NORMAL},g" \
                -e "s,.*WARNING.*,${COL_VIOLET}&${COL_NORMAL},g" \
                -e "s,.*(ERROR:|ORA-).*,${GRAS}${COL_ROUGE}&${COL_NORMAL},g" \
                -e "s,^(ARC|RFS|LNS|MRP).*,${COL_BLUE}&${COL_NORMAL},g" \
                -e "s,.*(Online Redo|online redo|Current log).*,${COL_CYAN}&${COL_NORMAL},g" \
                -e "s,.*,${COL_NORMAL}&${COL_NORMAL},"

}

#--------------- MAIN

INSTANCE=${ORACLE_SID}

# Traitement des paramètres de la ligne de commande
while getopts "hi:abcu" OPTION; do
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

test_instance || { echo "Instance ${ORACLE_SID} non démarrée !!";  exit 1 ; }

# Potionner les variables d'environnement
export ORACLE_SID
export ORAENV_ASK=NO
. oraenv -s >/dev/null


# determiner si c'est une instance DB ou ASM
# si l'instant est ASM alors le sous reprtoire est asm, sinon rdbms
if [ "$(echo ${ORACLE_SID} | tr A-Z a-z | grep asm)" ]; then
        SUB_DIR="asm"
else
        SUB_DIR="rdbms"
fi

DIAG_DEST=$(echo "show parameter diagnostic_dest" | sqlplus / as sysdba | grep "^diagnostic_dest" | awk '{print $3}')
DB_UNIQ_NAME=$(echo "show parameter db_unique_name" | sqlplus / as sysdba | grep "^db_unique_name" | awk '{print $3}')

F_ALERT="${DIAG_DEST}/diag/${SUB_DIR}/$(echo ${DB_UNIQ_NAME} | tr 'A-Z' 'a-z')/${ORACLE_SID}/trace/alert_${ORACLE_SID}.log"

if [ -e "${F_ALERT}" ]
then
        show_alert
else
        echo
        echo "le fichier : ${COL_ROUGE}${GRAS_ARR_PLAN}${F_ALERT}${COL_NORMAL} est introuvable !!"
        echo
        exit 1
echo
fi
