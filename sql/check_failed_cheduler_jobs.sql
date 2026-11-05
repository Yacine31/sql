set pages 999 lines 150
col job_name for a30
col owner for a20
SELECT owner, job_name, job_type, state, TRUNC(start_date) SDATE, TRUNC(next_run_date) NXTRUN, failure_count
FROM dba_scheduler_jobs
WHERE failure_count <> 0;

