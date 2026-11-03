-- I ran this first to see how big each table is. Later, after I join tables
-- together, I can compare the row count against these numbers to make sure
-- the join didn't add or lose rows.
-- I left out the events table because it's by far the biggest and I don't
-- need it for this analysis.
-- What I found (2 Nov 2026): orders 124,452 | order_items 180,746 |
-- products 29,120 | users 100,000 | inventory_items 487,914 |
-- distribution_centers 10

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
