. /home/oracle/.bash_profile
SCRIPTDIR=/home/oracle/Daily
LOGDIR=${SCRIPTDIR}/logs
DATETIME=`date +%Y%m%d%H%M`
mv $LOGDIR/DailyCheck.html $LOGDIR/DailyCheck_${DATETIME}.html
rm $LOGDIR/diskspacereport.html
rm $LOGDIR/diskspacereport.txt
rm $LOGDIR/dbnodecpudetails.lst
rm $LOGDIR/diskspacereport1.html
sqlplus -s "/ as sysdba" @$SCRIPTDIR/DailyCheck_html.sql
HOST=$(hostname)
IPADDR=$(hostname -i)
>$LOGDIR/diskspacereport.txt
string1="CPU, Memory and Space Usage Report for DB Server ($HOST | $IPADDR) : \n"
echo -e $string1>> $LOGDIR/diskspacereport.txt
printf "\n"
for i in `seq 1 5` ; do
        >$LOGDIR/dbnodecpudetails.lst
        top -bn 1 | head -n 3 >> $LOGDIR/dbnodecpudetails.lst
        sleep 3
done
cat $LOGDIR/dbnodecpudetails.lst >> $LOGDIR/diskspacereport.txt
echo "<br />" >> $LOGDIR/diskspacereport.txt
free | grep Mem | awk '{ printf("Free Memory: %.2f %\n", ($4+$7)/$2 * 100.0) }' >> $LOGDIR/diskspacereport.txt
echo "<br />" >>  $LOGDIR/diskspacereport.txt
df -h >> $LOGDIR/diskspacereport.txt
echo "<br />" >> $LOGDIR/diskspacereport.txt


echo "*******************************************END OF REPORT****************************************************">> $LOGDIR/diskspacereport.txt
cat $LOGDIR/diskspacereport.txt > $LOGDIR/diskspacereport.html
sed 's/$/<br>/g' $LOGDIR/diskspacereport.html>$LOGDIR/diskspacereport1.html
cat $LOGDIR/diskspacereport1.html >> $LOGDIR/DailyCheck.html
EMAIL_LIST=daily_report@gmail.com
SEND_MAIL()
{
{
echo "To: $EMAIL_LIST"
echo "Subject:Health Check : $ORACLE_SID@`hostname`"
echo "MIME-Version: 1.0"
echo "Content-Type: text/html"
echo "Content-Disposition: inline"
cat  $LOGDIR/DailyCheck.html
} | /usr/sbin/sendmail $EMAIL_LIST
}
SEND_MAIL
[oracle@dbnode1 Daily]$