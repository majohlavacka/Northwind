USE ROLE TRAINING_ROLE;
CREATE WAREHOUSE IF NOT EXISTS KANGAROO_WH;
USE WAREHOUSE KANGAROO_WH;

SHOW WAREHOUSES;
ALTER WAREHOUSE KANGAROO_WH RESUME;

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

--- ELT - (T)ransform

CREATE OR REPLACE TABLE fact_orderdetails AS
SELECT
    od.OrderDetailId AS orderdetails_id,
    od.Quantity AS quantity,
    od.ProductId AS productId,
    od.OrderId AS orderId,
    p.Price AS price,
    c.CustomerId AS customerId,
    e.EmployeeId AS employeeId,
    s.ShipperId AS shipperId,
    d.order_date AS dateId
FROM orderdetails_staging od
JOIN products_staging p ON od.ProductId = p.ProductId
JOIN orders_staging o ON od.OrderId = o.OrderId
JOIN customers_staging c ON o.CustomerId = c.CustomerId
JOIN employees_staging e ON o.EmployeeId = e.EmployeeId
JOIN shippers_staging s ON o.ShipperId = s.ShipperId
JOIN dim_date d ON TO_DATE(o.OrderDate) = d.order_date;

-- DROP stagging tables
DROP TABLE IF EXISTS suppliers_staging;
DROP TABLE IF EXISTS categories_staging;
DROP TABLE IF EXISTS products_staging;
DROP TABLE IF EXISTS customers_staging;
DROP TABLE IF EXISTS employees_staging;
DROP TABLE IF EXISTS shippers_staging;
DROP TABLE IF EXISTS orders_staging;
DROP TABLE IF EXISTS orderdetails_staging;
