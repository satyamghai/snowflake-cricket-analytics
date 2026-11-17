USE ROLE SYSADMIN;
USE WAREHOUSE COMPUTE_WH;
USE SCHEMA cricket.consumption;

CREATE OR REPLACE TABLE date_dim(
date_id INT PRIMARY KEY AUTOINCREMENT,
full_dt DATE,
day INT,
month INT,
year INT,
quarter INT,
dayofweek INT,
dayofmonth INT,
dayofyear INT,
dayofweekname VARCHAR(3), -- to store day names (eg:"Mon")
isweekend BOOLEAN -- to indicate if it's a weekend (Sat/Sun both falls under weekend)
);

-- match_referees,reserve_umpires,tv_umpires,field_umpires
CREATE OR REPLACE table referee_dim(
referee_id INT PRIMARY KEY AUTOINCREMENT,
referee_name TEXT NOT NULL,
referee_type TEXT NOT NULL
);

-- Ind,Aus etc.
CREATE OR REPLACE TABLE team_dim(
team_id INT PRIMARY KEY AUTOINCREMENT,
team_name TEXT NOT NULL
)

--Player
CREATE OR REPLACE TABLE player_dim(
player_id INT PRIMARY KEY AUTOINCREMENT,
team_id INT NOT NULL,
player_name TEXT NOT NULL
);

ALTER TABLE cricket.consumption.player_dim
ADD CONSTRAINT fk_team_player_id 
FOREIGN KEY (team_id)
REFERENCES cricket.consumption.team_dim (team_id);

CREATE OR REPLACE TABLE venue_dim(
venue_id INT PRIMARY KEY AUTOINCREMENT,
venue_name TEXT NOT NULL,
city TEXT NOT NULL,
state TEXT,
country TEXT,
continent TEXT,
end_names TEXT,
capacity NUMBER,
pitch TEXT,
flood_light BOOLEAN,
established_dt DATE,
playing_area TEXT,
other_sports TEXT,
curator TEXT,
LATITUDE NUMBER(10,6),
LONGITUDE NUMBER(10,6)
);

CREATE OR REPLACE TABLE match_type_dim(
match_type_id INT PRIMARY KEY AUTOINCREMENT,
match_type TEXT NOT NULL
);

CREATE OR REPLACE TABLE match_fact(
match_id INT PRIMARY KEY AUTOINCREMENT,
date_id INT NOT NULL,
referee_id INT NOT NULL,
team_a_id INT NOT NULL,
team_b_id INT NOT NULL,
match_type_id INT NOT NULL,
venue_id INT NOT NULL,
total_overs NUMBER(3),
bowls_per_over NUMBER(1),

overs_played_by_team_a NUMBER(2),
balls_played_by_team_a NUMBER(3),
extra_balls_played_by_team_a NUMBER(3),
extra_runs_scored_by_team_a NUMBER(3),
fours_by_team_a NUMBER(3),
sixes_by_team_a NUMBER(3),
total_score_by_team_a NUMBER(3),
wicket_lost_by_team_a NUMBER(2),

overs_played_by_team_b NUMBER(2),
balls_played_by_team_b NUMBER(3),
extra_balls_played_by_team_b NUMBER(3),
extra_runs_scored_by_team_b NUMBER(3),
fours_by_team_b NUMBER(3),
sixes_by_team_b NUMBER(3),
total_score_by_team_b NUMBER(3),
wicket_lost_by_team_b NUMBER(2),

toss_winner_team_id INT NOT NULL,
toss_decision TEXT NOT NULL,
match_result TEXT NOT NULL,
winner_team_id INT NOT NULL,

CONSTRAINT fk_date FOREIGN KEY (date_id) REFERENCES date_dim(date_id),
CONSTRAINT fk_referee FOREIGN KEY (referee_id) REFERENCES referee_dim(referee_id),
CONSTRAINT fk_team1 FOREIGN KEY (team_a_id) REFERENCES team_dim(team_id),
CONSTRAINT fk_team2 FOREIGN KEY (team_b_id) REFERENCES team_dim(team_id),
CONSTRAINT fk_match_type FOREIGN KEY (match_type_id) REFERENCES match_type_dim(match_type_id),
CONSTRAINT fk_venue FOREIGN KEY (venue_id) REFERENCES venue_dim(venue_id),

CONSTRAINT fk_toss_winner_team FOREIGN KEY (toss_winner_team_id) REFERENCES team_dim (team_id),
CONSTRAINT fk_winner_team FOREIGN KEY (winner_team_id) REFERENCES team_dim (team_id) 
);

