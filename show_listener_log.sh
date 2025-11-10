#!/bin/bash

#------------------------------------------------------------------------------
# Historique :
#       10/11/2025 : Gemini - Améliorations : lisibilité, robustesse et efficacité
#------------------------------------------------------------------------------

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

Le script localise le fichier log du listener et fait un "tail -f" sur ce fichier

OPTIONS:
   -h      Affiche ce message
   -l      Nom du listener (par default = LISTENER)
EOF
}


#--------------------------------------------
#--------------- Fonction d'affichage coloré du fichier log
#--------------------------------------------
show_listener_log()
{
        echo ${COL_ROUGE}
        echo ===========
        echo Fichier log Listener : ${TRC_LOG}
        echo Ctrl + C pour quitter
        echo ===========
        echo ${COL_NORMAL}

        tail -20f ${TRC_LOG} | sed -E \
                -e "s,^($(date +'%a %b')).*,${COL_JAUNE}&${COL_NORMAL},g" \
                -e "s,^($(date +'%Y-%m-%d')).*,${COL_JAUNE}&${COL_NORMAL},g" \
                -e "s,.*WARNING.*,${COL_VIOLET}&${COL_NORMAL},g" \
                -e "s,.*(ERROR:|ORA-|TNS-).*,${GRAS}${COL_ROUGE}&${COL_NORMAL},g" \
                -e "s,.*(stop|start|Start).*,${COL_CYAN}&${COL_NORMAL},g"

}

#--------------------------------------------
#--------------- MAIN
#--------------------------------------------

LISTENER_NAME="LISTENER"

#--------------------------------------------
# Traitement des paramètres de la ligne de commande
#--------------------------------------------
while getopts "hl:" OPTION; do
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

if pgrep -f "tnslsnr ${UPPER_LISTENER_NAME}" >/dev/null ;
then
        # listener démarré, on lui demande le chemin vers le fichier log
        TRC_DIR=$(lsnrctl show trc_directory ${UPPER_LISTENER_NAME} | grep "TRC_DIRECTORY =" | cut -d'=' -f2 | tr -d '[:space:]"')
        TRC_LOG=${TRC_DIR}/${LOWER_LISTENER_NAME}.log
else
        # le listener n'est pas démarré, on récupère le chemin par défaut 
        DIAG_DEST=$(adrci exec="SHOW BASE" | grep "ADR base is" | cut -d'"' -f2)
        H_NAME=$(hostname | cut -d. -f1)
        TRC_LOG="${DIAG_DEST}/diag/tnslsnr/${H_NAME}/${LOWER_LISTENER_NAME}/trace/${LOWER_LISTENER_NAME}.log"
fi

#--------------------------------------------
# affichage du fichier log du listener
#--------------------------------------------
if [ -e "${TRC_LOG}" ]
then
        show_listener_log
else
        echo
        echo "le fichier : ${COL_ROUGE}${GRAS}${TRC_LOG}${COL_NORMAL} est introuvable !!"
        echo
        exit 1
echo
fi