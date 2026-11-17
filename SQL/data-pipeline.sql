CREATE OR REPLACE STREAM cricket.raw.for_match_stream ON TABLE cricket.raw.match_raw_table APPEND_ONLY=TRUE;
CREATE OR REPLACE STREAM cricket.raw.for_player_stream ON TABLE cricket.raw.match_raw_table APPEND_ONLY=TRUE;
CREATE OR REPLACE STREAM cricket.raw.for_delivery_stream ON TABLE cricket.raw.match_raw_table APPEND_ONLY=TRUE;

-- Creating a task that runs every 5 min to load json data into raw layer.
CREATE OR REPLACE TASK cricket.raw.load_json_to_raw
WAREHOUSE='COMPUTE_WH'
SCHEDULE='5 minute'
AS COPY INTO cricket.raw.match_raw_table FROM(
SELECT t.$1:meta::object AS meta,
t.$1:info::VARIANT AS info,
t.$1:innings::ARRAY AS innings,

METADATA$FILENAME,
METADATA$FILE_ROW_NUMBER,
METADATA$FILE_CONTENT_KEY,
METADATA$FILE_LAST_MODIFIED

FROM @cricket.land.my_stage/cricket/json (FILE_FORMAT=>'cricket.land.my_json_format') t
)
ON_ERROR=CONTINUE;

CREATE OR REPLACE TASK cricket.raw.load_to_clean_match
WAREHOUSE='COMPUTE_WH'
AFTER cricket.raw.load_json_to_raw
WHEN SYSTEM$STREAM_HAS_DATA('cricket.raw.for_match_stream')
AS INSERT INTO cricket.clean.match_detail_clean
SELECT 
info:match_type_number::INT AS match_type_number,
info:event.name::TEXT AS event_name,
CASE 
WHEN 
info:event.match_number::TEXT IS NOT NULL THEN info:event.match_number::TEXT
WHEN 
info:event.stage::TEXT IS NOT NULL THEN info:event.stage::TEXT
ELSE 'NA'
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
stg_modified_ts 
FROM cricket.raw.for_match_stream;

-- Creating a child task after match data is populated
CREATE OR REPLACE TASK cricket.raw.load_to_clean_player
WAREHOUSE='COMPUTE_WH'
AFTER cricket.raw.load_to_clean_match
WHEN SYSTEM$STREAM_HAS_DATA('cricket.raw.for_player_stream')
AS INSERT INTO cricket.clean.player_clean_table
SELECT 
r.info:match_type_number::INT AS match_type_number,
p.path::TEXT AS country,
team.value::TEXT AS player_name,
stg_file_name,
stg_file_row_number,
stg_file_hashkey,
stg_modified_ts
FROM cricket.raw.for_player_stream r, 
LATERAL FLATTEN(INPUT=>r.info:players) p,
LATERAL FLATTEN(INPUT=>p.value) team;

-- Creating delivery clean table
CREATE OR REPLACE TASK cricket.raw.load_to_clean_delivery
WAREHOUSE='COMPUTE_WH'
AFTER cricket.raw.load_to_clean_player
WHEN SYSTEM$STREAM_HAS_DATA('cricket.raw.for_delivery_stream')
AS 
INSERT INTO cricket.clean.delivery_clean_table
SELECT 
m.info:match_type_number::INT AS match_type_number,
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
m.stg_file_name,
m.stg_file_row_number,
m.stg_file_hashkey,
m.stg_modified_ts
FROM cricket.raw.for_delivery_stream m,
LATERAL FLATTEN(INPUT=>m.innings) i,
LATERAL FLATTEN(INPUT=>i.value:overs) o,
LATERAL FLATTEN(INPUT=>o.value:deliveries) d,
LATERAL FLATTEN(INPUT=>d.value:extras,outer=>True) e,
LATERAL FLATTEN(INPUT=>d.value:wickets,outer=>True) w;

CREATE OR REPLACE TASK cricket.raw.load_to_team_dim
WAREHOUSE='COMPUTE_WH'
AFTER cricket.raw.load_to_clean_delivery 
AS INSERT INTO cricket.consumption.team_dim(team_name)(
SELECT DISTINCT team_name FROM(
SELECT first_team AS team_name FROM cricket.clean.match_detail_clean 
UNION ALL 
SELECT second_team AS team_name FROM cricket.clean.match_detail_clean
) 
MINUS
SELECT team_name FROM cricket.consumption.team_dim
);

CREATE OR REPLACE TASK cricket.raw.load_to_player_dim
WAREHOUSE='COMPUTE_WH'
AFTER cricket.raw.load_to_clean_delivery 
AS INSERT INTO cricket.consumption.player_dim (team_id,player_name)
SELECT b.team_id,a.player_name 
FROM cricket.clean.player_clean_table a JOIN cricket.consumption.team_dim b 
ON a.country=b.team_name
GROUP BY b.team_id,a.player_name
MINUS SELECT team_id,player_name FROM cricket.consumption.player_dim;

