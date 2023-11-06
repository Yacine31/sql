prompt <h2>Invalid objects</h2>
select owner, count(*) "invalid objects" FROM dba_objects WHERE status <> 'VALID' group by owner order by owner;
exit
