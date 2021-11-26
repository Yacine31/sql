-- le script génère les ordres de création sql des tablespaces et datafiles
-- si un tablespace contient plusieurs fichier, ceci est pris en compte
-- les tablespaces SYSTEM, SYSAUX et UNDO ne sont pas affichés
--
-- version avec la taille exacte des datafile occupée sur disque
--
-- Historique :
-- 2021/11/24 - ajout des tempfiles


set head off pages 0 feedback off lines 200

select '------- HOSTNAME : '||host_name||', DB_NAME : '||name||', VERSION : '||version from v$database,v$instance;

select '------- Datafiles : ' from dual;

SELECT    'CREATE '
         || DECODE (ts.bigfile, 'YES', 'BIGFILE ') --assuming smallfile is the default table space
         || 'TABLESPACE "' || ts.tablespace_name || '" DATAFILE ' || CHR(13) || CHR(10)
         || LISTAGG(decode(p.value, NULL, '  ''' || df.file_name || '''')  || ' SIZE '
               -- || df.bytes -- on ne prends pas la taille du datafile, mais la taille ocupée used_bytes
               -- || nvl(e.used_bytes,10*1024*1024) -- si taille nulle, on retourne 10M
               || decode(floor(e.used_bytes/1024/1024),0,10) || 'M ' -- si taille nulle, on retourne 10M
               || DECODE (
                     df.autoextensible,
                     'YES',    ' AUTOEXTEND ON NEXT ' || decode(floor(df.increment_by*ts.block_size/1024/1024),0,10) || 'M MAXSIZE '
                            || CASE
                                  WHEN maxbytes < POWER (1024, 3) * 2
                                  THEN
                                     TO_CHAR (maxbytes)
                                  ELSE
                                        TO_CHAR (FLOOR (maxbytes / POWER (1024, 2))) || 'M'
                               END),
               ',' || CHR (13) || CHR (10))
            WITHIN GROUP (ORDER BY df.file_id, df.file_name)
         || ';'
            ddl
    FROM    dba_tablespaces ts,
            dba_data_files df,
            (SELECT file_id, sum(decode(bytes,NULL,0,bytes)) used_bytes FROM dba_extents GROUP by file_id) e,
	    (select VALUE from v$parameter where name='db_create_file_dest') p
   WHERE ts.tablespace_name not in ('SYSTEM','SYSAUX')
        and ts.tablespace_name not like '%UNDO%'
         and e.file_id (+) = df.file_id
         and ts.tablespace_name = df.tablespace_name
GROUP BY ts.tablespace_name,
         ts.bigfile,
--         ts.logging,
--         ts.status,
         ts.block_size
ORDER BY ts.tablespace_name;

select '------- Tempfiles : ' from dual;

SELECT    'CREATE TEMPORARY TABLESPACE "' || ts.tablespace_name || '" TEMPFILE ' || CHR (13) || CHR (10)
         || LISTAGG(decode(p.value, NULL, '  ''' || df.file_name || '''')  || ' SIZE '
               || nvl(floor(e.used_bytes/1024/1024),10) || 'M ' -- si taille nulle, on retourne 10M
               || DECODE (
                     df.autoextensible,
                     'YES',    ' AUTOEXTEND ON NEXT ' || floor(df.increment_by*ts.block_size /1024/1024) || 'M MAXSIZE ' 
                     || FLOOR (maxbytes / POWER (1024, 2)) || 'M'
                        ),
               ',' || CHR (13) || CHR (10))
            WITHIN GROUP (ORDER BY df.file_id, df.file_name)
         || ';'
            ddl
    FROM    dba_tablespaces ts,
            dba_temp_files df,
            (SELECT file_id, sum(decode(bytes,NULL,0,bytes)) used_bytes FROM dba_extents GROUP by file_id) e,
        (select VALUE from v$parameter where name='db_create_file_dest') p
   WHERE e.file_id (+) = df.file_id
         and ts.tablespace_name = df.tablespace_name
GROUP BY ts.tablespace_name,
         ts.bigfile,
         ts.logging,
         ts.status,
         ts.block_size
ORDER BY ts.tablespace_name;

exit

