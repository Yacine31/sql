set head off
col "Database Size" format 99,999.99
select 'Database Size (Go) : ' || (
    SELECT ROUND(SUM(TAILLE_BYTES)/1024/1024/1024,2) "Database Size" FROM
        (
            SELECT SUM(FILE_SIZE_BLKS*BLOCK_SIZE) TAILLE_BYTES FROM V$CONTROLFILE
            UNION ALL
            SELECT SUM(BYTES) FROM V$TEMPFILE
            UNION ALL
            SELECT SUM(BYTES) FROM V$DATAFILE
            UNION ALL
            SELECT SUM(MEMBERS*BYTES) FROM V$LOG
            UNION ALL
            SELECT BYTES FROM V$STANDBY_LOG SL, V$LOGFILE LF WHERE SL.GROUP# = LF.GROUP#
        )
    )
from dual;
exit