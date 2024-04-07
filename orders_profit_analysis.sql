-- Identify the databse
USE [ORDER_DATA]
GO

/* Overall observation */
SELECT * FROM Orders;

/* Summarise profit per customer by product category */
SELECT
    o.customer_name,
    SUM(case when product_category = 'Office Supplies' then o.profit else NULL end) as "Office Supplies",
    SUM(case when product_category = 'Furniture' then o.profit else NULL end) as "Furniture",
    SUM(case when product_category = 'Technology' then o.profit else NULL end) as "Technology"
FROM dbo.Orders o
GROUP BY o.customer_name;

/* Calcuate order and sales value per year by category */
SELECT
    YEAR(o.order_date) as order_year,
    COUNT(DISTINCT case when category = 'Office Supplies' then o.order_id else NULL end) as total_order_office_supply,
    COUNT(DISTINCT case when category = 'Furniture' then o.order_id else NULL end) as total_order_furniture,
    COUNT(DISTINCT case when category = 'Technology' then o.order_id else NULL end) as total_order_technolofgy,
    SUM(case when category = 'Office Supplies' then CAST(o.sales as float) else 0 end) as total_sales_office_supply,
    SUM(case when category = 'Furniture' then CAST(o.sales as float) else 0 end) as total_sales_furniture,
    SUM(case when category = 'Technology' then CAST(o.sales as float) else 0 end) as total_sales_technolofgy
FROM dbo.sales_data_sample AS o
GROUP BY YEAR(o.order_date);

/* Get top 10 oders by profit, also show province information */
WITH order_cte AS (
    SELECT order_id, 
        SUM(profit) as profit, 
        province
    FROM Orders
    GROUP BY province, order_id
)
SELECT TOP(10) order_id, 
    ROUND(profit, 2) as profit, 
    province,
    DENSE_RANK() OVER(ORDER BY profit DESC) as rank
FROM order_cte;

/* Get orders having highest profit for each province */
WITH CTE AS (
    SELECT province, 
        order_id, 
        ROUND(profit, 2) as profit,
        DENSE_RANK() OVER(PARTITION BY province ORDER BY profit DESC) as rank
    FROM Orders
)
SELECT * FROM CTE 
WHERE rank = 1;

/* Get top 3 product categories having the highest profit for each province */
WITH CTE AS (
    SELECT province, 
        product_category, 
        SUM(profit) as total_profit
    FROM Orders
    GROUP BY province, product_category
)
SELECT *,
    ROW_NUMBER() OVER(PARTITION BY province ORDER BY total_profit DESC) as rank
FROM CTE;

/* Calculate sum of profit for each category per province */
SELECT o.province as "Province", 
    ROUND(SUM(CASE WHEN o.product_category = 'Office Supplies' THEN o.profit ELSE 0 END), 4) AS "Office Supplies",
    ROUND(SUM(CASE WHEN o.product_category = 'Furniture' THEN o.profit ELSE 0 END), 4) AS "Furniture",
    ROUND(SUM(CASE WHEN o.product_category = 'Technology' THEN o.profit ELSE 0 END), 4) AS "Technology"
FROM Orders AS o
GROUP BY o.province
ORDER BY o.province ASC;

/* Get top 3 product names having the lowest profit for each product category */
WITH order_cte AS (
    SELECT product_category, product_name,
        SUM(profit) as total_profit
    FROM Orders
    GROUP BY product_category, product_name
), final AS (
    SELECT *, 
        ROW_NUMBER() OVER(PARTITION BY product_category ORDER BY total_profit ASC) AS bottom_rank
    FROM order_cte
)
SELECT product_category as "Product Category", 
    product_name as "Product Name", 
    ROUND(total_profit, 2) as "Total Profit", 
    bottom_rank as "Bottom Rank"
FROM final
WHERE bottom_rank in (1, 2, 3);

/* Identify product namnes having 3rd rank by profit per provine */
WITH order_cte AS (
    SELECT province, product_name,
        SUM(profit) as total_profit
    FROM Orders
    GROUP BY province, product_name
), final_cte AS (
    SELECT *, 
        DENSE_RANK() OVER(PARTITION BY province ORDER BY total_profit DESC) AS top_rank
    FROM order_cte
)
SELECT province, 
    product_name, 
    ROUND(total_profit, 2) as total_profit, 
    top_rank
FROM final_cte
WHERE top_rank = 3

/* Identify product namnes having bottom rank of 3rd by profit per provine */
WITH order_cte AS (
    SELECT province, product_name,
        SUM(profit) as total_profit
    FROM Orders
    GROUP BY province, product_name
), final_cte AS (
    SELECT *, 
        RANK() OVER(PARTITION BY province ORDER BY total_profit ASC) AS bottom_rank
    FROM order_cte
)
SELECT province, product_name, ROUND(total_profit, 2) as total_profit, bottom_rank
FROM final_cte
WHERE bottom_rank = 3;