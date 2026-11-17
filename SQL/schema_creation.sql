USE ROLE SYSADMIN;
USE WAREHOUSE COMPUTE_WH;

-- Let's create a database named cricket and 4 schemas
CREATE DATABASE IF NOT EXISTS cricket;

CREATE OR REPLACE SCHEMA cricket.land;
CREATE OR REPLACE SCHEMA cricket.raw;
CREATE OR REPLACE SCHEMA cricket.clean;
CREATE OR REPLACE SCHEMA cricket.consumption;

SHOW SCHEMAS IN DATABASE cricket;

USE SCHEMA cricket.land;

-- JSON file format
CREATE OR REPLACE FILE FORMAT cricket.land.my_json_format
TYPE=JSON
NULL_IF=('\\n','NULL','')
STRIP_OUTER_ARRAY=TRUE
COMMENT='Json file format with outer strip array flag true'

-- Creating an internal stage
CREATE OR REPLACE STAGE cricket.land.my_stage;

-- Let's list the internal stage
LIST @cricket.land.my_stage;

-- Check if data is being loaded or not
LIST @my_stage/cricket/json;

SELECT 
t.$1:meta::VARIANT AS meta,
t.$1:info::VARIANT AS info,
t.$1:innings::VARIANT AS innings,
METADATA$FILENAME AS file_name,
METADATA$FILE_ROW_NUMBER AS row_number,
METADATA$FILE_CONTENT_KEY AS file_content_key,
METADATA$FILE_LAST_MODIFIED AS last_modified_ts
FROM @my_stage/cricket/json/1383539.json (FILE_FORMAT => 'my_json_format') t;
