USE ROLE SYSADMIN;
USE WAREHOUSE COMPUTE_WH;
USE SCHEMA cricket.consumption;

SELECT 
m.match_type_number AS match_id,
d.date_id,
0 AS referee_id
FROM cricket.clean.match_detail_clean m 
JOIN date_dim d 
ON m.event_date=d.full_dt
WHERE m.match_type_number=4631;

-- With team
SELECT 
m.match_type_number AS match_id,
d.date_id,
0 AS referee_id,
ft.team_id,
st.team_id 
FROM cricket.clean.match_detail_clean m 
JOIN date_dim d ON m.event_date=d.full_dt
JOIN team_dim ft ON m.first_team=ft.team_name
JOIN team_dim st ON m.second_team=st.team_name
WHERE m.match_type_number=4631;

-- With match_type
SELECT 
m.match_type_number AS match_id,
d.date_id,
0 AS referee_id,
ft.team_id,
st.team_id,
mt.match_type_id
FROM cricket.clean.match_detail_clean m 
JOIN date_dim d ON m.event_date=d.full_dt 
JOIN team_dim ft ON m.first_team=ft.team_name 
JOIN team_dim st ON m.second_team=st.team_name
JOIN match_type_dim mt ON m.match_type=mt.match_type
WHERE m.match_type_number=4631;

-- With venue
SELECT 
m.match_type_number AS match_id,
d.date_id,
0 AS referee_id,
ft.team_id,
st.team_id,
mt.match_type_id,
v.venue_id 
FROM cricket.clean.match_detail_clean m 
JOIN date_dim d ON m.event_date=d.full_dt
JOIN team_dim ft ON m.first_team=ft.team_name 
JOIN team_dim st ON m.second_team=st.team_name 
JOIN match_type_dim mt ON m.match_type=mt.match_type 
JOIN venue_dim v ON m.venue=v.venue_name 
WHERE m.match_type_number=4631;

-- Now we need to populate measure
SELECT m.match_type_number AS match_id,
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
MAX(CASE WHEN d.team_name=m.second_team THEN d.over ELSE 0 END) AS overs_played_by_team_b,
SUM(CASE WHEN d.team_name=m.second_team THEN 1 ELSE 0 END) AS balls_played_by_team_b,
SUM(CASE WHEN d.team_name=m.second_team THEN d.extras ELSE 0 END) AS extra_balls_played_by_team_b,
SUM(CASE WHEN d.team_name=m.second_team THEN d.extra_runs ELSE 0 END) AS extra_runs_scored_by_team_b,
0 fours_by_team_b,
0 sixes_by_team_b,
(SUM(CASE WHEN d.team_name=m.second_team THEN d.runs ELSE 0 END)+SUM(CASE WHEN d.team_name=m.second_team THEN d.extra_runs ELSE 0 END)) AS total_runs_scored_by_team_b 
FROM cricket.clean.match_detail_clean m 
JOIN date_dim dt ON m.event_date=dt.full_dt
JOIN team_dim ft ON m.first_team=ft.team_name 
JOIN team_dim st ON m.second_team=st.team_name
JOIN match_type_dim mt ON m.match_type=mt.match_type 
JOIN venue_dim v ON m.venue=v.venue_name 
JOIN cricket.clean.delivery_clean_table d ON d.match_type_number=m.match_type_number
WHERE m.match_type_number=4631
GROUP BY match_id,date_id,referee_id,first_team_id,second_team_id,match_type_id,venue_id;

SELECT m.match_type_number AS match_id,
dt.date_id AS date_id,
0 AS referee_id,
ft.team_id AS first_team_id,
st.team_id AS second_team_id,
mt.match_type_id AS match_type_id,
v.venue_id AS venue_id,
50 AS total_overs,
6 AS balls_per_over,
SUM(CASE WHEN d.team_name=m.first_team AND player_out IS NOT NULL THEN 1 ELSE 0 END) AS wicket_list_by_team_a,
SUM(CASE WHEN d.team_name=m.second_team AND player_out IS NOT NULL THEN 1 ELSE 0 END) AS wicket_list_by_team_b
FROM cricket.clean.match_detail_clean m 
JOIN date_dim dt ON m.event_date=dt.full_dt
JOIN team_dim ft ON m.first_team=ft.team_name
JOIN team_dim st ON m.second_team=st.team_name 
JOIN match_type_dim mt ON m.match_type=mt.match_type
JOIN venue_dim v ON m.venue=v.venue_name
JOIN cricket.clean.delivery_clean_table d ON d.match_type_number=m.match_type_number
WHERE m.match_type_number=4631 
GROUP BY match_id,date_id,referee_id,first_team_id,second_team_id,match_type_id,venue_id;