-- Let's start with team dim, and for simplicity, it is just team name
SELECT DISTINCT team_name FROM(
SELECT first_team AS team_name FROM cricket.clean.match_detail_clean 
UNION ALL 
SELECT second_team AS team_name FROM cricket.clean.match_detail_clean
) ;

INSERT INTO cricket.consumption.team_dim (team_name)
SELECT DISTINCT team_name FROM(
SELECT first_team AS team_name FROM cricket.clean.match_detail_clean 
UNION ALL 
SELECT second_team AS team_name FROM cricket.clean.match_detail_clean
) ORDER BY team_name;

SELECT * FROM cricket.consumption.team_dim ORDER BY team_name;

-- Team player
SELECT * FROM cricket.clean.player_clean_table LIMIT 10;

SELECT country,player_name FROM cricket.clean.player_clean_table GROUP BY country,player_name;

SELECT a.country,b.team_id,a.player_name
FROM cricket.clean.player_clean_table a JOIN cricket.consumption.team_dim b 
ON a.country=b.team_name
GROUP BY a.country,b.team_id,a.player_name;

INSERT INTO cricket.consumption.player_dim (team_id,player_name)
SELECT b.team_id,a.player_name 
FROM cricket.clean.player_clean_table a JOIN cricket.consumption.team_dim b 
ON a.country=b.team_name
GROUP BY b.team_id,a.player_name;

SELECT * FROM cricket.consumption.player_dim;

-- Referee Dimension

-- Since we have not populated the referee detail in our previous layer.
-- WE will skip it for now.. We need to understand it well
-- Before we can design the refree

SELECT * FROM cricket.clean.match_detail_clean LIMIT 10;

SELECT info FROM cricket.raw.match_raw_table LIMIT 1;

SELECT 
info:officials.match_referees[0]::TEXT AS match_referee,
info:officials.reserve_umpires[0]::TEXT AS reserve_umpire,
info:officials.tv_umpires[0]::TEXT AS tv_umpire,
info:officials.umpires[0]::TEXT AS first_umpire,
info:officials.umpires[1]::TEXT AS second_umpire
FROM 
cricket.raw.match_raw_table LIMIT 1;

-- Venue Dimension
SELECT * FROM cricket.clean.match_detail_clean LIMIT 10;

SELECT venue,city FROM cricket.clean.match_detail_clean LIMIT 10

SELECT 
venue,
city 
FROM cricket.clean.match_detail_clean GROUP BY venue,city;

INSERT INTO cricket.consumption.venue_dim(venue_name,city)
SELECT venue,city FROM(
SELECT
venue,
CASE WHEN city IS NULL THEN 'NA'
ELSE city 
END AS city
FROM cricket.clean.match_detail_clean
)
GROUP BY venue,city;

-- Match Type Dimension

SELECT * FROM cricket.clean.match_detail_clean LIMIT 10;

SELECT match_type FROM cricket.clean.match_detail_clean GROUP BY match_type;

INSERT INTO cricket.consumption.match_type_dim (match_type)
SELECT match_type FROM cricket.clean.match_detail_clean
WHERE match_type IS NOT NULL
GROUP BY match_type;

SELECT MIN(event_date),MAX(event_date) FROM cricket.clean.match_detail_clean;

CREATE OR REPLACE TRANSIENT TABLE cricket.consumption.date_range01 (Date DATE);

INSERT INTO cricket.consumption.date_range01 
SELECT DATEADD(DAY,SEQ4(),'2023-07-10'::DATE) 
FROM TABLE(GENERATOR(ROWCOUNT=>124));

INSERT INTO cricket.consumption.date_dim (date_id,full_dt,day,month,year,quarter,dayofweek,dayofmonth,dayofyear,dayofweekname,isweekend)
SELECT 
ROW_NUMBER() OVER (ORDER BY DATE) AS DateID,
Date AS FullDate,
EXTRACT(DAY FROM Date) AS Day,
EXTRACT(MONTH FROM Date) AS Month,
EXTRACT(YEAR FROM Date) AS Year,
CASE WHEN EXTRACT(Quarter FROM Date) IN (1,2,3,4) THEN EXTRACT(Quarter FROM Date) END AS Quarter,
DAYOFWEEKISO(Date) AS DayOfWeek,
EXTRACT(DAY FROM Date) AS DayOfMonth,
DAYOFYEAR(Date) AS DayOfYear,
DAYNAME(Date) AS DayOfWeekName,
CASE WHEN DAYNAME(Date) IN ('Sat','Sun') THEN 1 ELSE 0 END AS IsWeekend
FROM cricket.consumption.date_range01;