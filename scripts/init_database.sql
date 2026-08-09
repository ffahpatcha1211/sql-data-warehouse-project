/*
===================================
create database and schemas
===================================
script Purpose:
    This scripts create a new database named 'DataWarehouse' and scripts for setup three schemas 
    within the database: 'bronze','silver', 'gold'
warning :
    running dhis script maybe drop the entire 'DataWarehouse' database if it exists.
*/
-- create database
create database DataWarehouse;
use DataWarehouse;
GO

--create schema in DataWarehouse
create schema bronze;
GO
create schema silver;
GO
create schema gold;
GO
