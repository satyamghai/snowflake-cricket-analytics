USE ROLE SYSADMIN;
USE WAREHOUSE COMPUTE_WH;
USE SCHEMA cricket.consumption;

-- Let's populate delivery fact table
SELECT * FROM cricket.clean.delivery_clean_table
WHERE match_type_number=4631;

SELECT d.match_type_number AS match_id,
t.team_id,t.team_name 
FROM cricket.clean.delivery_clean_table d 
JOIN team_dim t 
ON d.team_name=t.team_name
WHERE d.match_type_number=4631;

SELECT 
d.match_type_number AS match_id,
t.team_id,t.team_name,
b.player_id AS bowler_id,b.player_name,
s.player_id AS batter_id,s.player_name,
ns.player_id AS non_striker_id,ns.player_name
FROM cricket.clean.delivery_clean_table d 
JOIN team_dim t ON d.team_name=t.team_name 
JOIN player_dim b ON d.bowler=b.player_name
JOIN player_dim s ON d.batter=s.player_name
JOIN player_dim ns ON d.non_striker=ns.player_name 
WHERE d.match_type_number=4631;

-- Add measurements
SELECT d.match_type_number AS match_id,
t.team_id,t.team_name,
b.player_id AS bowler_id,b.player_name AS bowler,
s.player_id AS batter_id,s.player_name AS striker,
s.player_id AS non_striker_id,s.player_name AS non_striker,
d.over,
d.runs,
d.extra_runs,
d.extra_type
FROM cricket.clean.delivery_clean_table d 
JOIN team_dim t ON d.team_name=t.team_name
JOIN player_dim b ON d.bowler=b.player_name
JOIN player_dim s ON d.batter=s.player_name  
JOIN player_dim ns ON d.non_striker=ns.player_name 
WHERE d.match_type_number=4631;

-- Remove unwanted columns
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
JOIN team_dim t ON d.team_name=t.team_name 
JOIN player_dim b ON d.bowler=b.player_name 
JOIN player_dim s ON d.batter=s.player_name 
JOIN player_dim ns ON d.non_striker=ns.player_name 
WHERE d.match_type_number=4631;

CREATE OR REPLACE TABLE delivery_fact(
match_id INT,
team_id INT,
bowler_id INT,
batter_id INT,
non_striker_id INT,
over INT,
runs INT,
extra_runs INT,
extra_type VARCHAR(255),
player_out VARCHAR(255),
player_out_kind VARCHAR(255),

CONSTRAINT fk_del_match_id FOREIGN KEY (match_id) REFERENCES match_fact(match_id),
CONSTRAINT fk_del_team FOREIGN KEY (team_id) REFERENCES team_dim(team_id),
CONSTRAINT fk_bowler FOREIGN KEY (bowler_id) REFERENCES player_dim(player_id),
CONSTRAINT fk_batter FOREIGN KEY (batter_id) REFERENCES player_dim(player_id),
CONSTRAINT fk_non_striker FOREIGN KEY (non_striker_id) REFERENCES player_dim(player_id)
);

INSERT INTO delivery_fact 
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
JOIN player_dim ns ON d.non_striker=ns.player_name;
