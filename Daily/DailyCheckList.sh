DATETIME=`date +%Y%m%d%H%M`

for r in $(ps -eaf | grep pmon | egrep -v 'grep|ASM1|APX1' | cut -d '_' -f3)
do
        export ORAENV_ASK=NO
        export ORACLE_SID=$r
        . oraenv -s > /dev/null
        sqlplus -s "/ as sysdba" @DailyCheck_html.sql > DailyCheck_${DATETIME}.html
done
