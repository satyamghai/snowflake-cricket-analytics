USE ROLE SYSADMIN;
USE WAREHOUSE COMPUTE_WH;
USE SCHEMA cricket.clean;

-- Step-1 
SELECT
meta['data_version']::TEXT AS data_version,
meta['created']::DATE AS created,
meta['revision']::NUMBER AS revision
FROM cricket.raw.match_raw_table;

SELECT 
info:match_type_number::INT AS match_type_number,
info:match_type::TEXT AS match_type,
info:season::TEXT AS season,
info:team_type::TEXT AS team_type,
info:overs::TEXT AS overs,
info:city::TEXT AS city,
info:venue::TEXT AS venue
FROM cricket.raw.match_raw_table;

CREATE OR REPLACE TRANSIENT TABLE cricket.clean.match_detail_clean AS
SELECT 
info:match_type_number::INT AS match_type_number,
info:event.name::TEXT AS event_name,
CASE 
WHEN 
info:event.match_number::TEXT IS NOT NULL THEN info:event.match_number::TEXT
WHEN 
info:event.stage::TEXT IS NOT NULL THEN info:event.stage::TEXT 
ELSE 
'NA'
END AS match_stage,
info:dates[0]::DATE AS event_date,
DATE_PART('YEAR',info:dates[0]::DATE) AS event_year,
DATE_PART('MONTH',info:dates[0]::DATE) AS event_month,
DATE_PART('DAY',info:dates[0]::DATE) AS event_day,
info:match_type::TEXT AS match_type,
info:season::TEXT AS season,
info:team_type::TEXT AS team_type,
info:overs::TEXT AS overs,
info:city::TEXT AS city,
info:venue::TEXT AS venue,
info:gender::TEXT AS gender,
info:teams[0]::TEXT AS first_team,
info:teams[1]::TEXT AS second_team,
CASE 
WHEN info:outcome.winner IS NOT NULL THEN 'Result Declared'
WHEN info:outcome.result='tie' THEN 'Tie'
WHEN info:outcome.result='no result' THEN 'No Result'
ELSE info:outcome.result
END AS match_result,
CASE 
WHEN info:outcome.winner IS NOT NULL THEN info:outcome.winner
ELSE 'NA'
END AS winner,
info:toss.winner::TEXT AS toss_winner,
INITCAP(info:toss.decision::TEXT) AS toss_decision,
stg_file_name,
stg_file_row_number,
stg_file_hashkey,
stg_modified_ts
FROM cricket.raw.match_raw_table;

SELECT * FROM cricket.clean.match_detail_clean;



