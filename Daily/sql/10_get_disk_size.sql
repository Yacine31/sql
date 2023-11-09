prompt <h2>Disk and Memory Size </h2>
set echo off head off
prompt <pre>
host df -h
prompt </pre>

prompt <pre>
lsblk -f
prompt </pre>

prompt <pre>
free -h
prompt </pre>
exit