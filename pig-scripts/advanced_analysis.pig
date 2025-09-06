-- Analyse avancée avec jointures et agrégations complexes
sales_data = LOAD '/data/sales_data.csv' USING PigStorage(',') 
AS (date:chararray, product:chararray, category:chararray, 
    quantity:int, price:float, customer_id:chararray, region:chararray);

sales_clean = FILTER sales_data BY date != 'date';

-- Analyse temporelle (par mois)
sales_with_month = FOREACH sales_clean GENERATE 
    SUBSTRING(date, 0, 7) AS month,
    product,
    category,
    quantity,
    price,
    (quantity * price) AS total_value,
    customer_id,
    region;

monthly_sales = GROUP sales_with_month BY month;
monthly_summary = FOREACH monthly_sales GENERATE 
    group AS month,
    COUNT(sales_with_month) AS total_transactions,
    SUM(sales_with_month.total_value) AS monthly_revenue,
    AVG(sales_with_month.total_value) AS avg_transaction_value;

STORE monthly_summary INTO '/output/monthly_analysis' USING PigStorage(',');

-- Analyse des clients
customer_analysis = GROUP sales_clean BY customer_id;
customer_summary = FOREACH customer_analysis GENERATE 
    group AS customer_id,
    COUNT(sales_clean) AS purchase_frequency,
    SUM(sales_clean.quantity * sales_clean.price) AS customer_lifetime_value;

valuable_customers = FILTER customer_summary BY customer_lifetime_value > 1500;
STORE valuable_customers INTO '/output/valuable_customers' USING PigStorage(',');

DUMP monthly_summary;