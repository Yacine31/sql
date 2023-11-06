prompt <h2>Database supplemental logging </h2>
SELECT supplemental_log_data_min, supplemental_log_data_pk, supplemental_log_data_ui, supplemental_log_data_fk, supplemental_log_data_all, supplemental_log_data_pl
FROM v$database;
exit
