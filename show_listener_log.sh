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

Le script fait un "tail -f" sur le fichier alertlog

OPTIONS:
   -h      Affiche ce message
   -l      Nom du listener (par default = LISTENER)
EOF
}


#--------------------------------------------
#--------------- Fonction d'affichage coloré du fichier log
#--------------------------------------------
show_alert()
{
        echo ${COL_ROUGE}
        echo ===========
        echo Fichier alert : ${TRC_LOG}
        echo Ctrl + C pour quitter
        echo ===========
        echo ${COL_NORMAL}

        tail -20f ${TRC_LOG} | sed -E \
                -e "s,^($(date +'%a %b')).*,${COL_JAUNE}&${COL_NORMAL},g" \
                -e "s,^($(date +'%Y-%m-%d')).*,${COL_JAUNE}&${COL_NORMAL},g" \
                -e "s,.*[1-9999]$,${GRAS}${COL_BLEU}&${COL_NORMAL},g" \
                -e "s,.*WARNING.*,${COL_VIOLET}&${COL_NORMAL},g" \
                -e "s,.*(ERROR:|ORA-|TNS-).*,${GRAS}${COL_ROUGE}&${COL_NORMAL},g" \
                -e "s,^(ARC|RFS|LNS|MRP).*,${COL_BLUE}&${COL_NORMAL},g" \
                -e "s,.*(stop|start|Start).*,${COL_CYAN}&${COL_NORMAL},g" \
                -e "s,.*,${COL_NORMAL}&${COL_NORMAL},"

}

#--------------------------------------------
#--------------- MAIN
#--------------------------------------------

LISTENER_NAME="LISTENER"

#--------------------------------------------
# Traitement des paramètres de la ligne de commande
#--------------------------------------------
while getopts "hl:abcu" OPTION; do
        case ${OPTION} in
          h)
                usage
                exit 0
                ;;
          l)
                LISTENER_NAME=${OPTARG}
                ;;
          ?)
                usage
                exit 0
                ;;
        esac
done

if [ -z "${LISTENER_NAME}" ];
then
        echo "\$LISTENER non définie et pas de LISTENER en paramètre (-l)."
        exit 1
fi

#--------------------------------------------
# determiner le repertoire du fichier log
#--------------------------------------------


LOWER_LISTENER_NAME=$(echo ${LISTENER_NAME} | tr 'A-Z' 'a-z')
UPPER_LISTENER_NAME=$(echo ${LISTENER_NAME} | tr 'a-z' 'A-Z')

# determiner si le listener est démarrée ou pas

if [ $(ps -ef | grep "tnslsnr ${UPPER_LISTENER_NAME}" | grep -v grep | wc -l) -eq 1 ] ;
then
        # listener démarré, on lui demande le chemin vers le fichier log
        TRC_DIR=$(lsnrctl show trc_directory ${UPPER_LISTENER_NAME} | grep "^LISTENER parameter" | cut -d' ' -f6)
        TRC_LOG=${TRC_DIR}/${LOWER_LISTENER_NAME}.log
else
        # le listener n'est pas démarré, on récupère le chemin par défaut 
        DIAG_DEST=$(adrci exec="SHOW BASE" | grep -o '".*"' | tr -d '"')
        H_NAME=$(hostname | cut -d. -f1)
        TRC_LOG="${DIAG_DEST}/diag/tnslsnr/${H_NAME}/${LOWER_LISTENER_NAME}/trace/${LOWER_LISTENER_NAME}.log"
fi

#--------------------------------------------
# affichage du fichier log du listener
#--------------------------------------------
if [ -e "${TRC_LOG}" ]
then
        show_alert
else
        echo
        echo "le fichier : ${COL_ROUGE}${GRAS_ARR_PLAN}${TRC_LOG}${COL_NORMAL} est introuvable !!"
        echo
        exit 1
echo
fi