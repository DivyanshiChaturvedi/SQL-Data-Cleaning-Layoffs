# Layoffs Dataset — SQL Data Cleaning Project

## Overview
End-to-end data cleaning project on a real-world global tech layoffs dataset using MySQL. 
Demonstrates professional data cleaning workflow — never modifying raw data, handling duplicates, standardizing formats, and resolving NULL values.

---

## Dataset
- **Source:** Kaggle — Global Tech Layoffs Dataset
- **Coverage:** Tech company layoffs worldwide (2020–2023)
- **Size:** 2000+ records
- **Columns:** Company, Location, Industry, Total Laid Off, Percentage Laid Off, Date, Stage, Country, Funds Raised

---

## Problems Found in Raw Data
| Problem | Example |
|---|---|
| Duplicate records | Same company, date, and layoff count appearing multiple times |
| Inconsistent industry names | 'Crypto', 'Crypto Currency', 'CryptoCurrency' all meaning the same thing |
| Country name inconsistency | 'United States' and 'United States.' both present |
| Date stored as TEXT | '03/15/2022' instead of proper DATE format |
| Blank and NULL industries | Some companies had blank industry where other rows had the value |
| Rows with no useful data | Records with NULL in both total_laid_off AND percentage_laid_off |
| Leading/trailing whitespace | Company names with extra spaces |

---

## Cleaning Steps

### 1. Created Working Copy — Never Touch Raw Data
```sql
CREATE TABLE layoff_duplicate LIKE layoffs;
INSERT layoff_duplicate SELECT * FROM layoffs;
```

### 2. Removed Duplicates Using ROW_NUMBER()
Used ROW_NUMBER() with PARTITION BY across all relevant columns to identify true duplicates, then deleted rows where row_num > 1.

### 3. Standardized Data
- Trimmed whitespace from company names
- Unified all Crypto variations → 'Crypto'
- Unified 'United States.' → 'United States'
- Converted date column from TEXT to proper DATE format using STR_TO_DATE()
- Used ALTER TABLE to change column data type from text to date

### 4. Handled NULL Values
- Converted blank industry values to NULL for consistency
- Self-joined the table to fill NULL industries using known values from the same company
- Deleted rows where both total_laid_off AND percentage_laid_off were NULL (unusable records)

### 5. Removed Unnecessary Columns
- Dropped the row_num helper column after duplicate removal

---

## Key SQL Concepts Used
- ROW_NUMBER() window function
- CTEs (Common Table Expressions)
- Self JOIN for NULL imputation
- STR_TO_DATE() for format conversion
- ALTER TABLE for data type changes
- TRIM() for whitespace removal
- LIKE with wildcards for pattern matching

---

## Tools Used
- MySQL 8.0
- MySQL Workbench

---

## Files
- `layoffs.csv` — Original raw dataset
- `data_cleaning_layoffs.sql` — Complete cleaning script with comments
