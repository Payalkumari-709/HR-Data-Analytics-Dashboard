

-- ===========================================================
-- Create Table
-- ===========================================================

DROP TABLE IF EXISTS hr;

CREATE TABLE hr (
    id VARCHAR(20),
    first_name VARCHAR(50),
    last_name VARCHAR(50),
    birthdate VARCHAR(20),
    gender VARCHAR(20),
    race VARCHAR(100),
    department VARCHAR(100),
    jobtitle VARCHAR(100),
    location VARCHAR(50),
    hire_date VARCHAR(20),
    termdate VARCHAR(100),
    location_city VARCHAR(100),
    location_state VARCHAR(100)
);

-- ===========================================================
-- Import the CSV file into the hr table using pgAdmin
-- ===========================================================

SELECT * FROM hr;

-- ===========================================================
-- Data Cleaning & Preprocessing
-- ===========================================================

-- Rename primary key column

ALTER TABLE hr
RENAME COLUMN id TO emp_id;

-- Verify table structure

SELECT column_name, data_type
FROM information_schema.columns
WHERE table_name = 'hr';

-- ===========================================================
-- Convert Birthdate to DATE
-- ===========================================================

ALTER TABLE hr
ALTER COLUMN birthdate
TYPE DATE
USING (
    CASE
        WHEN birthdate LIKE '%/%'
            THEN TO_DATE(birthdate,'MM/DD/YYYY')
        WHEN birthdate LIKE '%-%'
            THEN TO_DATE(birthdate,'MM-DD-YYYY')
        ELSE NULL
    END
);

-- ===========================================================
-- Convert Hire Date to DATE
-- ===========================================================

ALTER TABLE hr
ALTER COLUMN hire_date
TYPE DATE
USING (
    CASE
        WHEN hire_date LIKE '%/%'
            THEN TO_DATE(hire_date,'MM/DD/YYYY')
        WHEN hire_date LIKE '%-%'
            THEN TO_DATE(hire_date,'MM-DD-YYYY')
        ELSE NULL
    END
);

-- ===========================================================
-- Convert Termination Date to DATE
-- ===========================================================

ALTER TABLE hr
ALTER COLUMN termdate
TYPE DATE
USING (
    CASE
        WHEN termdate IS NULL OR TRIM(termdate) = ''
            THEN NULL
        ELSE CAST(LEFT(termdate,10) AS DATE)
    END
);

-- ===========================================================
-- Add Age Column
-- ===========================================================

ALTER TABLE hr
ADD COLUMN age INT;

UPDATE hr
SET age = EXTRACT(YEAR FROM AGE(CURRENT_DATE,birthdate));

-- Verify age calculation

SELECT
    MIN(age) AS minimum_age,
    MAX(age) AS maximum_age
FROM hr;

-- ===========================================================
-- Exploratory Data Analysis (EDA)
-- ===========================================================

-- ===========================================================
-- 1. Gender Breakdown of Active Employees
-- ===========================================================

SELECT
    gender,
    COUNT(*) AS employee_count
FROM hr
WHERE termdate IS NULL
GROUP BY gender
ORDER BY employee_count DESC;

-- ===========================================================
-- 2. Race Breakdown of Active Employees
-- ===========================================================

SELECT
    race,
    COUNT(*) AS employee_count
FROM hr
WHERE termdate IS NULL
GROUP BY race
ORDER BY employee_count DESC;

-- ===========================================================
-- 3. Age Distribution
-- ===========================================================

SELECT
    CASE
        WHEN age BETWEEN 18 AND 24 THEN '18-24'
        WHEN age BETWEEN 25 AND 34 THEN '25-34'
        WHEN age BETWEEN 35 AND 44 THEN '35-44'
        WHEN age BETWEEN 45 AND 54 THEN '45-54'
        WHEN age BETWEEN 55 AND 64 THEN '55-64'
        ELSE '65+'
    END AS age_group,
    COUNT(*) AS employee_count
