Use ev_sales_project;

LOAD DATA LOCAL INFILE '/Users/akanksha/Documents/Data_201_Group_Project/New_ZEV_Sales.csv'
INTO TABLE staging_ev_sales
FIELDS TERMINATED BY ',' 
ENCLOSED BY '"' 
LINES TERMINATED BY '\n'
IGNORE 1 ROWS
(Data_Year, Quarter, County, State, Fuel_Type, Make, Model, Number_of_Vehicles);

-- Check for null values 

-- ============================================
-- EV REGISTRATION DATA PREPROCESSING & NORMALIZATION
-- ============================================

-- STEP 1: Create staging table to load raw data
-- ============================================
CREATE TABLE staging_ev_sales (
    data_year INT,
    quarter INT,
    county VARCHAR(100),
    fuel_type VARCHAR(50),
    make VARCHAR(100),
    model VARCHAR(100),
    number_of_vehicles INT
);

-- Check for NULL values
SELECT 
    COUNT(*) as total_rows,
    SUM(CASE WHEN data_year IS NULL THEN 1 ELSE 0 END) as null_year,
    SUM(CASE WHEN quarter IS NULL THEN 1 ELSE 0 END) as null_quarter,
    SUM(CASE WHEN county IS NULL THEN 1 ELSE 0 END) as null_county,
    SUM(CASE WHEN state is NULL THEN 1 else 0 END) as null_state,
    SUM(CASE WHEN fuel_type IS NULL THEN 1 ELSE 0 END) as null_fuel_type,
    SUM(CASE WHEN make IS NULL THEN 1 ELSE 0 END) as null_make,
    SUM(CASE WHEN model IS NULL THEN 1 ELSE 0 END) as null_model,
    SUM(CASE WHEN number_of_vehicles IS NULL THEN 1 ELSE 0 END) as null_vehicles
FROM staging_ev_sales;

-- Remove duplicates if any :
select count(*) from staging_ev_sales;
CREATE TABLE temp_dedup AS
SELECT 
    data_year, quarter, county, fuel_type, make, model,
    MIN(number_of_vehicles) AS number_of_vehicles
FROM staging_ev_sales
GROUP BY data_year, quarter, county, state, fuel_type, make, model;

select count(*) from temp_dedup;
TRUNCATE TABLE staging_ev_sales;

INSERT INTO staging_ev_sales
SELECT * FROM temp_dedup;

DROP TABLE temp_dedup;

-- Trim whitespace from text columns

-- Disable safe update mode
SET SQL_SAFE_UPDATES = 0;
UPDATE staging_ev_sales
SET 
    county = TRIM(county),
    state = TRIM(state),
    fuel_type = TRIM(fuel_type),
    make = TRIM(make),
    model = TRIM(model);
    
-- Standardize text case (optional)
UPDATE staging_ev_sales
SET 
	fuel_type = LOWER(fuel_type),
    make = LOWER(make);
    
    -- checking the chnages
    
select * from staging_ev_sales;

-- STEP 3: Verify data integrity
-- ============================================

-- Get unique combinations to verify everything looks correct
SELECT 
    make,
    model,
    fuel_type,
    COUNT(DISTINCT CONCAT(data_year, '-', quarter)) as time_periods,
    SUM(number_of_vehicles) as total_vehicles
FROM staging_ev_sales
GROUP BY make, model, fuel_type
ORDER BY make, model;

-- Check for potential data entry errors
-- (same model with different fuel types - this is normal for some models)
SELECT 
    make,
    model,
    COUNT(DISTINCT fuel_type) as fuel_type_count,
    GROUP_CONCAT(DISTINCT fuel_type) as fuel_types
FROM staging_ev_sales
GROUP BY make, model
HAVING COUNT(DISTINCT fuel_type) > 1;

-- STEP 5: Now proceed with normalized table creation
-- ============================================
-- (Use the original normalization script from earlier, 
-- but with these cleaned names)

-- Add state dimension first
CREATE TABLE state (
    state_id INT PRIMARY KEY AUTO_INCREMENT,
    state_name VARCHAR(100) UNIQUE NOT NULL,
    state_code VARCHAR(50)
);

INSERT INTO state (state_name, state_code)
VALUES 
    ('California', 'CA'),
    ('Out of State', 'Unknown');
    
Select * from state; 


-- County dimension now includes state reference
CREATE TABLE county (
    county_id INT PRIMARY KEY AUTO_INCREMENT,
    county_name VARCHAR(100) NOT NULL,
    state_id INT NOT NULL,
    FOREIGN KEY (state_id) REFERENCES state(state_id),
    UNIQUE KEY (county_name, state_id)
);

INSERT INTO county (county_name, state_id)
SELECT DISTINCT 
    s.county,
    st.state_id
