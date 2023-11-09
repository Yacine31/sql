prompt <h2>Disk Size df -h</h2>
set echo off head off
prompt <pre>
host df -h
prompt </pre>

prompt <h2>lsblk -f </h2>
prompt <pre>
host lsblk -f
prompt </pre>

prompt <h2>cat /etc/fstab </h2>
prompt <pre>
host cat /etc/fstab
prompt </pre>

prompt <h2>Memory Size free -h </h2>
prompt <pre>
host free -h
prompt </pre>

prompt <h2>lscpu </h2>
prompt <pre>
host lscpu
prompt </pre>
exit