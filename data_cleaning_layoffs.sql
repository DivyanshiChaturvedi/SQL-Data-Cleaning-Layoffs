-- ============================================================
-- LAYOFFS DATASET - DATA CLEANING PROJECT
-- Author: Divyanshi Chaturvedi
-- Tool: MySQL 8.0
-- Dataset: Global Tech Layoffs (2020-2023)
-- ============================================================

-- View raw data
SELECT * FROM layoffs;

-- ============================================================
-- RULE: NEVER modify the raw dataset
-- Always create a duplicate table and work on that
-- Steps:
-- 1. Remove duplicates
-- 2. Standardize the data
-- 3. Handle NULL / blank values
-- 4. Remove unnecessary columns
-- ============================================================

-- STEP 0: Create working copy of raw data
CREATE TABLE layoff_duplicate LIKE layoffs;

SELECT * FROM layoff_duplicate;

INSERT layoff_duplicate
SELECT * FROM layoffs;

-- ============================================================
-- STEP 1: REMOVE DUPLICATES
-- ============================================================

-- Identify duplicates using ROW_NUMBER()
-- If row_num > 1, it is a duplicate
SELECT *,
    ROW_NUMBER() OVER(
        PARTITION BY company, industry, total_laid_off, 
        percentage_laid_off, `date`, location, stage, 
        funds_raised_millions, country
    ) AS row_num
FROM layoff_duplicate;

-- Use CTE to view duplicates
WITH cte_duplicate AS (
    SELECT *,
        ROW_NUMBER() OVER(
            PARTITION BY company, industry, total_laid_off, 
            percentage_laid_off, `date`, location, stage, 
            funds_raised_millions, country
        ) AS row_num
    FROM layoff_duplicate
)
SELECT * FROM cte_duplicate WHERE row_num > 1;

-- Cannot DELETE from a CTE directly
-- Solution: Create a second table with row_num column included
CREATE TABLE `layoff_duplicate2` (
    `company` text,
    `location` text,
    `industry` text,
    `total_laid_off` int DEFAULT NULL,
    `percentage_laid_off` text,
    `date` text,
    `stage` text,
    `country` text,
    `funds_raised_millions` int DEFAULT NULL,
    `row_num` int
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

-- Insert data with row numbers into new table
INSERT INTO layoff_duplicate2
SELECT *,
    ROW_NUMBER() OVER(
        PARTITION BY company, industry, total_laid_off, 
        percentage_laid_off, `date`, location, stage, 
        funds_raised_millions, country
    ) AS row_num
FROM layoff_duplicate;

-- Verify duplicates
SELECT * FROM layoff_duplicate2 WHERE row_num > 1;

-- Delete duplicates
DELETE FROM layoff_duplicate2 WHERE row_num > 1;

-- Confirm duplicates removed
SELECT * FROM layoff_duplicate2;

-- ============================================================
-- STEP 2: STANDARDIZE DATA
-- ============================================================

-- 2a. Remove leading/trailing whitespace from company names
SELECT company, TRIM(company) FROM layoff_duplicate2;

UPDATE layoff_duplicate2
SET company = TRIM(company);

-- 2b. Standardize industry names
-- Found: 'Crypto', 'Crypto Currency', 'CryptoCurrency' — all same industry
SELECT DISTINCT(industry) FROM layoff_duplicate2 ORDER BY 1;

UPDATE layoff_duplicate2
SET industry = 'Crypto'
WHERE industry LIKE 'Crypto%';

-- 2c. Standardize country names
-- Found: 'United States' and 'United States.' — trailing period issue
SELECT DISTINCT(country) FROM layoff_duplicate2 ORDER BY 1;

UPDATE layoff_duplicate2
SET country = 'United States'
WHERE country LIKE 'United States%';

-- 2d. Convert date from TEXT to DATE format
-- Required for time series analysis
SELECT `date`, STR_TO_DATE(`date`, '%m/%d/%Y')
FROM layoff_duplicate2;

UPDATE layoff_duplicate2
SET `date` = STR_TO_DATE(`date`, '%m/%d/%Y');

-- Change column data type from TEXT to DATE
ALTER TABLE layoff_duplicate2
MODIFY COLUMN `date` DATE;

-- ============================================================
-- STEP 3: HANDLE NULL AND BLANK VALUES
-- ============================================================

-- 3a. Convert blank industry values to NULL for consistency
UPDATE layoff_duplicate2
SET industry = NULL
WHERE industry = '';

-- 3b. Fill NULL industries using self-join
-- Logic: if company X has NULL industry in one row but filled in another, use that value
UPDATE layoff_duplicate2 t1
JOIN layoff_duplicate2 t2
    ON t1.company = t2.company
SET t1.industry = t2.industry
WHERE t1.industry IS NULL
AND t2.industry IS NOT NULL;

-- Verify — Airbnb example
SELECT * FROM layoff_duplicate2 WHERE company = 'Airbnb';

-- 3c. Identify rows where both key metrics are NULL (unusable records)
SELECT * FROM layoff_duplicate2
WHERE total_laid_off IS NULL
AND percentage_laid_off IS NULL;

-- Delete these rows — no useful information can be derived
DELETE FROM layoff_duplicate2
WHERE total_laid_off IS NULL
AND percentage_laid_off IS NULL;

-- ============================================================
-- STEP 4: REMOVE UNNECESSARY COLUMNS
-- ============================================================

-- Drop the row_num helper column — no longer needed
ALTER TABLE layoff_duplicate2
DROP COLUMN row_num;

-- ============================================================
-- FINAL: View cleaned dataset
-- ============================================================
SELECT * FROM layoff_duplicate2;