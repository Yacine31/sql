COL_NORMAL=$(tput sgr0)
COL_ROUGE=$(tput setaf 1)
COL_VERT=$(tput setaf 2)
COL_JAUNE=$(tput setaf 3)
COL_BLUE=$(tput setaf 4)
COL_VIOLET=$(tput setaf 5)
COL_CYNA=$(tput setaf 6)
COL_BLANC=$(tput setaf 7)
COL_GRIS=$(tput setaf 8)


tail -100f /u01/app/oracle/diag/rdbms/$(echo ${ORACLE_SID} | tr 'A-Z' 'a-z')/${ORACLE_SID}/trace/alert_${ORACLE_SID}.log | sed -E \
	-e "s,^($(date +'%a %b')).*,${COL_JAUNE}&${COL_NORMAL},g" \
	-e "s,.*(ALTER|alter).*,${COL_VERT}&${COL_NORMAL},g" \
	-e "s,.*WARNING.*,${COL_VIOLET}&${COL_NORMAL},g" \
	-e "s,.*(ERROR:|ORA-).*,${COL_ROUGE}&${COL_NORMAL},g" \
    -e "s,.*,${COL_NORMAL}&${COL_NORMAL},"


