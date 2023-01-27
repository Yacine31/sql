DATETIME=`date +%Y%m%d%H%M`

for r in $(ps -eaf | grep pmon | egrep -v 'grep|ASM1|APX1' | cut -d '_' -f3)
do
        export ORACLE_SID=$r
        . oraenv -s
        echo $ORACLE_SID $ORACLE_HOME
        sqlplus -s "/ as sysdba" @DailyCheck_html.sql > DailyCheck_${DATETIME}.html
done
