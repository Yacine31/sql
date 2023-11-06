prompt <h2>Taille des redolog par jours / heure </h2>
set head off
select max('Taille des fichiers redolog (Mo) : ' || bytes/1024/1024) from v$log;

set head on
set pages 999 lines 200
col Date for a12
col Total for 9999
col 00 for 999
col 01 for 999
col 02 for 999
col 03 for 999
col 04 for 999
col 05 for 999
col 06 for 999
col 07 for 999
col 08 for 999
col 09 for 999
col 10 for 999
col 11 for 999
col 12 for 999
col 13 for 999
col 14 for 999
col 15 for 999
col 16 for 999
col 17 for 999
col 18 for 999
col 19 for 999
col 20 for 999
col 21 for 999
col 22 for 999
col 23 for 999
col 24 for 999


select to_char(first_time, 'YYYY/MM/dd') "Date",
count(1) "Total",
sum(decode(to_char(first_time, 'hh24'),'00',1,0)) "00",
sum(decode(to_char(first_time, 'hh24'),'01',1,0)) "01",
sum(decode(to_char(first_time, 'hh24'),'02',1,0)) "02",
sum(decode(to_char(first_time, 'hh24'),'03',1,0)) "03",
sum(decode(to_char(first_time, 'hh24'),'04',1,0)) "04",
sum(decode(to_char(first_time, 'hh24'),'05',1,0)) "05",
sum(decode(to_char(first_time, 'hh24'),'06',1,0)) "06",
sum(decode(to_char(first_time, 'hh24'),'07',1,0)) "07",
sum(decode(to_char(first_time, 'hh24'),'08',1,0)) "08",
sum(decode(to_char(first_time, 'hh24'),'09',1,0)) "09",
sum(decode(to_char(first_time, 'hh24'),'10',1,0)) "10",
sum(decode(to_char(first_time, 'hh24'),'11',1,0)) "11",
sum(decode(to_char(first_time, 'hh24'),'12',1,0)) "12",
sum(decode(to_char(first_time, 'hh24'),'13',1,0)) "13",
sum(decode(to_char(first_time, 'hh24'),'14',1,0)) "14",
sum(decode(to_char(first_time, 'hh24'),'15',1,0)) "15",
sum(decode(to_char(first_time, 'hh24'),'16',1,0)) "16",
sum(decode(to_char(first_time, 'hh24'),'17',1,0)) "17",
sum(decode(to_char(first_time, 'hh24'),'18',1,0)) "18",
sum(decode(to_char(first_time, 'hh24'),'19',1,0)) "19",
sum(decode(to_char(first_time, 'hh24'),'20',1,0)) "20",
sum(decode(to_char(first_time, 'hh24'),'21',1,0)) "21",
sum(decode(to_char(first_time, 'hh24'),'22',1,0)) "22",
sum(decode(to_char(first_time, 'hh24'),'23',1,0)) "23",
sum(decode(to_char(first_time, 'hh24'),'24',1,0)) "24"
from v$log_history
group by to_char(first_time, 'YYYY/MM/dd')
order by to_char(first_time, 'YYYY/MM/dd')
;

prompt <h2>Taille des redolog par jour </h2>
select
        to_char(first_time, 'YYYY/MM/dd') "Jour",
    count(*) "Nbr de fichiers",
        ROUND(sum(BLOCKS*BLOCK_SIZE)/1024/1024, 0) "Taille_Mo"
from v$archived_log
group by to_char(first_time, 'YYYY/MM/dd')
order by to_char(first_time, 'YYYY/MM/dd')
;

exit
