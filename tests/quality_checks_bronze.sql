/*
===============================================================================
Quality Checks
===============================================================================
Script Purpose:
    This script performs various quality checks for data consistency, accuracy, 
    and standardization across the 'bronze' layer. It includes checks for:
    - Null or duplicate primary keys.
    - Unwanted spaces in string fields.
    - Data standardization and consistency.
    - Invalid date ranges and orders.
    - Data consistency between related fields.

Usage Notes:
    - Run these for checking data in Bronze Layer.
===============================================================================
*/

/* 
======================================
check for clean crm_cust_info table
======================================
*/
-- Check for nulls or duplicates in Primary key
-- Expectation: No Result
SELECT 
cst_id,
count(*)
FROM bronze.crm_cust_info
GROUP BY cst_id
HAVING count(*) >1 OR cst_id IS NULL;

SELECT * FROM bronze.crm_cust_info
WHERE cst_id = 29466;

-- Check for unwanted Spaces
-- Expectation: No Results
SELECT cst_firstname
FROM bronze.crm_cust_info
WHERE cst_firstname != TRIM(cst_firstname)

SELECT cst_lastname
FROM bronze.crm_cust_info
WHERE cst_lastname != TRIM(cst_lastname)

-- Data Standardization & Consistency
SELECT DISTINCT cst_gndr
FROM bronze.crm_cust_info

SELECT DISTINCT cst_material_status
FROM bronze.crm_cust_info

/* 
=============================
check for clean crm_prd_info
=============================
*/
-- Check for nulls or duplicates in Primary key
-- Expectation: No Result
SELECT
prd_id,
count(*)
FROM bronze.crm_prd_info
GROUP BY prd_id
HAVING count(*) >1 OR prd_id IS NULL

-- substring() extract a specific part of a string value
SELECT
prd_id,
prd_key,
REPLACE(SUBSTRING(prd_key,1,5),'-','_') AS cat_id, --using SUBSTRING function define start-end position to extract and replace '-' with '_' -> use to join erp
SUBSTRING(prd_key,7,len(prd_key)) AS prd_key, -- size in each not equal -> use to join crm_sales_details
prd_nm,
prd_cost,
prd_line,
prd_start_dt,
prd_end_dt
FROM bronze.crm_prd_info 
WHERE SUBSTRING(prd_key,7,len(prd_key)) IN
(SELECT sls_prd_key FROM bronze.crm_sales_details)

SELECT
prd_id,
prd_key,
REPLACE(SUBSTRING(prd_key,1,5),'-','_') AS cat_id, --using SUBSTRING function define start-end position to extract and replace '-' with '_' -> use to join erp
prd_nm,
prd_cost,
prd_line,
prd_start_dt,
prd_end_dt
FROM bronze.crm_prd_info 
WHERE REPLACE(SUBSTRING(prd_key,1,5),'-','_') NOT IN
(SELECT DISTINCT id FROM bronze.erp_px_cat_g1v2)

-- Check for unwanted Spaces
-- Expectation: No Results
SELECT prd_nm
FROM bronze.crm_prd_info
WHERE prd_nm != TRIM(prd_nm)

-- Check for NULLs or Negative Numbers
-- Expectation: No Results
SELECT prd_cost
FROM bronze.crm_prd_info
WHERE prd_cost < 0 OR prd_cost IS NULL

-- Data Standardization & Consistency
SELECT DISTINCT prd_line
FROM bronze.crm_prd_info

-- check for Invalid Date Orders
SELECT *
FROM bronze.crm_prd_info
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

/* 
=============================
check for clean crm_sales_details
=============================
*/
-- Check for unwanted Spaces
-- Expectation: No Results
SELECT 
sls_ord_num
,sls_prd_key
,sls_cust_id
,sls_order_dt
,sls_ship_dt
,sls_due_dt
,sls_sales
,sls_quantity
,sls_price
FROM bronze.crm_sales_details
WHERE sls_ord_num != TRIM(sls_ord_num)

--check key with other table which they must to map(crm_cust_info,crm_prd_info)
SELECT 
sls_ord_num
,sls_prd_key
,sls_cust_id
,sls_order_dt
,sls_ship_dt
,sls_due_dt
,sls_sales
,sls_quantity
,sls_price
FROM bronze.crm_sales_details
WHERE sls_cust_id NOT IN 
(SELECT cst_id FROM silver.crm_cust_info)

