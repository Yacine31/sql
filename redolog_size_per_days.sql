REM 
REM Tailes des redoslog par jour
REM 

set pages 0
select 
	to_char(first_time, 'YYYY/MM/dd') "Jour",
	ROUND(sum(BLOCKS*BLOCK_SIZE)/1024/1024, 0) "Taille_Mo"
from v$archived_log
group by to_char(first_time, 'YYYY/MM/dd')
order by to_char(first_time, 'YYYY/MM/dd')
;
