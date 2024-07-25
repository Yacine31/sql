set pages 999 lines 200
col owner for a30

select * from
(select owner, object_type ,count(*) as object_count from dba_objects group by owner, object_type order by owner, object_type)
  pivot
  (
     max(object_count)
     for object_type in (
             'TABLE',
             'VIEW',
             'INDEX',
             'FUNCTION',
             'LOB',
             'PACKAGE',
             'PROCEDURE',
             'TRIGGER',
             'SYNONYM'
        )
  )
  order by owner
;
