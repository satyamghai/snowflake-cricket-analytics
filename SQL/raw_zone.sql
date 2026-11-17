USE ROLE SYSADMIN;
USE WAREHOUSE COMPUTE_WH;
USE SCHEMA cricket.raw;

-- Let's create a table inside the raw layer
CREATE OR REPLACE TRANSIENT TABLE cricket.raw.match_raw_table(
meta OBJECT NOT NULL,
info VARIANT NOT NULL,
innings ARRAY NOT NULL,
stg_file_name TEXT NOT NULL,
stg_file_row_number INT NOT NULL,
stg_file_hashkey TEXT NOT NULL,
stg_modified_ts TIMESTAMP NOT NULL
)
COMMENT='This is raw table to store all the json data file with root elements extracted';

-- We have total 212 JSON files
COPY INTO cricket.raw.match_raw_table FROM(
SELECT 
t.$1:meta::OBJECT AS meta,
t.$1:info::VARIANT AS info,
t.$1:innings::ARRAY AS innings,
METADATA$FILENAME,
METADATA$FILE_ROW_NUMBER,
METADATA$FILE_CONTENT_KEY,
METADATA$FILE_LAST_MODIFIED
FROM @cricket.land.my_stage/cricket/json (FILE_FORMAT=>'cricket.land.my_json_format') t
)
ON_ERROR=CONTINUE;

-- Let's execute the count
SELECT COUNT(*) FROM cricket.raw.match_raw_table;

-- Let's run top 10 records
SELECT * FROM cricket.raw.match_raw_table LIMIT 10;