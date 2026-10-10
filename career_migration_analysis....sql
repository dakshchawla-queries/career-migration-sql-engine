USE CareerMigrationDB;

-- DATA NOTES:
-- Source: Stack Overflow Developer Survey 2025
-- Salary = ConvertedCompYearly (annual USD), converted with TRY_CAST because the import loaded it as text
-- Rows with NULL salary or salary below $10,000/year are excluded as unrealistic entries
-- Countries analysed: Germany, Canada, Ireland
-- Tables: dbo.respondents (one row per person), dbo.respondent_languages (one row per person per language, linked by ResponseId)


-- QUESTION 1: What is the average annual salary (USD) for developers in Germany, Canada, and Ireland?
WITH EXACT_SALARY AS (
    SELECT
        COUNTRY,
        TRY_CAST(ConvertedCompYearly AS FLOAT) AS NEW_SALARY
    FROM dbo.respondents
),
FILTERED_SALARY AS (
    SELECT COUNTRY, NEW_SALARY
    FROM EXACT_SALARY
    WHERE NEW_SALARY IS NOT NULL
      AND NEW_SALARY >= 10000
      AND COUNTRY IN ('Germany', 'Canada', 'Ireland')
)
SELECT
    COUNTRY,
    ROUND(AVG(NEW_SALARY), 0) AS AVERAGE_SALARY
FROM FILTERED_SALARY
GROUP BY COUNTRY;


-- QUESTION 2: Which developer role pays the most in each country? (RANK, minimum 10 respondents per role)
WITH EXACT_SALARY AS (
    SELECT
        COUNTRY,
        DEVTYPE,
        TRY_CAST(ConvertedCompYearly AS FLOAT) AS NEW_SALARY
    FROM dbo.respondents
),
FILTERED_SALARY AS (
    SELECT COUNTRY, DEVTYPE, NEW_SALARY
    FROM EXACT_SALARY
    WHERE NEW_SALARY IS NOT NULL
      AND NEW_SALARY >= 10000
      AND COUNTRY IN ('Germany', 'Canada', 'Ireland')
),
CTE_DEV AS (
    SELECT
        COUNTRY,
        DEVTYPE,
        AVG(NEW_SALARY) AS AVERAGE_SALARY,
        COUNT(*) AS NO_OF_PEOPLE
    FROM FILTERED_SALARY
    GROUP BY COUNTRY, DEVTYPE
    HAVING COUNT(*) >= 10
),
CTE_RANK AS (
    SELECT
        COUNTRY,
        DEVTYPE,
        AVERAGE_SALARY,
        NO_OF_PEOPLE,
        RANK() OVER (PARTITION BY COUNTRY ORDER BY AVERAGE_SALARY DESC) AS RANKING
    FROM CTE_DEV
)
SELECT
    COUNTRY,
    DEVTYPE,
    ROUND(AVERAGE_SALARY, 0) AS AVERAGE_SALARY,
    NO_OF_PEOPLE
FROM CTE_RANK
WHERE RANKING = 1
ORDER BY COUNTRY;


-- QUESTION 3: Where does an individual salary sit compared with other developers in the same country? (PERCENT_RANK)
WITH EXACT_SALARY AS (
    SELECT
        COUNTRY,
        TRY_CAST(ConvertedCompYearly AS FLOAT) AS NEW_SALARY
    FROM dbo.respondents
),
FILTERED_SALARY AS (
    SELECT COUNTRY, NEW_SALARY
    FROM EXACT_SALARY
    WHERE NEW_SALARY IS NOT NULL
      AND NEW_SALARY >= 10000
      AND COUNTRY IN ('Germany', 'Canada', 'Ireland')
)
SELECT
    COUNTRY,
    NEW_SALARY,
    PERCENT_RANK() OVER (PARTITION BY COUNTRY ORDER BY NEW_SALARY) AS SalaryPercentile
FROM FILTERED_SALARY
ORDER BY COUNTRY, NEW_SALARY;


-- QUESTION 4: Does more work experience lead to higher pay in each country? (NTILE experience buckets)
-- Bucket 1 = least experienced 25% in that country, bucket 4 = most experienced 25%
WITH CAST_CTE AS (
    SELECT
        COUNTRY,
        TRY_CAST(WorkExp AS INT) AS TOTAL_EXPERIENCE,
        TRY_CAST(ConvertedCompYearly AS FLOAT) AS CONVERTED_SALARY
    FROM dbo.respondents
),
FILTERED AS (
    SELECT
        TOTAL_EXPERIENCE,
        CONVERTED_SALARY,
        COUNTRY
    FROM CAST_CTE
    WHERE TOTAL_EXPERIENCE IS NOT NULL
      AND CONVERTED_SALARY IS NOT NULL
      AND CONVERTED_SALARY >= 10000
      AND COUNTRY IN ('Germany', 'Ireland', 'Canada')
),
BUCKETED AS (
    SELECT
        COUNTRY,
        CONVERTED_SALARY,
        NTILE(4) OVER (PARTITION BY COUNTRY ORDER BY TOTAL_EXPERIENCE) AS ExperienceBucket
    FROM FILTERED
)
SELECT
    COUNTRY,
    ExperienceBucket,
    ROUND(AVG(CONVERTED_SALARY), 0) AS AvgSalary
FROM BUCKETED
GROUP BY COUNTRY, ExperienceBucket
ORDER BY COUNTRY, ExperienceBucket;


-- QUESTION 5: Which 5 programming languages have the highest average salary in each country? (JOIN with respondent_languages, minimum 10 respondents per language)
WITH BASE AS (
    SELECT
        res.Country,
        resl.LanguageHaveWorkedWith,
        TRY_CAST(res.ConvertedCompYearly AS FLOAT) AS NEW_SALARY
    FROM dbo.respondents AS res
    INNER JOIN dbo.respondent_languages AS resl
        ON res.ResponseId = resl.ResponseId
),
FILTERED AS (
    SELECT
        Country,
        LanguageHaveWorkedWith,
        NEW_SALARY
    FROM BASE
    WHERE NEW_SALARY IS NOT NULL
      AND NEW_SALARY >= 10000
      AND Country IN ('Germany', 'Canada', 'Ireland')
),
AGGREGATION AS (
    SELECT
        Country,
        LanguageHaveWorkedWith,
        AVG(NEW_SALARY) AS AVERAGE_SALARY,
        COUNT(*) AS NO_OF_PEOPLE
    FROM FILTERED
    GROUP BY Country, LanguageHaveWorkedWith
    HAVING COUNT(*) >= 10
),
RANKING AS (
    SELECT
        Country,
        LanguageHaveWorkedWith,
        AVERAGE_SALARY,
        NO_OF_PEOPLE,
        RANK() OVER (PARTITION BY Country ORDER BY AVERAGE_SALARY DESC) AS RANKS
    FROM AGGREGATION
)
SELECT
    Country,
    LanguageHaveWorkedWith,
    ROUND(AVERAGE_SALARY, 0) AS AVERAGE_SALARY,
    NO_OF_PEOPLE
FROM RANKING
WHERE RANKS <= 5
ORDER BY Country, RANKS;