CREATE OR REPLACE TASK cricket.raw.load_to_venue_dim
WAREHOUSE='COMPUTE_WH'
AFTER cricket.raw.load_to_clean_delivery
AS 
INSERT INTO cricket.consumption.venue_dim(venue_name,city)
SELECT venue,city FROM(
SELECT
venue,
CASE WHEN city IS NULL THEN 'NA'
ELSE city 
END AS city
FROM cricket.clean.match_detail_clean
)
GROUP BY venue,city
MINUS SELECT venue_name,city FROM cricket.consumption.venue_dim;

CREATE OR REPLACE TASK cricket.raw.load_match_fact
WAREHOUSE='COMPUTE_WH'
AFTER cricket.raw.load_to_team_dim,cricket.raw.load_to_player_dim,cricket.raw.load_to_venue_dim
AS INSERT INTO cricket.consumption.match_fact 
SELECT a.* FROM (
SELECT 
m.match_type_number AS match_id,
dt.date_id AS date_id,
0 AS referee_id,
ft.team_id AS first_team_id,
st.team_id AS second_team_id,
mt.match_type_id AS match_type_id,
v.venue_id AS venue_id,
50 AS total_overs,
6 AS balls_per_over,
MAX(CASE WHEN d.team_name=m.first_team THEN d.over ELSE 0 END) AS overs_played_by_team_a,
SUM(CASE WHEN d.team_name=m.first_team THEN 1 ELSE 0 END) AS balls_played_by_team_a,
SUM(CASE WHEN d.team_name=m.first_team THEN d.extras ELSE 0 END) AS extra_balls_played_by_team_a,
SUM(CASE WHEN d.team_name=m.first_team THEN d.extra_runs ELSE 0 END) AS extra_runs_scored_by_team_a,
0 fours_by_team_a,
0 sixes_by_team_a,
(SUM(CASE WHEN d.team_name=m.first_team THEN d.runs ELSE 0 END)+SUM(CASE WHEN d.team_name=m.first_team THEN d.extra_runs ELSE 0 END)) AS total_runs_scored_by_team_a,
SUM(CASE WHEN d.team_name=m.first_team AND player_out IS NOT NULL THEN 1 ELSE 0 END) AS wicket_lost_by_team_a,

MAX(CASE WHEN d.team_name=m.second_team THEN d.over ELSE 0 END) AS overs_played_by_team_b,
SUM(CASE WHEN d.team_name=m.second_team THEN 1 ELSE 0 END) AS balls_played_by_team_b,
SUM(CASE WHEN d.team_name=m.second_team THEN d.extras ELSE 0 END) AS extra_balls_played_by_team_b,
SUM(CASE WHEN d.team_name=m.second_team THEN d.extra_runs ELSE 0 END) AS extra_runs_scored_by_team_b,
0 fours_by_team_b,
0 sixes_by_team_b,
(SUM(CASE WHEN d.team_name=m.second_team THEN d.runs ELSE 0 END)+SUM(CASE WHEN d.team_name=m.second_team THEN d.extra_runs ELSE 0 END)) AS total_runs_scored_by_team_b,
SUM(CASE WHEN d.team_name=m.second_team AND player_out IS NOT NULL THEN 1 ELSE 0 END) AS wicket_lost_by_team_b,
tw.team_id AS toss_winner_id,
m.toss_decision AS toss_decision,
m.match_result AS match_result,
mw.team_id AS winner_team_id 
) a
LEFT JOIN cricket.consumption.match_fact b ON a.match_id=b.match_id
WHERE b.match_id IS NULL;

CREATE OR REPLACE TASK cricket.raw.load_delivery_fact
WAREHOUSE='COMPUTE_WH'
AFTER cricket.raw.load_match_fact
AS 
INSERT INTO cricket.consumption.delivery_fact
SELECT a.* FROM(
SELECT 
d.match_type_number AS match_id,
t.team_id,
b.player_id AS bowler_id,
s.player_id AS batter_id,
ns.player_id AS non_striker_id,
d.over,
d.runs,
CASE WHEN d.extra_runs IS NULL THEN 0 ELSE d.extra_runs END AS extra_runs,
CASE WHEN d.extra_type IS NULL THEN 'None' ELSE d.extra_type END AS extra_type,
CASE WHEN d.player_out IS NULL THEN 'None' ELSE d.player_out END AS player_out,
CASE WHEN d.player_out_kind IS NULL THEN 'None' ELSE d.player_out_kind END AS player_out_kind
FROM cricket.clean.delivery_clean_table d 
JOIN team_dim t ON d.team_name=t.TEAM_NAME 
JOIN player_dim b ON d.bowler=b.player_name 
JOIN player_dim s ON d.batter=s.player_name 
JOIN player_dim ns ON d.non_striker=ns.player_name
) a 
LEFT JOIN cricket.consumption.delivery_fact b ON a.match_id=b.match_id
WHERE b.match_id IS NOT NULL;

