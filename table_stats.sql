REM NAME:    TFSTBLST.SQL
REM USAGE:"@path/tfstblst"
REM ------------------------------------------------------------------------
REM REQUIREMENTS:
REM   SELECT on DBA_TABLES
REM ------------------------------------------------------------------------
REM PURPOSE:
REM    This script pulls the statistics for a table from DBA_TABLES and
REM    presents them in a formatted report.  It will only report correctly
REM    for tables which have been ANALYZEd.
REM ------------------------------------------------------------------------
REM Main text of script follows:

set echo off
set scan on
set lines 132
set pages 66
set verify off
set feedback off
prompt
accept owner prompt 'Please enter Name of Table Owner: '
accept table_name  prompt 'Please enter Table Name to show Statistics for: '
column TABLE_NAME heading "Table|Name" format a15
column NUM_ROWS heading "Number|of Rows" format 9,999,990
column BLOCKS heading "Blocks" format 999,990
column EMPTY_BLOCKS heading "Empty|Blocks" format 999,990
column AVG_SPACE heading "Average|Space" format 9,990
column CHAIN_CNT heading "Chain|Count" format 990
column AVG_ROW_LEN heading "Average|Row Len" format 990
column COLUMN_NAME  heading "Column|Name" format a25
column NULLABLE heading Null|able format a4
column NUM_DISTINCT heading "Distinct|Values" format 99,990
column DENSITY heading "Density" format 990
column INDEX_NAME heading "Index|Name" format a15
column UNIQUENESS heading "Unique" format a9
column BLEV heading "B|Tree|Level" format 90
column LEAF_BLOCKS heading "Leaf|Blks" format 99990
column DISTINCT_KEYS heading "Distinct|Keys" format 9,999,990
column AVG_LEAF_BLOCKS_PER_KEY heading "Average|Leaf Blocks|Per Key" format  99,990
column AVG_DATA_BLOCKS_PER_KEY heading "Average|Data Blocks|Per Key" format  99,990
column CLUSTERING_FACTOR heading "Cluster|Factor" format 999,990
column COLUMN_POSITION heading "Col|Pos" format 990
column col heading "Column|Details" format a24
column COLUMN_LENGTH heading "Col|Len" format 990
 select TABLE_NAME,
 NUM_ROWS,
 BLOCKS,
 EMPTY_BLOCKS,
 AVG_SPACE,
 CHAIN_CNT,
 AVG_ROW_LEN
from dba_tables
where owner = upper(nvl('&&Owner',user))
and table_name = upper('&&Table_name')
/
 select
 COLUMN_NAME,
decode(t.DATA_TYPE,
'NUMBER',t.DATA_TYPE||'('||
         decode(t.DATA_PRECISION,
                null,t.DATA_LENGTH||')',
                t.DATA_PRECISION||','||t.DATA_SCALE||')'),
'DATE',t.DATA_TYPE,
'LONG',t.DATA_TYPE,
'LONG RAW',t.DATA_TYPE,
'ROWID',t.DATA_TYPE,
'MLSLABEL',t.DATA_TYPE,
t.DATA_TYPE||'('||t.DATA_LENGTH||')') ||' '||
       decode(t.nullable,
              'N','NOT NULL',
              'n','NOT NULL',
        NULL) col,
 NUM_DISTINCT,
 DENSITY
from dba_tab_columns t
where table_name = upper('&Table_name')
and owner = upper(nvl('&Owner',user))
/
 select INDEX_NAME,
 UNIQUENESS,
 BLEVEL BLev,
 LEAF_BLOCKS,
 DISTINCT_KEYS,
 AVG_LEAF_BLOCKS_PER_KEY,
 AVG_DATA_BLOCKS_PER_KEY,
 CLUSTERING_FACTOR
from dba_indexes
where table_name = upper('&Table_name')
and table_owner = upper(nvl('&Owner',user))
/
break on index_name
select
i.INDEX_NAME,
i.COLUMN_NAME,
i.COLUMN_POSITION,
decode(t.DATA_TYPE,
'NUMBER',t.DATA_TYPE||'('||
         decode(t.DATA_PRECISION,
                null,t.DATA_LENGTH||')',
                t.DATA_PRECISION||','||t.DATA_SCALE||')'),
'DATE',t.DATA_TYPE,
'LONG',t.DATA_TYPE,
'LONG RAW',t.DATA_TYPE,
'ROWID',t.DATA_TYPE,
'MLSLABEL',t.DATA_TYPE,
t.DATA_TYPE||'('||t.DATA_LENGTH||')') ||' '||
       decode(t.nullable,
              'N','NOT NULL',
    'n','NOT NULL',
              NULL) col
from dba_ind_columns i,dba_tab_columns t
where i.table_name = upper('&Table_name')
and owner = upper(nvl('&Owner',user))
and i.table_name = t.table_name
and t.column_name = i.column_name
order by index_name,column_position
/
clear breaks
set echo on

