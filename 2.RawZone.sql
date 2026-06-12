use role sysadmin;
use warehouse compute_wh;
use schema cricket.raw;

-- lets create a table inside the raw layer
create or replace transient table cricket.raw.match_raw_tbl (
    meta object not null,
    info variant not null,
    innings ARRAY not null,
    stg_file_name text not null,
    stg_file_row_number int not null,
    stg_file_hashkey text not null,
    stg_modified_ts timestamp not null
)
comment = 'This is raw table to store all the json data file with root elements extracted'
;


-- we have total 2411 JSON files.--   STAGE >>> RAW Layer
copy into cricket.raw.match_raw_tbl from 
    (
    select 
        t.$1:meta::object as meta, 
        t.$1:info::variant as info, 
        t.$1:innings::array as innings, 
        --
        metadata$filename,
        metadata$file_row_number,
        metadata$file_content_key,
        metadata$file_last_modified
    from @cricket.land.my_stg/cricket/json (file_format => 'cricket.land.my_json_format') t
    )
    on_error = continue;

-- lets execute the count 
select count(*) from cricket.raw.match_raw_tbl; 

-- Go to COPY History (in Tables) -- Copy History BAR Chart
    -- tells Bar for Failed and Success
    -- Apply Failed Status Filter -- see File name

    -- Solution 1:- Remove and Reload
    -- Go to Stage(Land) >> Search that Errorenous File >>> Remove (...)
    -- reload it w Snowsight / SNOWSQL
    -- Rerun COPY INTO Again


    -- Solution 2
    -- Use OVERWRITE Option in PUT COMMAND in SNOWSQL.
    -- Rerun COPY INTO Again

-- lets run top 10 records.
select * from cricket.raw.match_raw_tbl limit 10;
