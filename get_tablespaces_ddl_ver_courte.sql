SET PAGES 999 LINES 150
SELECT
    'CREATE TABLESPACE "' || ts.tablespace_name || '" ' || CHR(13) || CHR(10)
    || LISTAGG(' DATAFILE ' 
	||  decode(p.value, NULL, '''' || df.file_name || '''')  -- si OMF pas de nom de fichier  
    	|| ' SIZE '
        || nvl(e.used_bytes, 10 * 1024 * 1024) -- si taille nulle, on retourne 10M
        || decode(df.autoextensible, 'YES', ' AUTOEXTEND ON'),
        ',' || CHR(13) || CHR(10)) 
        WITHIN GROUP(ORDER BY df.file_id, df.file_name)
    || ';' ddl
FROM dba_tablespaces  ts, dba_data_files   df,
    (SELECT file_id, SUM(decode(bytes, NULL, 0, bytes)) used_bytes FROM dba_extents GROUP BY file_id ) e,
    (select VALUE from v$parameter where name='db_create_file_dest') p
WHERE ts.tablespace_name NOT IN ( 'SYSTEM', 'SYSAUX' )
    AND ts.tablespace_name NOT LIKE '%UNDO%'
    AND e.file_id (+) = df.file_id
    AND ts.tablespace_name = df.tablespace_name
GROUP BY ts.tablespace_name, ts.bigfile, ts.block_size
ORDER BY ts.tablespace_name;

EXIT

