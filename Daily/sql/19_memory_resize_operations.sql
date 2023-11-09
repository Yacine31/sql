prompt <h2>Memory Resize Operations</h2>
SELECT /*+  NO_MERGE  */ 
       *
  FROM gv$memory_resize_ops
 ORDER BY
       inst_id,
       start_time DESC,
       component;
exit 
