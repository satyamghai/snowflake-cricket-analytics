USE ROLE SYSADMIN;
USE WAREHOUSE COMPUTE_WH;
USE SCHEMA cricket.clean;

--Let's quickly validate the dataset
-- Ind Vs SA (2023-Nov-05)
SELECT * FROM cricket.clean.match_detail_clean
WHERE match_type_number=4694;

--By batsman
SELECT 
team_name,
batter,
SUM(runs)
FROM delivery_clean_table
WHERE match_type_number=4694
GROUP BY team_name,batter
ORDER BY 1,2,3 DESC;

--By team
SELECT team_name,
SUM(runs)+SUM(extra_runs)
FROM delivery_clean_table
WHERE match_type_number=4694
GROUP BY team_name
ORDER BY 1,2 DESC;


