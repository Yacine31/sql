select NAME, DISPLAY_VALUE from v$parameter where ISDEFAULT='FALSE' order by name;
exit