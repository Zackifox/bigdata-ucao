-- Chargement des données de ventes
sales_data = LOAD '/data/sales_data.csv' USING PigStorage(',') 
AS (date:chararray, product:chararray, category:chararray, 
    quantity:int, price:float, customer_id:chararray, region:chararray);

-- Suppression de l'en-tête
sales_clean = FILTER sales_data BY date != 'date';

-- 1. Analyse des ventes par catégorie
sales_by_category = GROUP sales_clean BY category;
category_summary = FOREACH sales_by_category GENERATE 
    group AS category,
    COUNT(sales_clean) AS total_orders,
    SUM(sales_clean.quantity) AS total_quantity,
    AVG(sales_clean.price) AS avg_price;

STORE category_summary INTO '/output/category_analysis' USING PigStorage(',');

-- 2. Top 5 des produits les plus vendus
product_sales = GROUP sales_clean BY product;
product_summary = FOREACH product_sales GENERATE 
    group AS product,
    SUM(sales_clean.quantity) AS total_sold;

top_products = ORDER product_summary BY total_sold DESC;
top_5_products = LIMIT top_products 5;

STORE top_5_products INTO '/output/top_products' USING PigStorage(',');

-- 3. Analyse régionale
regional_sales = GROUP sales_clean BY region;
regional_summary = FOREACH regional_sales GENERATE 
    group AS region,
    COUNT(sales_clean) AS orders_count,
    SUM(sales_clean.quantity * sales_clean.price) AS total_revenue;

STORE regional_summary INTO '/output/regional_analysis' USING PigStorage(',');

-- 4. Filtrage des ventes importantes (> 1000$)
high_value_sales = FILTER sales_clean BY (quantity * price) > 1000;
STORE high_value_sales INTO '/output/high_value_sales' USING PigStorage(',');

-- Affichage des résultats
DUMP category_summary;
DUMP top_5_products;
DUMP regional_summary;