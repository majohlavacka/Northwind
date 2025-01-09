USE ROLE TRAINING_ROLE;
CREATE WAREHOUSE IF NOT EXISTS KANGAROO_WH;
USE WAREHOUSE KANGAROO_WH;

-- Vytvorenie databazy
CREATE DATABASE IF NOT EXISTS KANGAROO_NORTHWIND_DB;
USE KANGAROO_NORTHWIND_DB;

-- Vytvorenie schemy pre staging tabulky
CREATE SCHEMA IF NOT EXISTS KANGAROO_NORTHWIND_DB.STAGING;

USE SCHEMA KANGAROO_NORTHWIND_DB.STAGING;

-- Vytvorenie jednodtlivych staging tabuliek
CREATE TABLE suppliers_staging (
    SupplierId INT PRIMARY KEY,
    SupplierName VARCHAR(50),
    ContactName VARCHAR(50),
    Address VARCHAR(50),
    City VARCHAR(20),
    PostalCode VARCHAR(10),
    Country VARCHAR(15),
    Phone VARCHAR(15)
);

CREATE TABLE categories_staging (
    CategoryId INT PRIMARY KEY,
    CategoryName VARCHAR(25),
    Description VARCHAR(255)
);

CREATE TABLE products_staging (
    ProductId INT PRIMARY KEY,
    ProductName VARCHAR(50),
    SupplierId INT,
    CategoryId INT,
    Unit VARCHAR(255),
    Price DECIMAL(10,0),
    FOREIGN KEY (SupplierId) REFERENCES suppliers_staging(SupplierId),
    FOREIGN KEY (CategoryId) REFERENCES categories_staging(CategoryId)
);

CREATE TABLE customers_staging (
    CustomerId INT PRIMARY KEY,
    CustomerName VARCHAR(50),
    ContactName VARCHAR(50),
    Address VARCHAR(50),
    City VARCHAR(20),
    PostalCode VARCHAR(10),
    Country VARCHAR(15)
);

CREATE TABLE employees_staging (
    EmployeeId INT PRIMARY KEY,
    LastName VARCHAR(15),
    FirstName VARCHAR(15),
    BirthDate TIMESTAMP,
    Photo VARCHAR(25),
    Notes VARCHAR(1024)
);

CREATE TABLE shippers_staging (
    ShipperId INT PRIMARY KEY,
    ShipperName VARCHAR(25),
    Phone VARCHAR(15)
);

CREATE TABLE orders_staging (
    OrderId INT PRIMARY KEY,
    CustomerId INT,
    EmployeeId INT,
    OrderDate TIMESTAMP,
    ShipperId INT,
    FOREIGN KEY (CustomerId) REFERENCES customers_staging(CustomerId),
    FOREIGN KEY (EmployeeId) REFERENCES employees_staging(EmployeeId),
    FOREIGN KEY (ShipperId) REFERENCES shippers_staging(ShipperId)
);

CREATE TABLE orderdetails_staging (
    OrderDetailId INT PRIMARY KEY,
    OrderId INT,
    ProductId INT,
    Quantity INT,
    FOREIGN KEY (OrderId) REFERENCES orders_staging(OrderId),
    FOREIGN KEY (ProductId) REFERENCES products_staging(ProductId)
);

SHOW TABLES;

-- Vytvorenie my_stage pre .csv súbory
CREATE OR REPLACE STAGE my_stage;

-- Načitanie údajov z tabuliek uložených v my_stage do staging tabuliek
COPY INTO suppliers_staging
FROM @my_stage/suppliers.csv
FILE_FORMAT = (TYPE = 'CSV' FIELD_OPTIONALLY_ENCLOSED_BY = '"' SKIP_HEADER = 1);

COPY INTO categories_staging
FROM @my_stage/categories.csv
FILE_FORMAT = (TYPE = 'CSV' FIELD_OPTIONALLY_ENCLOSED_BY = '"' SKIP_HEADER = 1);

COPY INTO products_staging
FROM @my_stage/products.csv
FILE_FORMAT = (TYPE = 'CSV' FIELD_OPTIONALLY_ENCLOSED_BY = '"' SKIP_HEADER = 1);

COPY INTO customers_staging
FROM @my_stage/customers.csv
FILE_FORMAT = (TYPE = 'CSV' FIELD_OPTIONALLY_ENCLOSED_BY = '"' SKIP_HEADER = 1);

COPY INTO employees_staging
FROM @my_stage/employees.csv
FILE_FORMAT = (TYPE = 'CSV' FIELD_OPTIONALLY_ENCLOSED_BY = '"' SKIP_HEADER = 1);

COPY INTO shippers_staging
FROM @my_stage/shippers.csv
FILE_FORMAT = (TYPE = 'CSV' FIELD_OPTIONALLY_ENCLOSED_BY = '"' SKIP_HEADER = 1);

COPY INTO orders_staging
FROM @my_stage/orders.csv
FILE_FORMAT = (TYPE = 'CSV' FIELD_OPTIONALLY_ENCLOSED_BY = '"' SKIP_HEADER = 1);

COPY INTO orderdetails_staging
FROM @my_stage/orderdetails.csv
FILE_FORMAT = (TYPE = 'CSV' FIELD_OPTIONALLY_ENCLOSED_BY = '"' SKIP_HEADER = 1);