FROM staging_ev_sales s
JOIN state st ON s.state = st.state_name
ORDER BY st.state_id, s.county;

CREATE TABLE fuel_type (
    fuel_type_id INT PRIMARY KEY AUTO_INCREMENT,
    fuel_type_name VARCHAR(100) UNIQUE NOT NULL,
    fuel_category VARCHAR(100)
);

INSERT INTO fuel_type (fuel_type_name, fuel_category)
SELECT DISTINCT 
    fuel_type,
    CASE 
        WHEN fuel_type = 'Electric' THEN 'Battery Electric Vehicle (BEV)'
        WHEN fuel_type = 'PHEV' THEN 'Plug-in Hybrid Electric Vehicle (PHEV)'
        WHEN fuel_type = 'Hydrogen' THEN 'Fuel Cell Electric Vehicle (FCEV)'
        ELSE 'Other'
    END as fuel_category
FROM staging_ev_sales
ORDER BY fuel_type;

select * from fuel_type;

CREATE TABLE make (
    make_id INT PRIMARY KEY AUTO_INCREMENT,
    make_name VARCHAR(100) UNIQUE NOT NULL
);

INSERT INTO make (make_name)
SELECT DISTINCT make 
FROM staging_ev_sales
ORDER BY make;

-- Keep original model names as they appear in the data
CREATE TABLE model (
    model_id INT PRIMARY KEY AUTO_INCREMENT,
    make_id INT,
    model_name VARCHAR(100) NOT NULL,
    FOREIGN KEY (make_id) REFERENCES make(make_id),
    UNIQUE KEY (make_id, model_name)
);

INSERT INTO model (make_id, model_name)
SELECT DISTINCT 
    m.make_id,
    s.model  -- Keep original model names
FROM staging_ev_sales s
JOIN make m ON s.make = m.make_name
ORDER BY m.make_id, s.model;

select * from model;


CREATE TABLE time (
    time_id INT PRIMARY KEY AUTO_INCREMENT,
    year INT NOT NULL,
    quarter INT NOT NULL,
    quarter_name VARCHAR(50),
    UNIQUE KEY (year, quarter)
);

INSERT INTO time (year, quarter, quarter_name)
SELECT DISTINCT 
    data_year,
    quarter,
    CONCAT('Q', quarter, ' ', data_year)
FROM staging_ev_sales
ORDER BY data_year, quarter;

CREATE TABLE fact_vehicle_sales (
    sales_id INT PRIMARY KEY AUTO_INCREMENT,
    time_id INT NOT NULL,
    county_id INT NOT NULL,
    fuel_type_id INT NOT NULL,
    model_id INT NOT NULL,
    number_of_vehicles INT NOT NULL,
    FOREIGN KEY (time_id) REFERENCES time(time_id),
    FOREIGN KEY (county_id) REFERENCES county(county_id),
    FOREIGN KEY (fuel_type_id) REFERENCES fuel_type(fuel_type_id),
    FOREIGN KEY (model_id) REFERENCES model(model_id)
);

INSERT INTO fact_vehicle_sales 
    (time_id, county_id, fuel_type_id, model_id, number_of_vehicles)
SELECT 
    t.time_id,
    c.county_id,
    f.fuel_type_id,
    m.model_id,
    s.number_of_vehicles
FROM staging_ev_sales s
JOIN time t ON s.data_year = t.year AND s.quarter = t.quarter
JOIN state st ON s.state = st.state_name
JOIN county c ON s.county = c.county_name AND c.state_id = st.state_id
JOIN fuel_type f ON s.fuel_type = f.fuel_type_name
JOIN make mk ON s.make = mk.make_name
JOIN model m ON mk.make_id = m.make_id AND s.model = m.model_name;

-- Create indexes
CREATE INDEX idx_fact_time ON fact_vehicle_sales(time_id);
CREATE INDEX idx_fact_county ON fact_vehicle_sales(county_id);
CREATE INDEX idx_fact_fuel ON fact_vehicle_sales(fuel_type_id);
CREATE INDEX idx_fact_model ON fact_vehicle_sales(model_id);
CREATE INDEX idx_model_make ON model(make_id);

-- Create main view preserving original model names
CREATE VIEW vw_ev_sales AS
SELECT 
    t.year,
    t.quarter,
    t.quarter_name,
    st.state_name,
    st.state_code,
    c.county_name,
    f.fuel_type_name,
    f.fuel_category,
    mk.make_name,
    m.model_name,  -- Original model names preserved
    fs.number_of_vehicles
FROM fact_vehicle_sales fs
JOIN time t ON fs.time_id = t.time_id
JOIN county c ON fs.county_id = c.county_id
JOIN state st ON c.state_id = st.state_id
JOIN fuel_type f ON fs.fuel_type_id = f.fuel_type_id
JOIN model m ON fs.model_id = m.model_id
JOIN make mk ON m.make_id = mk.make_id;

