prompt <h2>Table Statistics Summary</h2>
alter session set nls_date_format='YYYY/MM/DD HH24:MI:SS';
WITH x as (
SELECT /*+  NO_MERGE  */ 
       --con_id,
       owner,
       object_type,
       COUNT(*) type_count,
       SUM(DECODE(last_analyzed, NULL, 1, 0)) not_analyzed,
       SUM(DECODE(stattype_locked, NULL, 0, 1)) stats_locked,
       SUM(DECODE(stale_stats, 'YES', 1, 0)) stale_stats,
       SUM(num_rows) sum_num_rows,
       MAX(num_rows) max_num_rows,
       SUM(blocks) sum_blocks,
       MAX(blocks) max_blocks,
       MIN(last_analyzed) min_last_analyzed,
       MAX(last_analyzed) max_last_analyzed,
       MEDIAN(last_analyzed) median_last_analyzed,
       PERCENTILE_DISC(0.75) WITHIN GROUP (ORDER BY last_analyzed) last_analyzed_75_percentile,
       PERCENTILE_DISC(0.90) WITHIN GROUP (ORDER BY last_analyzed) last_analyzed_90_percentile,
       PERCENTILE_DISC(0.95) WITHIN GROUP (ORDER BY last_analyzed) last_analyzed_95_percentile,
       PERCENTILE_DISC(0.99) WITHIN GROUP (ORDER BY last_analyzed) last_analyzed_99_percentile
  FROM dba_tab_statistics s
 WHERE table_name NOT LIKE 'BIN$%' -- bug 9930151 reported by brad peek
   AND NOT EXISTS (
SELECT /*+  NO_MERGE  */ NULL
  FROM dba_external_tables e
 WHERE e.owner = s.owner
   --AND e.con_id = s.con_id
   AND e.table_name = s.table_name)
GROUP BY
       --con_id,
       owner, object_type
)
SELECT x.*
       --,c.name con_name
FROM   x
       --LEFT OUTER JOIN v$containers c ON c.con_id = x.con_id
 ORDER BY
       --x.con_id,
       owner, object_type;
exit