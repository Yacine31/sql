prompt
prompt Les tables et lobs dont la taille est >= 1M
prompt
set pages 999 lines 120
col owner for a30
col table_name for a30

WITH table_size AS (
    SELECT dt.owner, dt.table_name,
        ROUND(SUM(ds.bytes)/1024/1024, 2) AS table_size_mb
    FROM dba_segments ds
    JOIN dba_tables dt ON ds.segment_name = dt.table_name
    WHERE ds.segment_type = 'TABLE'
    GROUP BY dt.owner, dt.table_name
),
lob_size AS (
    SELECT dl.owner, dl.table_name,
        ROUND(SUM(ds.bytes)/1024/1024, 2) AS lob_size_mb
    FROM dba_lobs dl
    JOIN dba_segments ds ON ds.segment_name = dl.segment_name
    WHERE ds.segment_type = 'LOBSEGMENT'
    GROUP BY dl.owner, dl.table_name
)
SELECT ts.owner, ts.table_name,
    NVL(ts.table_size_mb,0) AS table_mb,
    NVL(ls.lob_size_mb,0) AS lob_mb,
    (NVL(ts.table_size_mb,0) + NVL(ls.lob_size_mb,0)) AS total_mb
FROM table_size ts
LEFT JOIN lob_size ls ON ts.owner = ls.owner AND ts.table_name = ls.table_name
-- Mettre un nom de user pour limiter les resultats
-- WHERE ts.owner!='SYS'
WHERE ls.lob_size_mb >= 1
ORDER BY total_mb DESC;
