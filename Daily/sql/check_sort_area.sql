SELECT a.value "Disk Sorts", b.value "Memory Sorts",
ROUND((100*b.value)/DECODE((a.value+b.value), 0,1,(a.value+b.value)),2) "Pct Memory Sorts"
FROM v$sysstat a, v$sysstat b
WHERE a.name = 'sorts (disk)'
AND b.name = 'sorts (memory)';
exit
