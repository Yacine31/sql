select '------- HOSTNAME : '||host_name||', DB_NAME : '||name||', VERSION : '||version || ' -------' from v$database,v$instance;
select '------- Datafiles -------' from dual;
SELECT 'CREATE '
      || DECODE (ts.bigfile, 'YES', 'BIGFILE ') --assuming smallfile is the default table space
      || 'TABLESPACE "' || ts.tablespace_name || '" DATAFILE ' || CHR(13) || CHR(10)
      || LISTAGG(decode(p.value, NULL, '  ''' || df.file_name || '''')  || ' SIZE '
         || CASE
              -- si la taille est nulle ou < 1M on retourne 1M
               WHEN e.used_bytes is NULL or e.used_bytes < (1024*1024)
               THEN '1M'
               ELSE to_char(floor(e.used_bytes/(1024*1024))) || 'M'
            END
         || DECODE (df.autoextensible, 'YES', ' AUTOEXTEND ON'),
         ',' || CHR (13) || CHR (10))
      WITHIN GROUP (ORDER BY df.file_id, df.file_name)
      || ';'
      ddl
   FROM  dba_tablespaces ts,
         dba_data_files df,
         (SELECT file_id, sum(decode(bytes,NULL,0,bytes)) used_bytes FROM dba_extents GROUP by file_id) e,
         (select VALUE from v$parameter where name='db_create_file_dest') p
   WHERE ts.tablespace_name not in ('SYSTEM','SYSAUX')
      and ts.tablespace_name not like '%UNDO%'
      and e.file_id (+) = df.file_id
      and ts.tablespace_name = df.tablespace_name
   GROUP BY ts.tablespace_name,
         ts.bigfile,
         ts.block_size
   ORDER BY ts.tablespace_name;

select '------- Tempfiles -------' from dual;

SELECT 'CREATE TEMPORARY TABLESPACE "' || ts.tablespace_name || '" TEMPFILE ' || CHR (13) || CHR (10)
      || LISTAGG(decode(p.value, NULL, '  ''' || df.file_name || '''')  || ' SIZE '
         || CASE
               -- si la taille est nulle ou < 1M on retourne 1M
               WHEN e.used_bytes is NULL or e.used_bytes < (1024*1024)
               THEN '1M'
               ELSE to_char(floor(e.used_bytes/(1024*1024))) || 'M'
            END
         || DECODE (df.autoextensible, 'YES', ' AUTOEXTEND ON'), 
         ',' || CHR (13) || CHR (10))
      WITHIN GROUP (ORDER BY df.file_id, df.file_name)
      || ';'
      ddl
   FROM dba_tablespaces ts,
        dba_temp_files df,
      (SELECT file_id, sum(decode(bytes,NULL,0,bytes)) used_bytes FROM dba_extents GROUP by file_id) e,
      (select VALUE from v$parameter where name='db_create_file_dest') p
   WHERE e.file_id (+) = df.file_id
         and ts.tablespace_name = df.tablespace_name
   GROUP BY ts.tablespace_name,
         ts.bigfile,
         ts.block_size
   ORDER BY ts.tablespace_name;


EXIT

