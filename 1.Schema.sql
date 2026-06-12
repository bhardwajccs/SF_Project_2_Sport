use role sysadmin;

use warehouse compute_wh;

create database cricket;
create schema land;
create schema raw;
create schema clean;
create schema consumption;

show schemas in database cricket;

use schema cricket.land;

-- Stage & File Format 

-- json file format
create or replace file format my_json_format
 type = json
 null_if = ('\\n', 'null', '')
    strip_outer_array = true
    comment = 'Json File Format with outer stip array flag true'; 

-- creating an internal stage
create or replace stage my_stg; 

-- lets list the internal stage
list @my_stg;

-- Load 5-6 Files w Snowsight UI

-- check if data is being loaded or not
list @my_stg/cricket/json/;

-- quick check if data is coming correctly or not
select 
        t.$1:meta::variant as meta, 
        t.$1:info::variant as info, 
        t.$1:innings::array as innings, 
        metadata$filename as file_name,
        metadata$file_row_number int,
        metadata$file_content_key text,
        metadata$file_last_modified stg_modified_ts
     from  @my_stg/cricket/json/1384402.json (file_format => 'my_json_format') t;

-- Since lots of Files -- Drop Last Loaded 5-6 Files
-- SNOQSQL CLI -- Good for Loading Big data fatser -- Limit of 50 MB in Snowsight UI.

REMOVE  @my_stg/cricket/json/;

-- SNOWSQL Command
put 'file://C:/Users/lbhardwaj/OneDrive - California Creative Solutions, Inc/Data_Ba
                                   ckup_Cloud_Lalit/Lalit BI/Lalit Business Intelligence CCS/SnowFlake/2023-world-cup-j
                                   son/*.json' @my_stg/cricket/json/ parallel = 50;

list @my_stg/cricket/json/;

