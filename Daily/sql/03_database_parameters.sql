prompt <h2>Database Parameters </h2>
select NAME, DISPLAY_VALUE from v$parameter where ISDEFAULT='FALSE' order by name;
exit