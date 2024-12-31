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
    Unit VARCHAR(25),
    Price DECIMAL(10,0),
    SupplierId INT,
    CategoryId INT,
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
    City VARCHAR(20),
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
    OrdersId INT PRIMARY KEY,
    OrderDate TIMESTAMP,
    CustomerId INT,
    EmployeeId INT,
    ShipperId INT,
    FOREIGN KEY (CustomerId) REFERENCES customers_staging(CustomerId),
    FOREIGN KEY (EmployeeId) REFERENCES employees_staging(EmployeeId),
    FOREIGN KEY (ShipperId) REFERENCES shippers_staging(ShipperId)
);

-- Vytvorenie tabulky orderdetails (staging)
CREATE TABLE orderdetails_staging (
    OrderDetailId INT PRIMARY KEY,
    Quantity INT,
    OrderId INT,
    ProductId INT,
    FOREIGN KEY (OrderId) REFERENCES orders_staging(OrdersId),
    FOREIGN KEY (ProductId) REFERENCES products_staging(ProductId)
);

SHOW TABLES;
