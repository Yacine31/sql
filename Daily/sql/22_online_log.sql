prompt <h2>Redolog </h2>
SELECT /*+  NO_MERGE  */ 
     *
  FROM v$log
 ORDER BY 1, 2, 3, 4;

prompt <h2>Redolog Files </h2>
COL MEMBER FORMAT A90 WRAPPED
BREAK ON GROUP# SKIP 1 ON THREAD# ON SEQUENCE# ON TAILLE_MIB ON "STATUS(ARCHIVED)"
SELECT 'OnlineLog' T, G.GROUP#, G.THREAD#, G.SEQUENCE#, G.BYTES/1024/1024 TAILLE_MIB, G.STATUS||'('||G.ARCHIVED||')' "STATUS(ARCHIVED)", F.MEMBER
FROM V$LOG G, V$LOGFILE F
WHERE G.GROUP#=F.GROUP#
UNION ALL
SELECT 'StandbyLog',G.GROUP#, G.THREAD#, G.SEQUENCE#, G.BYTES/1024/1024 TAILLE_MIB, G.STATUS||'('||G.ARCHIVED||')' "STATUS(ARCHIVED)", F.MEMBER
FROM V$STANDBY_LOG G, V$LOGFILE F
WHERE G.GROUP#=F.GROUP#
ORDER BY 1,3,4,2;
exit
