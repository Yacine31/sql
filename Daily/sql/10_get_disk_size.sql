prompt <h2>Disk and Memory Size </h2>
set echo off head off
prompt <pre>
host df -h
prompt </pre>

prompt <pre>
host lsblk -f
prompt </pre>

prompt <pre>
host cat /etc/fstab
prompt </pre>

prompt <pre>
host free -h
prompt </pre>

prompt <pre>
host lscpu
prompt </pre>
exit