FROM hr
WHERE termdate IS NULL
GROUP BY age_group
ORDER BY age_group;

-- ===========================================================
-- 4. Employees Working at Headquarters vs Remote
-- ===========================================================

SELECT
    location,
    COUNT(*) AS employee_count
FROM hr
WHERE termdate IS NULL
GROUP BY location
ORDER BY employee_count DESC;

-- ===========================================================
-- 5. Average Employment Length of Terminated Employees
-- ===========================================================

SELECT
    ROUND(
        AVG(EXTRACT(YEAR FROM AGE(termdate,hire_date))),
        0
    ) AS average_years
FROM hr
WHERE termdate IS NOT NULL
AND termdate <= CURRENT_DATE;

-- ===========================================================
-- 6. Gender Distribution Across Departments & Job Titles
-- ===========================================================

SELECT
    department,
    jobtitle,
    gender,
    COUNT(*) AS employee_count
FROM hr
WHERE termdate IS NULL
GROUP BY department, jobtitle, gender
ORDER BY department, jobtitle, gender;

SELECT
    department,
    gender,
    COUNT(*) AS employee_count
FROM hr
WHERE termdate IS NULL
GROUP BY department, gender
ORDER BY department, gender;

-- ===========================================================
-- 7. Job Title Distribution
-- ===========================================================

SELECT
    jobtitle,
    COUNT(*) AS employee_count
FROM hr
WHERE termdate IS NULL
GROUP BY jobtitle
ORDER BY employee_count DESC;

-- ===========================================================
-- 8. Department-wise Termination Rate
-- ===========================================================

SELECT
    department,
    COUNT(*) AS total_employees,
    COUNT(*) FILTER (
        WHERE termdate IS NOT NULL
        AND termdate <= CURRENT_DATE
    ) AS terminated_employees,

    ROUND(
        (
            COUNT(*) FILTER (
                WHERE termdate IS NOT NULL
                AND termdate <= CURRENT_DATE
            )::NUMERIC
            / COUNT(*)
        ) * 100,
        2
    ) AS termination_rate

FROM hr
GROUP BY department
ORDER BY termination_rate DESC;

-- ===========================================================
-- 9. Employee Distribution by State
-- ===========================================================

SELECT
    location_state,
    COUNT(*) AS employee_count
FROM hr
WHERE termdate IS NULL
GROUP BY location_state
ORDER BY employee_count DESC;

-- ===========================================================
-- Employee Distribution by City
-- ===========================================================

SELECT
    location_city,
    COUNT(*) AS employee_count
FROM hr
WHERE termdate IS NULL
GROUP BY location_city
ORDER BY employee_count DESC;

-- ===========================================================
-- 10. Employee Count Change Over Time
-- ===========================================================

SELECT
    EXTRACT(YEAR FROM hire_date) AS year,
    COUNT(*) AS hires,

    COUNT(*) FILTER (
        WHERE termdate IS NOT NULL
        AND termdate <= CURRENT_DATE
    ) AS terminations,

    COUNT(*) -
    COUNT(*) FILTER (
        WHERE termdate IS NOT NULL
        AND termdate <= CURRENT_DATE
    ) AS net_change,

    ROUND(
        (
            COUNT(*) FILTER (
                WHERE termdate IS NOT NULL
                AND termdate <= CURRENT_DATE
            )::NUMERIC
            / COUNT(*)
        ) * 100,
        2
    ) AS termination_percentage

FROM hr
GROUP BY EXTRACT(YEAR FROM hire_date)
ORDER BY year;

-- ===========================================================
-- 11. Average Tenure by Department
-- ===========================================================

SELECT
    department,
    ROUND(
        AVG(EXTRACT(YEAR FROM AGE(termdate, hire_date))),
        0
    ) AS average_tenure
FROM hr
WHERE termdate IS NOT NULL
  AND termdate <= CURRENT_DATE
GROUP BY department
ORDER BY average_tenure DESC;