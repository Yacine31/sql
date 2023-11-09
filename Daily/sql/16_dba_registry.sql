prompt <h2>Registry (DBA_REGISTRY)</h2>
SELECT /*+  NO_MERGE  */ 
       x.*
	   --,c.name con_name
  FROM dba_registry x
       --LEFT OUTER JOIN v$containers c ON c.con_id = x.con_id
ORDER BY
       --x.con_id,
	   x.comp_id;
exit;