--check for invalid date : change data type from integer to date
SELECT 
NULLIF (sls_order_dt,0) sls_order_dt
FROM bronze.crm_sales_details
WHERE sls_order_dt <= 0 
OR LEN(sls_order_dt) != 8 
OR sls_order_dt > 20500101 
OR sls_order_dt < 19000101

SELECT 
NULLIF (sls_ship_dt,0) sls_ship_dt
FROM bronze.crm_sales_details
WHERE sls_ship_dt <= 0 
OR LEN(sls_ship_dt) != 8 
OR sls_ship_dt > 20500101 
OR sls_ship_dt < 19000101

SELECT 
NULLIF (sls_due_dt,0) sls_due_dt
FROM bronze.crm_sales_details
WHERE sls_due_dt <= 0 
OR LEN(sls_due_dt) != 8 
OR sls_due_dt > 20500101 
OR sls_due_dt < 19000101

--check for Invalid Date Orders : check order date must always be ealier than the shipping Date or Due Date
SELECT 
*
FROM bronze.crm_sales_details
WHERE sls_order_dt > sls_ship_dt --order date must be smaller than others
OR sls_order_dt > sls_due_dt 

-- Check Data Consistency: Between Sales, Quantity, and Price /must to talk with business domain for rules before edit it
-- >> Sales = Quantity * Price
-- >> Values must not be NULL, zero, or negative.
-- >> #1 Solution Data Issues will be fixed direct in source system 
-- >> #2 Solution Data Issues will be fixed direct in data warehouse
SELECT 
sls_sales AS old_sls_sales ,
sls_quantity,
sls_price AS old_sls_price,
CASE 
    WHEN sls_sales IS NULL OR sls_sales <= 0 OR sls_sales != sls_quantity * ABS(sls_price)
    THEN sls_quantity * ABS(sls_price)
    ELSE sls_sales
END AS sls_sales,
CASE 
    WHEN sls_price IS NULL OR sls_price <= 0
    THEN sls_sales / NULLIF(sls_quantity, 0)
    ELSE sls_price
END AS sls_price
FROM bronze.crm_sales_details
WHERE sls_sales != sls_quantity * sls_price
OR sls_sales IS NULL OR sls_quantity IS NULL OR sls_price IS NULL 
OR sls_sales <= 0 OR sls_quantity <= 0 OR sls_price <= 0 
ORDER BY sls_sales,sls_quantity,sls_price

/* 
=============================
check for clean erp_cust_az12
=============================
*/
--adjust key for map with crm_cust_info 
SELECT
    cid,
    CASE WHEN cid LIKE 'NAS%' THEN SUBSTRING(cid,4,LEN(cid))
    ELSE cid
    END cid,
    bdate,
    gen
FROM bronze.erp_cust_az12
WHERE CASE WHEN cid LIKE 'NAS%' THEN SUBSTRING(cid,4,LEN(cid))
    ELSE cid
    END NOT IN (SELECT cst_key FROM silver.crm_cust_info)

--identify out of range dates
SELECT DISTINCT bdate
FROM bronze.erp_cust_az12
WHERE bdate < '1924-01-01' OR bdate > GETDATE()

--Data Standardization & Consistency
SELECT DISTINCT gen
FROM bronze.erp_cust_az12

/* 
=============================
check for clean erp_loc_a101
=============================
*/
SELECT 
REPLACE(cid,'-','') cid,
cntry
FROM bronze.erp_loc_a101
WHERE REPLACE(cid,'-','') NOT IN 
(SELECT cst_key FROM silver.crm_cust_info)

-- Data Standardization & Consistency
SELECT DISTINCT 
cntry AS old_cntry,
CASE 
    WHEN TRIM(cntry) = 'DE' THEN 'Germany'
    WHEN TRIM(cntry) IN ('US', 'USA') THEN 'United States'
    WHEN TRIM(cntry) = '' OR cntry IS NULL THEN 'n/a'
    ELSE TRIM(cntry)
END AS cntry
FROM bronze.erp_loc_a101
ORDER BY cntry

/* 
=============================
check for clean erp_px_cat_g1v1
=============================
*/
--check for unwanted spaces
SELECT * FROM bronze.erp_px_cat_g1v2
WHERE cat != TRIM(cat) OR subcat != TRIM(subcat) OR maintenance != TRIM(maintenance)

--Data Standardization & Consistency
SELECT DISTINCT cat
FROM bronze.erp_px_cat_g1v2

SELECT DISTINCT subcat
FROM bronze.erp_px_cat_g1v2

SELECT DISTINCT maintenance
FROM bronze.erp_px_cat_g1v2
