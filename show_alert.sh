COL_NORMAL=$(tput sgr0)
COL_ROUGE=$(tput setaf 1)
COL_VERT=$(tput setaf 2)
COL_JAUNE=$(tput setaf 3)
COL_BLUE=$(tput setaf 4)
COL_VIOLET=$(tput setaf 5)
COL_CYAN=$(tput setaf 6)
COL_BLANC=$(tput setaf 7)
COL_GRIS=$(tput setaf 8)
GRAS_ARR_PLAN=$(tput bold; tput setab 7)
GRAS=$(tput bold)

show_alert()
{
        echo 
        echo ${COL_ROUGE}${GRAS_ARR_PLAN}
        echo ===========
        echo Fichier alert : ${f_alert}
        echo Ctrl + C pour quitter
        echo ===========
        echo ${COL_NORMAL}

        tail -20f ${f_alert} | sed -E \
                -e "s,^($(date +'%a %b')).*,${COL_JAUNE}&${COL_NORMAL},g" \
                -e "s,^($(date +'%Y-%m-%d')).*,${COL_JAUNE}&${COL_NORMAL},g" \
                -e "s,.*(ALTER|alter).*,${GRAS}${COL_VERT}&${COL_NORMAL},g" \
                -e "s,.*WARNING.*,${COL_VIOLET}&${COL_NORMAL},g" \
                -e "s,.*(ERROR:|ORA-).*,${GRAS}${COL_ROUGE}&${COL_NORMAL},g" \
                -e "s,^(ARC|RFS|LNS|MRP).*,${COL_BLUE}&${COL_NORMAL},g" \
                -e "s,.*(Online Redo|online redo|Current log).*,${COL_CYAN}&${COL_NORMAL},g" \
                -e "s,.*,${COL_NORMAL}&${COL_NORMAL},"

}

# determiner si c'est une instance DB ou ASM
# si l'instant est ASM alors le sous reprtoire est asm, sinon rdbms
if [ "$(echo ${ORACLE_SID} | tr A-Z a-z | grep asm)" ]; then
	SUB_DIR="asm"
else
	SUB_DIR="rdbms"
fi

NB_PROCESS=$(ps -ef | grep pmon_${ORACLE_SID}\$ | grep -v grep | wc -l)
DIAG_DEST=$(echo "show parameter diagnostic_dest" | sqlplus / as sysdba | grep "^diagnostic_dest" | awk '{print $3}')

if [ ${NB_PROCESS} -ne 1 ]; then
        echo 
        echo Base non active ... Tentative d\'ouverture du fichier alertlog par defaut
        echo
        f_alert="${DIAG_DEST}/diag/${SUB_DIR}/$(echo ${ORACLE_SID} | tr 'A-Z' 'a-z')/${ORACLE_SID}/trace/alert_${ORACLE_SID}.log"
        if [ -e "${f_alert}" ]
        then
                show_alert
        else
        	echo 
        	echo "le fichier : ${COL_ROUGE}${GRAS_ARR_PLAN}${f_alert}${COL_NORMAL} est introuvable !!"
        	echo
        	exit 1
        fi
else
        export DB_UNIQ_NAME=$(echo "show parameter db_unique_name" | sqlplus / as sysdba | grep "^db_unique_name" | awk '{print $3}')
        f_alert="${DIAG_DEST}/diag/${SUB_DIR}/$(echo ${DB_UNIQ_NAME} | tr 'A-Z' 'a-z')/${ORACLE_SID}/trace/alert_${ORACLE_SID}.log"
        show_alert
fi


