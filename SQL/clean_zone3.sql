USE ROLE SYSADMIN;
USE WAREHOUSE COMPUTE_WH;
USE SCHEMA cricket.clean;

-- Let's extract the elements from the innings array
SELECT
info:match_type_number::INT AS match_type_number,
innings
FROM cricket.raw.match_raw_table
WHERE match_type_number=4630;

SELECT 
info:match_type_number::INT AS match_type_number,
i.*
FROM cricket.raw.match_raw_table,
LATERAL FLATTEN (INPUT=>innings) i 
WHERE match_type_number=4631;

SELECT 
info:match_type_number::INT AS match_type_number,
i.value:team::TEXT AS team_name,
o.*
FROM cricket.raw.match_raw_table,
LATERAL FLATTEN (INPUT=>innings) i,
LATERAL FLATTEN (INPUT=>i.value:overs) o
WHERE match_type_number=4631;

SELECT 
info:match_type_number::INT AS match_type_number,
i.value:team::TEXT AS team_name,
o.value:over::INT+1 AS over,
d.value:bowler::TEXT AS bowler,
d.value:batter::TEXT AS batter,
d.value:non_striker::TEXT AS non_striker,
d.value:runs.batter::TEXT AS runs, 
d.value:runs.extras::TEXT AS extras,
d.value:runs.total::TEXT AS total,
e.key::TEXT AS extra_type,
e.value::NUMBER AS extra_runs
FROM cricket.raw.match_raw_table,
LATERAL FLATTEN(INPUT=>innings) i,
LATERAL FLATTEN(INPUT=>i.value:overs) o,
LATERAL FLATTEN(INPUT=>o.value:deliveries) d,
LATERAL FLATTEN(INPUT=>d.value:extras,OUTER=>TRUE) e
WHERE match_type_number=4631;

SELECT 
info:match_type_number::INT AS match_type_number,
i.value:team::TEXT AS team_name,
o.value:over::INT+1 AS over,
d.value:bowler::TEXT AS bowler,
d.value:batter::TEXT AS batter,
d.value:non_striker::TEXT AS non_striker,
d.value:runs.batter::TEXT AS runs,
d.value:runs.extras::TEXT AS extras,
d.value:runs.total::TEXT AS total,
e.key::TEXT AS extra_type,
e.value::NUMBER AS extra_runs,
w.value:player_out::TEXT AS player_out,
w.value:kind::TEXT AS player_out_kind,
w.value:fielders::VARIANT AS player_out_fielders
FROM cricket.raw.match_raw_table,
LATERAL FLATTEN (INPUT=>innings) i,
LATERAL FLATTEN (INPUT=>i.value:overs) o,
LATERAL FLATTEN (INPUT=>o.value:deliveries) d,
LATERAL FLATTEN (INPUT=>d.value:extras,outer=>True) e,
LATERAL FLATTEN (INPUT=>d.value:wickets,outer=>True) w 
WHERE match_type_number=4631;

CREATE OR REPLACE TRANSIENT TABLE cricket.clean.delivery_clean_table AS 
SELECT 
info:match_type_number::INT AS match_type_number,
i.value:team::TEXT AS team_name,
o.value:over::INT+1 AS over,
d.value:bowler::TEXT AS bowler,
d.value:batter::TEXT AS batter,
d.value:non_striker::TEXT AS non_striker,
d.value:runs.batter::TEXT AS runs,
d.value:runs.extras::TEXT AS extras,
d.value:runs.total::TEXT AS total,
e.key::TEXT AS extra_type,
e.value::NUMBER AS extra_runs,
w.value:player_out::TEXT AS player_out,
w.value:kind::TEXT AS player_out_kind,
w.value:fielders::VARIANT AS player_out_fielders,
stg_file_name,
stg_file_row_number,
stg_file_hashkey,
stg_modified_ts
FROM cricket.raw.match_raw_table,
LATERAL FLATTEN (INPUT=>innings) i,
LATERAL FLATTEN (INPUT=>i.value:overs) o,
LATERAL FLATTEN (INPUT=>o.value:deliveries) d,
LATERAL FLATTEN (INPUT=>d.value:extras,outer=>True) e,
LATERAL FLATTEN (INPUT=>d.value:wickets,outer=>True) w;

SELECT DISTINCT match_type_number 
FROM cricket.clean.delivery_clean_table;
