prompt <h2>Failed scheduled jobs </h2>
SELECT owner, job_name, job_type, state, TRUNC(start_date) SDATE, TRUNC(next_run_date) NXTRUN, failure_count
FROM dba_scheduler_jobs
WHERE failure_count <> 0;
exit


