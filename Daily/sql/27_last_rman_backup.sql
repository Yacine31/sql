prompt <h2>Last RMAN backups </h2>
alter session set nls_date_format='DD/MM/YYYY HH24:MI:SS' ;
set linesize 250 heading off;
set heading on pagesize 999;
column status format a25;
column input_bytes_display format a12;
column output_bytes_display format a12;
column device_type format a10;

select
        b.input_type,
        b.status,
        to_char(b.start_time,'DD-MM-YYYY HH24:MI') "Start Time",
        to_char(b.end_time,'DD-MM-YYYY HH24:MI') "End Time",
        b.output_device_type device_type,
        b.input_bytes_display,
        b.output_bytes_display
FROM v$rman_backup_job_details b
WHERE b.start_time > (SYSDATE - 30)
ORDER BY b.start_time asc;
exit
