prompt <h2>Database supplemental logging </h2>
SELECT 
	supplemental_log_data_min data_min, 
	supplemental_log_data_pk data_pk, 
	supplemental_log_data_ui data_ui, 
	supplemental_log_data_fk data_fk, 
	supplemental_log_data_all data_all, 
	supplemental_log_data_pl data_pl
FROM v$database;
exit