SELECT m.match_type_number AS match_id,
dt.date_id AS date_id,
0 AS referee_id,
ft.team_id AS first_team_id,
st.team_id AS second_team_id,
mt.match_type_id AS match_type_id,
v.venue_id AS venue_id,
50 AS total_overs,
6 AS balls_per_over,
m.toss_winner AS toss_winner,
m.toss_decision AS toss_decision
FROM cricket.clean.match_detail_clean m 
JOIN date_dim dt ON m.event_date=dt.full_dt
JOIN team_dim ft ON m.first_team=ft.team_name
JOIN team_dim st ON m.second_team=st.team_name 
JOIN match_type_dim mt ON m.match_type=mt.match_type
JOIN venue_dim v ON m.venue=v.venue_name
JOIN cricket.clean.delivery_clean_table d ON d.match_type_number=m.match_type_number
WHERE m.match_type_number=4631 
GROUP BY match_id,date_id,referee_id,first_team_id,second_team_id,match_type_id,venue_id,toss_winner,toss_decision;

INSERT INTO cricket.consumption.match_fact
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

FROM cricket.clean.match_detail_clean m 
JOIN date_dim dt ON m.event_date=dt.full_dt
JOIN team_dim ft ON m.first_team=ft.team_name
JOIN team_dim st ON m.second_team=st.team_name
JOIN match_type_dim mt ON m.match_type=mt.match_type
JOIN venue_dim v ON m.venue=v.venue_name 
JOIN cricket.clean.delivery_clean_table d ON d.match_type_number=m.match_type_number 
JOIN team_dim tw ON m.toss_winner=tw.team_name
JOIN team_dim mw ON m.winner=mw.team_name 

GROUP BY match_id,date_id,referee_id,first_team_id,second_team_id,match_type_id,venue_id,total_overs,toss_winner_id,toss_decision,match_result,winner_team_id;

DESC TABLE cricket.consumption.match_fact;

ALTER TABLE cricket.consumption.match_fact ALTER COLUMN balls_played_by_team_a SET DATA TYPE NUMBER(38,0);
ALTER TABLE cricket.consumption.match_fact ALTER COLUMN extra_balls_played_by_team_a SET DATA TYPE NUMBER(38,0);
ALTER TABLE cricket.consumption.match_fact ALTER COLUMN extra_runs_scored_by_team_a SET DATA TYPE NUMBER(38,0);
ALTER TABLE cricket.consumption.match_fact ALTER COLUMN fours_by_team_a SET DATA TYPE NUMBER(38,0);
ALTER TABLE cricket.consumption.match_fact ALTER COLUMN sixes_by_team_a SET DATA TYPE NUMBER(38,0);
ALTER TABLE cricket.consumption.match_fact ALTER COLUMN TOTAL_SCORE_BY_TEAM_A SET DATA TYPE NUMBER(38,0);
ALTER TABLE cricket.consumption.match_fact ALTER COLUMN wicket_lost_by_team_a SET DATA TYPE NUMBER(38,0);

ALTER TABLE cricket.consumption.match_fact ALTER COLUMN balls_played_by_team_b SET DATA TYPE NUMBER(38,0);
ALTER TABLE cricket.consumption.match_fact ALTER COLUMN extra_balls_played_by_team_b SET DATA TYPE NUMBER(38,0);
ALTER TABLE cricket.consumption.match_fact ALTER COLUMN extra_runs_scored_by_team_b SET DATA TYPE NUMBER(38,0);
ALTER TABLE cricket.consumption.match_fact ALTER COLUMN fours_by_team_b SET DATA TYPE NUMBER(38,0);
ALTER TABLE cricket.consumption.match_fact ALTER COLUMN sixes_by_team_b SET DATA TYPE NUMBER(38,0);
ALTER TABLE cricket.consumption.match_fact ALTER COLUMN TOTAL_SCORE_BY_TEAM_B SET DATA TYPE NUMBER(38,0);
ALTER TABLE cricket.consumption.match_fact ALTER COLUMN wicket_lost_by_team_b SET DATA TYPE NUMBER(38,0);

ALTER TABLE cricket.consumption.match_fact ALTER COLUMN overs_played_by_team_a SET DATA TYPE NUMBER(38,0);
ALTER TABLE cricket.consumption.match_fact ALTER COLUMN overs_played_by_team_b SET DATA TYPE NUMBER(38,0);

INSERT INTO cricket.consumption.match_fact
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

FROM cricket.clean.match_detail_clean m 
JOIN date_dim dt ON m.event_date=dt.full_dt
JOIN team_dim ft ON m.first_team=ft.team_name
JOIN team_dim st ON m.second_team=st.team_name
JOIN match_type_dim mt ON m.match_type=mt.match_type
JOIN venue_dim v ON m.venue=v.venue_name 
JOIN cricket.clean.delivery_clean_table d ON d.match_type_number=m.match_type_number 
JOIN team_dim tw ON m.toss_winner=tw.team_name
JOIN team_dim mw ON m.winner=mw.team_name 

GROUP BY match_id,date_id,referee_id,first_team_id,second_team_id,match_type_id,venue_id,total_overs,toss_winner_id,toss_decision,match_result,winner_team_id;

SELECT * FROM cricket.consumption.match_fact WHERE match_id=4631;



