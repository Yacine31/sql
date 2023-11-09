prompt <h2>Datafiles </h2>
SELECT /*+  NO_MERGE  */ 
       x.file_name, x.file_id, x.tablespace_name, round(x.bytes/1024/1024,0) "Bytes_Mo", x.status, x.autoextensible, round(x.maxbytes/1024/1024/1024,0) "MaxBytes_Go", x.online_status
	   --,c.name con_name
  FROM dba_data_files x
       --LEFT OUTER JOIN v$containers c ON c.con_id = x.con_id
 ORDER BY
       --x.con_id,
	   x.file_name;
exit