--- ELT - Transformácia údajov
-- Dimenzionálne tabuľky 
CREATE OR REPLACE TABLE dim_customers AS
SELECT DISTINCT
    CustomerId AS customerId,
    CustomerName AS customer_name,
    ContactName AS contact_name,
    Address AS address,
    City AS city,
    Country AS country,
    PostalCode AS postal_code
FROM customers_staging;

CREATE OR REPLACE TABLE dim_shippers AS
SELECT DISTINCT
    ShipperId AS shippersId,
    ShipperName AS shipper_name,
    Phone AS phone
FROM shippers_staging;

CREATE OR REPLACE TABLE dim_employees AS
SELECT DISTINCT
    EmployeeId AS employeesId,
    FirstName AS first_name,
    LastName AS last_name,
    BirthDate AS birth_date,
    CASE 
        WHEN DATE_PART(year, CURRENT_DATE) - DATE_PART(year, BirthDate) < 20 THEN 'Pod 20 rokov'
        WHEN DATE_PART(year, CURRENT_DATE) - DATE_PART(year, BirthDate) BETWEEN 20 AND 29 THEN '20-29 rokov'
        WHEN DATE_PART(year, CURRENT_DATE) - DATE_PART(year, BirthDate) BETWEEN 30 AND 39 THEN '30-39 rokov'
        WHEN DATE_PART(year, CURRENT_DATE) - DATE_PART(year, BirthDate) BETWEEN 40 AND 49 THEN '40-49 rokov'
        WHEN DATE_PART(year, CURRENT_DATE) - DATE_PART(year, BirthDate) >= 50 THEN '50 a viac rokov'
        ELSE 'Neznáme'
    END AS age_group
FROM employees_staging;

CREATE OR REPLACE TABLE dim_products AS
SELECT DISTINCT
    ProductId AS productsId,
    ProductName AS product_name,
    COALESCE(CategoryName, 'Neznáma kategória') AS category_name,
    COALESCE(SupplierName, 'Neznámy dodávateľ') AS supplier_name,
    Price AS price,
    CASE 
        WHEN Price < 20 THEN 'Nízka'
        WHEN Price BETWEEN 20 AND 50 THEN 'Stredná'
        WHEN Price > 50 THEN 'Vysoká'
        ELSE 'Neznáme'
    END AS price_category,
    CURRENT_DATE AS valid_from,
    NULL AS valid_to
FROM products_staging
LEFT JOIN categories_staging ON products_staging.CategoryId = categories_staging.CategoryId
LEFT JOIN suppliers_staging ON products_staging.SupplierId = suppliers_staging.SupplierId;

CREATE OR REPLACE TABLE dim_date AS
SELECT DISTINCT
    ROW_NUMBER() OVER (ORDER BY OrderDate) AS datedId,
    TO_DATE(OrderDate) AS order_date,
    DATE_PART('day', OrderDate) AS den,
    DATE_PART('month', OrderDate) AS mesiac,
    DATE_PART('year', OrderDate) AS rok,
    CASE
        WHEN DATE_PART('month', OrderDate) IN (12, 1, 2) THEN 'Zima'
        WHEN DATE_PART('month', OrderDate) IN (3, 4, 5) THEN 'Jar'
        WHEN DATE_PART('month', OrderDate) IN (6, 7, 8) THEN 'Leto'
        WHEN DATE_PART('month', OrderDate) IN (9, 10, 11) THEN 'Jeseň'
        ELSE 'Neznáme'
    END AS sezona,
    CASE (DATE_PART('dow', OrderDate) + 1)
        WHEN 1 THEN 'Pondelok'
        WHEN 2 THEN 'Utorok'
        WHEN 3 THEN 'Streda'
        WHEN 4 THEN 'Štvrtok'
        WHEN 5 THEN 'Piatok'
        WHEN 6 THEN 'Sobota'
        WHEN 7 THEN 'Nedeľa'
    END AS den_v_tyzdni
FROM orders_staging;

-- Faktová tabuľka Orderdetails
CREATE OR REPLACE TABLE fact_orderdetails AS
SELECT
    od.OrderDetailId AS orderdetails_id,
    o.OrderId AS order_id,
    c.customerId AS customer_id,
    e.employeesId AS employee_id,
    p.productsId AS product_id,
    s.shippersId AS shipper_id,
    d.datedId AS date_id,
    od.Quantity AS quantity,
    od.Quantity * p.Price AS total_price
FROM orderdetails_staging od
JOIN orders_staging o ON od.OrderId = o.OrderId
JOIN dim_customers c ON o.CustomerId = c.customerId
JOIN dim_employees e ON o.EmployeeId = e.employeesId
JOIN dim_products p ON od.ProductId = p.productsId
JOIN dim_shippers s ON o.ShipperId = s.shippersId
JOIN dim_date d ON TO_DATE(o.OrderDate) = d.order_date;

-- Na koniec dropneme všetky staging tabuľky kvôli zataženiu systému
DROP TABLE IF EXISTS suppliers_staging;
DROP TABLE IF EXISTS categories_staging;
DROP TABLE IF EXISTS products_staging;
DROP TABLE IF EXISTS customers_staging;
DROP TABLE IF EXISTS employees_staging;
DROP TABLE IF EXISTS shippers_staging;
DROP TABLE IF EXISTS orders_staging;
DROP TABLE IF EXISTS orderdetails_staging;
