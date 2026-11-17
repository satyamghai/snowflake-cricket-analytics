USE ROLE SYSADMIN;
USE WAREHOUSE COMPUTE_WH;
USE SCHEMA cricket.clean;

SELECT 
info:match_type_number::INT AS match_type_number,
info:players,
info:teams
FROM cricket.raw.match_raw_table;

SELECT 
info:match_type_number::INT AS match_type_number,
info:players,
info:teams
FROM cricket.raw.match_raw_table
WHERE match_type_number=4630;

SELECT 
info:match_type_number::INT AS match_type_number,
p.*,
--p.key::TEXT AS country
FROM cricket.raw.match_raw_table,
LATERAL FLATTEN (INPUT=>info:players) p 
WHERE match_type_number=4630;

SELECT
info:match_type_number::INT AS match_type_number,
--p.*
p.key::TEXT AS country
FROM cricket.raw.match_raw_table,
LATERAL FLATTEN (INPUT=>info:players) p
WHERE match_type_number=4630;

SELECT 
info:match_type_number::INT AS match_type_number,
p.key::TEXT AS country,
team.*
--team.value::TEXT AS player_name
FROM cricket.raw.match_raw_table,
LATERAL FLATTEN (INPUT=> info:players) p,
LATERAL FLATTEN (INPUT=> p.value) team
WHERE match_type_number=4630;

SELECT 
info:match_type_number::INT AS match_type_number,
p.key::TEXT AS country,
--team.*
team.value::TEXT AS player_name
FROM cricket.raw.match_raw_table,
LATERAL FLATTEN (INPUT=> info:players) p,
LATERAL FLATTEN (INPUT=>p.value) team 
WHERE match_type_number=4630;

--CREATE TABLE FOR PLAYER
CREATE OR REPLACE TABLE cricket.clean.player_clean_table AS 
SELECT 
info:match_type_number::INT AS match_type_number,
p.key::TEXT AS country,
team.value::TEXT AS player_name,
stg_file_name,
stg_file_row_number,
stg_file_hashkey,
stg_modified_ts
FROM cricket.raw.match_raw_table,
LATERAL FLATTEN(INPUT=>info:players) p,
LATERAL FLATTEN(INPUT=>p.value) TEAM;

--Let's describe the table
DESCRIBE TABLE cricket.clean.player_clean_table;

