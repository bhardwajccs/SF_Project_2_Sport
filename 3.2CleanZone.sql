use role sysadmin;
use warehouse compute_wh;
use schema cricket.clean;


-- Extract Players -- version-1

Select 
    raw.info:match_type_number::int as match_type_number,
    raw.info:players,
    raw.info:teams
from cricket.raw.match_raw_tbl raw;

--version_2

Select 
    raw.info:match_type_number::int as match_type_number,
    raw.info:players,
    raw.info:teams
from cricket.raw.match_raw_tbl raw
where match_type_number = 4684;


-- We want to Flatten data as for Both Teams we want to see data in different ROWS

Select 
    raw.info:match_type_number::int as match_type_number,
    -- p.*
    p.key::text as Country
from cricket.raw.match_raw_tbl raw,
lateral flatten(input => raw.info:players ) as p
where match_type_number = 4684;


-- version 4


Select 
    raw.info:match_type_number::int as match_type_number,
    --team.*,
    p.key::text as Country,
    team.value::text as player_name
from cricket.raw.match_raw_tbl raw,
lateral flatten(input => raw.info:players ) as p,
lateral flatten( input => p.value) team
where match_type_number = 4684;



-- Finally Player Table

create or replace table cricket.clean.player_clean_tbl as 
select 
    raw.info:match_type_number::int as match_type_number, 
    p.key::text as country,
    team.value:: text as player_name,
    raw.stg_file_name ,
    raw.stg_file_row_number,
    raw.stg_file_hashkey,
    raw.stg_modified_ts
from cricket.raw.match_raw_tbl raw,
lateral flatten (input => raw.info:players) p,
lateral flatten (input => p.value) team;


DESC TABLE cricket.clean.player_clean_tbl;   -- We saw Null and PK and UK as N -- It should njot be

-- Add NOT NULL and FK

ALTER TABLE cricket.clean.player_clean_tbl
MODIFY COLUMN match_type_number SET NOT NULL;



ALTER TABLE cricket.clean.player_clean_tbl
MODIFY COLUMN Country SET NOT NULL;

ALTER TABLE cricket.clean.player_clean_tbl
MODIFY COLUMN player_name SET NOT NULL;


DESC TABLE cricket.clean.player_clean_tbl; 


ALTER TABLE cricket.clean.match_detail_clean ADD PRIMARY KEY (match_type_number); -- Add PK

-- FK
ALTER  TABLE cricket.clean.player_clean_tbl
Add CONSTRAINT fk_match_id
FOREIGN KEY (match_type_number)
REFERENCES cricket.clean.match_detail_clean (match_type_number);


DESC TABLE cricket.clean.player_clean_tbl; 

-- and PK and FK are seen via get_ddl()

Select get_ddl('table', 'cricket.clean.player_clean_tbl');

-- Connect DBeaver to SF -- to see relationships -- data Model.
