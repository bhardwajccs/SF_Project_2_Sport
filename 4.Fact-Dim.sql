use role sysadmin;
use warehouse compute_wh;
use schema cricket.consumption;

-- Date dim
create or replace table date_dim (
    date_id int primary key autoincrement,
    full_dt date,
    day int,
    month int,
    year int,
    quarter int,
    dayofweek int,
    dayofmonth int,
    dayofyear int,
    dayofweekname varchar(3), -- to store day names (e.g., "Mon")
    isweekend boolean -- to indicate if it's a weekend (True/False Sat/Sun both falls under weekend)
);


-- Referee dim
create or replace table referee_dim (
    referee_id int primary key autoincrement,
    referee_name text not null,
    referee_type text not null
);

-- Team and Player dim
create or replace table team_dim (
    team_id int primary key autoincrement,
    team_name text not null
);

-- player..
create or replace table player_dim (
    player_id int primary key autoincrement,
    team_id int not null,
    player_name text not null
);

-- Realtion b/n Player and Team Dim tables.
alter table cricket.consumption.player_dim
add constraint fk_team_player_id
foreign key (team_id)
references cricket.consumption.team_dim (team_id);


-- Venue dim
create or replace table venue_dim (
    venue_id int primary key autoincrement,
    venue_name text not null,
    city text not null,
    state text,
    country text,
    continent text,
    end_Names text,
    capacity number,
    pitch text,
    flood_light boolean,
    established_dt date,
    playing_area text,
    other_sports text,
    curator text,
    lattitude number(10,6),
    longitude number(10,6)
);


-- Match type dim
create or replace table match_type_dim (
    match_type_id int primary key autoincrement,
    match_type text not null
);


-- Match fact
CREATE or replace TABLE match_fact (
    match_id INT PRIMARY KEY,
    date_id INT NOT NULL,
    referee_id INT NOT NULL,
    team_a_id INT NOT NULL,
    team_b_id INT NOT NULL,
    match_type_id INT NOT NULL,
    venue_id INT NOT NULL,
    total_overs number(3),
    balls_per_over number(1),

    overs_played_by_team_a number(2),
    bowls_played_by_team_a number(3),
    extra_bowls_played_by_team_a number(3),
    extra_runs_scored_by_team_a number(3),
    fours_by_team_a number(3),
    sixes_by_team_a number(3),
    total_score_by_team_a number(3),
    wicket_lost_by_team_a number(2),

    overs_played_by_team_b number(2),
    bowls_played_by_team_b number(3),
    extra_bowls_played_by_team_b number(3),
    extra_runs_scored_by_team_b number(3),
    fours_by_team_b number(3),
    sixes_by_team_b number(3),
    total_score_by_team_b number(3),
    wicket_lost_by_team_b number(2),

    toss_winner_team_id int not null, 
    toss_decision text not null, 
    match_result text not null, 
    winner_team_id int not null,

    CONSTRAINT fk_date FOREIGN KEY (date_id) REFERENCES date_dim (date_id),
    CONSTRAINT fk_referee FOREIGN KEY (referee_id) REFERENCES referee_dim (referee_id),
    CONSTRAINT fk_team1 FOREIGN KEY (team_a_id) REFERENCES team_dim (team_id),
    CONSTRAINT fk_team2 FOREIGN KEY (team_b_id) REFERENCES team_dim (team_id),
    CONSTRAINT fk_match_type FOREIGN KEY (match_type_id) REFERENCES match_type_dim (match_type_id),
    CONSTRAINT fk_venue FOREIGN KEY (venue_id) REFERENCES venue_dim (venue_id),

    CONSTRAINT fk_toss_winner_team FOREIGN KEY (toss_winner_team_id) REFERENCES team_dim (team_id),
    CONSTRAINT fk_winner_team FOREIGN KEY (winner_team_id) REFERENCES team_dim (team_id)
);


-- Data Population

-- team dim (Team name)
Select distinct team_name from (
    Select first_team as team_name from cricket.clean.match_detail_clean
    UNION ALL
    Select  second_team as team_name  from cricket.clean.match_detail_clean
)

-- v2
-- Insert into team dim
INSERT INTO cricket.consumption.team_dim (team_name)
Select distinct team_name from (
    Select first_team as team_name from cricket.clean.match_detail_clean
    UNION ALL
    Select  second_team as team_name  from cricket.clean.match_detail_clean
)

-- v3
Select * from cricket.consumption.team_dim;



-- team player
-- v1
Select * from cricket.clean.player_clean_tbl;

-- v2
Select country, player_name from cricket.clean.player_clean_tbl group by country, player_name;

-- v3
Select a.country,b.team_id, a.player_name 
from 
    cricket.clean.player_clean_tbl as a JOiN cricket.consumption.team_dim as b
    ON a.country = b.team_name
group by 
    a.country, 
    b.team_id,
    a.player_name;

    -- V4 Insert Data
INSERT INTO CRICKET.CONSUMPTION.PLAYER_DIM(team_id, player_name)
    Select b.team_id, a.player_name 
    from 
        cricket.clean.player_clean_tbl as a JOiN cricket.consumption.team_dim as b
        ON a.country = b.team_name
    group by 
        a.country, 
        b.team_id,
        a.player_name;

-- V5
Select * from CRICKET.CONSUMPTION.PLAYER_DIM;



-- Referee dim
-- We don't have data in Clean layer for this -- SKIP it
-- Understand it before desgining Refress

-- V1
Select * from cricket.clean.match_detail_clean;   -- don't have Refree details

--V2
Select info from cricket.raw.match_raw_tbl limit 1;

--V3 Refress details
SELECT
    info:officials.match_referees[0]::text as match_referee,
    info:officials.reserve_umpires[0]::text as reserve_umpire,
    info:officials.tv_umpires[0]::text as tv_umpire,
    info:officials.umpires[0]::text as first_umpire,
    info:officials.umpires[1]::text as second_umpire
FROM 
cricket.raw.match_raw_tbl limit 1;

-- V4 -- But we will keep Refree table as empty.


-- venue dim

--V1
SELECT * FROM cricket.clean.match_detail_clean limit 10;

--V2
SELECT venue, city FROM cricket.clean.match_detail_clean limit 10;


--v3
SELECT venue, city FROM cricket.clean.match_detail_clean
GROUP BY venue,city;

--V4
INSERT INTO cricket.consumption.venue_dim (venue_name, city)
SELECT venue, city FROM (
    SELECT 
        venue,
        CASE
            WHEN city is null then 'NA' 
            ELSE city
            END AS city
    from cricket.clean.match_detail_clean
    )
GROUP BY 
    venue,
    city;

    --V6
    select * from cricket.consumption.venue_dim where city = 'Bengaluru';




    -- Match Type dim

    -- V1
    Select * from cricket.clean.match_detail_clean limit 2;

    --v2
    Select match_type from cricket.clean.match_detail_clean group by match_type;

    -- v3
    INSERT INTO CRICKET.CONSUMPTION.MATCH_TYPE_DIM (match_type)
        Select match_type from cricket.clean.match_detail_clean group by match_type;

    --v4
    Select * from cricket.consumption.match_type_dim;






    