Select count(*) from vw_ev_sales;

-- Analysis part :
-- 1) Top 10 makes by total sales
SELECT 
    make_name,
    COUNT(DISTINCT model_name) as model_count,
    SUM(number_of_vehicles) as total_sales
FROM vw_ev_sales
GROUP BY make_name
ORDER BY total_sales DESC
LIMIT 10;

-- 2) Counties with above avg EV sales
SELECT 
    county_name,
    state_name,
    SUM(number_of_vehicles) as total_sales,
    ROUND(SUM(number_of_vehicles) * 100.0 / 
        (SELECT SUM(number_of_vehicles) FROM vw_ev_sales), 2) as market_share_pct
FROM vw_ev_sales
GROUP BY county_name, state_name
HAVING SUM(number_of_vehicles) > (
    -- Subquery: Calculate average sales per county
    SELECT AVG(county_sales)
    FROM (
        SELECT SUM(number_of_vehicles) as county_sales
        FROM vw_ev_sales
        GROUP BY county_name
    ) as county_totals
)
ORDER BY total_sales DESC;

-- 3) Models outselling their avg EV makes
SELECT 
    make_name,
    model_name,
    SUM(number_of_vehicles) as model_sales,
    (
        -- Correlated subquery: Average sales for this make
        SELECT AVG(model_sales)
        FROM (
            SELECT SUM(number_of_vehicles) as model_sales
            FROM vw_ev_sales v2
            WHERE v2.make_name = v1.make_name
            GROUP BY v2.model_name
        ) as make_avg
    ) as make_avg_sales
FROM vw_ev_sales v1
GROUP BY make_name, model_name
HAVING model_sales > (
    SELECT AVG(model_sales)
    FROM (
        SELECT SUM(number_of_vehicles) as model_sales
        FROM vw_ev_sales v2
        WHERE v2.make_name = v1.make_name
        GROUP BY v2.model_name
    ) as make_avg
)
ORDER BY make_name, model_sales DESC;

-- 4) models with rank per county

WITH county_model_sales AS (
    -- CTE: Get sales by county and model
    SELECT 
        county_name,
        make_name,
        model_name,
        SUM(number_of_vehicles) as total_sales,
        ROW_NUMBER() OVER (
            PARTITION BY county_name 
            ORDER BY SUM(number_of_vehicles) DESC
        ) as rank_in_county
    FROM vw_ev_sales
    GROUP BY county_name, make_name, model_name
)
SELECT 
    county_name,
    make_name,
    model_name,
    total_sales,
    rank_in_county
FROM county_model_sales
WHERE rank_in_county <= 3
ORDER BY county_name, rank_in_county;

-- 5) Year over Year growth trend
WITH yearly_sales AS (
    -- CTE 1: Calculate total sales per year
    SELECT 
        year,
        SUM(number_of_vehicles) as total_sales
    FROM vw_ev_sales
    GROUP BY year
),
yoy_growth AS (
    -- CTE 2: Calculate year-over-year growth
    SELECT 
        year,
        total_sales,
        LAG(total_sales) OVER (ORDER BY year) as prev_year_sales,
        total_sales - LAG(total_sales) OVER (ORDER BY year) as absolute_growth,
        ROUND(
            (total_sales - LAG(total_sales) OVER (ORDER BY year)) * 100.0 / 
            NULLIF(LAG(total_sales) OVER (ORDER BY year), 0), 
            2
        ) as growth_rate_pct
    FROM yearly_sales
)
SELECT 
    year,
    total_sales,
    prev_year_sales,
    absolute_growth,
    growth_rate_pct,
    CASE 
        WHEN growth_rate_pct > 50 THEN 'High Growth'
        WHEN growth_rate_pct > 20 THEN 'Moderate Growth'
        WHEN growth_rate_pct > 0 THEN 'Slow Growth'
        ELSE 'Decline'
    END as growth_category
FROM yoy_growth
ORDER BY year;

-- 6) Sales by Fuel type over time
SELECT 
    year,
    quarter,
    quarter_name,
    fuel_type_name,
    fuel_category,
    SUM(number_of_vehicles) as total_vehicles
FROM vw_ev_sales
GROUP BY year, quarter, quarter_name, fuel_type_name, fuel_category
ORDER BY year, quarter, fuel_type_name;

-- 7) Total EV Sales by county
SELECT 
    county_name,
    state_name,
    SUM(number_of_vehicles) as total_vehicles_sold,
    COUNT(DISTINCT CONCAT(year, '-', quarter)) as time_periods
FROM vw_ev_sales
GROUP BY county_name, state_name
ORDER BY total_vehicles_sold DESC;





