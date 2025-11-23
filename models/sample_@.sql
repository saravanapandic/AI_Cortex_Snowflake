[0m03:09:05  Running with dbt=1.10.15
[0m03:09:05  Registered adapter: snowflake=1.10.3
[0m03:09:06  Found 4 models, 4 data tests, 508 macros
"Removed extra comma in UNION ALL clause"
1
/*
    Welcome to your first dbt model!
    Did you know that you can also configure models directly within SQL files?
    This will override configurations stated in dbt_project.yml

    Try changing "table" to "view" below
*/

{{ config(materialized='table') }}

WITH source_data AS (

    SELECT 1 AS id
    UNION ALL
    SELECT null AS id

)

SELECT *
FROM source_data;

/*
    Uncomment the line below to remove records with null `id` values
*/

-- where id is not null
