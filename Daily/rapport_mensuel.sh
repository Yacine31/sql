DATETIME=`date +%Y%m%d%H%M`
HNAME=$(hostname)

for r in $(ps -eaf | grep pmon | egrep -v 'grep|ASM1|APX1' | cut -d '_' -f3)
do
        export ORAENV_ASK=NO
        export ORACLE_SID=$r
        . oraenv -s > /dev/null
        sqlplus -s "/ as sysdba" @rapport_html.sql > Rapport_${ORACLE_SID}_${DATETIME}.html
        echo Rapport dans le fichier html : Rapport_$HNAME_${ORACLE_SID}_${DATETIME}.html
done
