-- Graf 1: TOP 10 najviac predávaných produktov 
SELECT 
   p.product_name, 
   SUM(od.quantity) AS total_quantity
FROM fact_orderdetails od
  JOIN dim_products p ON od.product_id = p.productsId
GROUP BY p.product_name
ORDER BY total_quantity DESC
LIMIT 10;

-- Graf 2: Objem objednávok podľa časového obdobia
SELECT 
    d.rok, 
    d.mesiac, 
    SUM(od.total_price) AS monthly_sales
FROM fact_orderdetails od
JOIN dim_date d ON od.date_id = d.datedId
GROUP BY d.rok, d.mesiac
ORDER BY d.rok, d.mesiac;

-- Graf 3: Počet objednávok podľa cenových kategórií produktov
SELECT 
   p.price_category, 
   COUNT(od.order_id) AS total_orders
FROM fact_orderdetails od
JOIN dim_products p ON od.product_id = p.productsId
GROUP BY p.price_category
ORDER BY total_orders DESC;

-- Graf 4: Trend predaja podľa sezón
SELECT 
   d.sezona, 
   SUM(od.total_price) AS total_sales
FROM fact_orderdetails od
JOIN dim_date d ON od.date_id = d.datedId
GROUP BY d.sezona
ORDER BY total_sales DESC;

-- Graf 5: Počet objednávok podľa prepravných spoločností
SELECT 
    s.shipper_name, 
    COUNT(od.order_id) AS total_orders
FROM fact_orderdetails od
JOIN dim_shippers s ON od.shipper_id = s.shippersId
GROUP BY s.shipper_name
ORDER BY total_orders DESC;