prompt <h2>Resource Limit (GV$RESOURCE_LIMIT)</h2>
SELECT /*+  NO_MERGE  */ 
       *
  FROM gv$resource_limit
 ORDER BY
       resource_name,
       inst_id;
exit