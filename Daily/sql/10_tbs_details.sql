COL TABLESPACE_NAME FORMAT A20 HEAD "Nom espace|disque logique"
COL PCT_OCCUPATION_THEORIQUE FORMAT 990.00 HEAD "%occ|Theo"
COL TAILLE_MIB FORMAT 99999990.00 HEAD "Taille|MiB"
COL TAILLE_MAX_MIB FORMAT 99999990.00 HEAD "Taille max|MiB"
COL TAILLE_OCCUPEE_MIB FORMAT 99999990.00 HEAD "Espace occupé|MiB"
WITH TS_FREE_SPACE AS
(select tablespace_name, file_id, sum(bytes) FREE_O from dba_free_space group by tablespace_name, file_id
), TEMP_ALLOC AS
(select tablespace_name, file_id, sum(bytes) USED_O from v$temp_extent_map group by tablespace_name, file_id
)
SELECT
  TABLESPACE_NAME,
  SUM(TAILLE_MIB) TAILLE_MIB,
  SUM(TAILLE_MAX_MIB) TAILLE_MAX_MIB,
  SUM(TAILLE_OCCUPEE_MIB) TAILLE_OCCUPEE_MIB,
  ROUND(SUM(TAILLE_OCCUPEE_MIB)*100/SUM(GREATEST(TAILLE_MAX_MIB,TAILLE_MIB)),2) PCT_OCCUPATION_THEORIQUE
FROM
(
    SELECT D.FILE_NAME, D.TABLESPACE_NAME, D.BYTES/1024/1024 TAILLE_MIB, DECODE(D.AUTOEXTENSIBLE,'NO',D.BYTES,D.MAXBYTES)/1024/1024 TAILLE_MAX_MIB,
      (D.BYTES-FO.FREE_O)/1024/1024 TAILLE_OCCUPEE_MIB
    FROM
      DBA_DATA_FILES D, TS_FREE_SPACE FO
    WHERE
        D.TABLESPACE_NAME=FO.TABLESPACE_NAME
    AND D.FILE_ID=FO.FILE_ID
    UNION ALL
    SELECT T.FILE_NAME, T.TABLESPACE_NAME, T.BYTES/1024/1024 TAILLE_MIB, DECODE(T.AUTOEXTENSIBLE,'NO',T.BYTES,T.MAXBYTES)/1024/1024 TAILLE_MAX_MIB,
      (TA.USED_O)/1024/1024 TAILLE_OCCUPEE_MIB
    FROM
      DBA_TEMP_FILES T, TEMP_ALLOC TA
    WHERE
        T.TABLESPACE_NAME=TA.TABLESPACE_NAME
    AND T.FILE_ID=TA.FILE_ID
)
GROUP BY TABLESPACE_NAME
ORDER BY TABLESPACE_NAME;
exit
