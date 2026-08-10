/*
===============================================================================
Quality Checks
===============================================================================
Script Purpose:
    This script performs various quality checks for data consistency, accuracy, 
    and standardization across the 'silver' layer. It includes checks for:
    - Null or duplicate primary keys.
    - Unwanted spaces in string fields.
    - Data standardization and consistency.
    - Invalid date ranges and orders.
    - Data consistency between related fields.

Usage Notes:
    - Run these checks after data loading Silver Layer.
    - Investigate and resolve any discrepancies found during the checks.
===============================================================================
*/

/* 
======================================
check after clean silver.crm_cust_info table
======================================
*/
-- Check for nulls or duplicates in Primary key
-- Expectation: No Result
SELECT 
cst_id,
count(*)
FROM silver.crm_cust_info
GROUP BY cst_id
HAVING count(*) >1 OR cst_id IS NULL;


SELECT * FROM silver.crm_cust_info
WHERE cst_id = 29466;


-- Check for unwanted Spaces
-- Expectation: No Results
SELECT cst_firstname
FROM silver.crm_cust_info
WHERE cst_firstname != TRIM(cst_firstname)

SELECT cst_lastname
FROM silver.crm_cust_info
WHERE cst_lastname != TRIM(cst_lastname)

-- Data Standardization & Consistency
SELECT DISTINCT cst_gndr
FROM silver.crm_cust_info

SELECT DISTINCT cst_material_status
FROM silver.crm_cust_info

SELECT * FROM silver.crm_cust_info

/* 
======================================
check after clean silver.crm_prd_info table
======================================
*/

-- Check for nulls or duplicates in Primary key
-- Expectation: No Result
SELECT
prd_id,
count(*)
FROM silver.crm_prd_info
GROUP BY prd_id
HAVING count(*) >1 OR prd_id IS NULL

-- Check for unwanted Spaces
-- Expectation: No Results
SELECT prd_nm
FROM silver.crm_prd_info
WHERE prd_nm != TRIM(prd_nm)

-- Check for NULLs or Negative Numbers
-- Expectation: No Results
SELECT prd_cost
FROM silver.crm_prd_info
WHERE prd_cost < 0 OR prd_cost IS NULL

-- Data Standardization & Consistency
SELECT DISTINCT prd_line
FROM silver.crm_prd_info

-- check for Invalid Date Orders
SELECT *
FROM silver.crm_prd_info
WHERE prd_end_dt < prd_start_dt 

-- edit start_date end_date
-- Using LEAD() to Access values from the next row within a window
SELECT 
prd_id,
prd_key,
prd_nm,
prd_start_dt,
prd_end_dt,
LEAD(prd_start_dt) OVER (PARTITION BY prd_key ORDER BY prd_start_dt)-1 AS prd_end_dt_test -- select the start_date of next row to be the end_date of current row
FROM bronze.crm_prd_info
WHERE prd_key IN ('AC-HE-HL-U509-R' , 'AC-HE-HL-U509') 

--final 
SELECT * FROM silver.crm_prd_info

/* 
======================================
check after clean silver.crm_sales_details table
======================================
*/

--check for Invalid Date Orders : check order date must always be ealier than the shipping Date or Due Date
SELECT 
*
FROM silver.crm_sales_details
WHERE sls_order_dt > sls_ship_dt --order date must be smaller than others
OR sls_order_dt > sls_due_dt 

-- Check Data Consistency: Between Sales, Quantity, and Price /must to talk with business domain for rules before edit it
-- >> Sales = Quantity * Price
-- >> Values must not be NULL, zero, or negative.
-- >> #1 Solution Data Issues will be fixed direct in source system 
-- >> #2 Solution Data Issues will be fixed direct in data warehouse
SELECT 
sls_sales,
sls_quantity,
sls_price
FROM silver.crm_sales_details
WHERE sls_sales != sls_quantity * sls_price
OR sls_sales IS NULL OR sls_quantity IS NULL OR sls_price IS NULL 
OR sls_sales <= 0 OR sls_quantity <= 0 OR sls_price <= 0 
ORDER BY sls_sales,sls_quantity,sls_price

--final check
SELECT * FROM silver.crm_sales_details

/* 
======================================
check after clean silver.erp_cust_az12
======================================
*/

--identify out of range dates
SELECT DISTINCT bdate
FROM silver.erp_cust_az12
WHERE bdate < '1924-01-01' OR bdate > GETDATE()

--Data Standardization & Consistency
SELECT DISTINCT gen
FROM silver.erp_cust_az12

SELECT * FROM silver.erp_cust_az12

/* 
======================================
check after clean silver.erp_loc_a101
======================================
*/

--Data Standardization & Consistency
SELECT DISTINCT 
cntry 
FROM silver.erp_loc_a101
ORDER BY cntry

SELECT * FROM silver.erp_loc_a101

/* 
======================================
check after clean silver.erp_px_cat_g1v2
======================================
*/
SELECT * FROM silver.erp_px_cat_g1v2
