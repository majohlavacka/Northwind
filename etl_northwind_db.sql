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

-- Vytvorenie tabulky suppliers (staging)
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

-- Vytvorenie tabulky categories (staging)
CREATE TABLE categories_staging (
    CategoryId INT PRIMARY KEY,
    CategoryName VARCHAR(25),
    Description VARCHAR(255)
);

-- Vytvorenie tabulky products (staging)
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

-- Vytvorenie tabulky customers (staging)
CREATE TABLE customers_staging (
    CustomerId INT PRIMARY KEY,
    CustomerName VARCHAR(50),
    ContactName VARCHAR(50),
    Address VARCHAR(50),
    City VARCHAR(20),
    PostalCode VARCHAR(10),
    Country VARCHAR(15)
);

-- Vytvorenie tabulky employees (staging)
CREATE TABLE employees_staging (
    EmployeeId INT PRIMARY KEY,
    LastName VARCHAR(15),
    FirstName VARCHAR(15),
    BirthDate TIMESTAMP,
    Photo VARCHAR(25),
    Notes VARCHAR(1024)
);

-- Vytvorenie tabulky shippers (staging)
CREATE TABLE shippers_staging (
    ShipperId INT PRIMARY KEY,
    ShipperName VARCHAR(25),
    Phone VARCHAR(15)
);

-- Vytvorenie tabulky orders (staging)
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

-- Vytvorenie tabulky orderdetails (staging)
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
