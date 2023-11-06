prompt <h2>Last alertlog errors </h2>

set pages 999 lines 150
select to_char(ORIGINATING_TIMESTAMP, 'DD-MM-YYYY HH-MM-SS') || ' : ' || message_text "Last alertlog (30 days)"
FROM X$DBGALERTEXT
WHERE originating_timestamp > systimestamp - 30  AND regexp_like(message_text, '(ORA-)');
exit
