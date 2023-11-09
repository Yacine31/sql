prompt <h2>SYSAUX Occupants</h2>
SELECT /*+  NO_MERGE  */ 
       v.*, ROUND(v.space_usage_kbytes / POWER(10,6), 3) space_usage_gbs
  FROM v$sysaux_occupants v
 ORDER BY 1;
 exit