-- Purpose: Size each table before analysis, and give a baseline to compare
--          against after joins (a changed row count means a bad join).
-- Dataset: bigquery-public-data.thelook_ecommerce
-- Note: events is excluded on purpose because it is the largest table.
-- Result (2 Nov 2026): orders 124,452 | order_items 180,746 | products 29,120
--          | users 100,000 | inventory_items 487,914 | distribution_centers 10

SELECT 'orders' AS table_name, COUNT(*) AS row_count
FROM `bigquery-public-data.thelook_ecommerce.orders`
UNION ALL
SELECT 'order_items', COUNT(*)
FROM `bigquery-public-data.thelook_ecommerce.order_items`
UNION ALL
SELECT 'products', COUNT(*)
FROM `bigquery-public-data.thelook_ecommerce.products`
UNION ALL
SELECT 'users', COUNT(*)
FROM `bigquery-public-data.thelook_ecommerce.users`
UNION ALL
SELECT 'inventory_items', COUNT(*)
FROM `bigquery-public-data.thelook_ecommerce.inventory_items`
UNION ALL
SELECT 'distribution_centers', COUNT(*)
FROM `bigquery-public-data.thelook_ecommerce.distribution_centers`;
