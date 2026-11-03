-- Purpose: Find the time span of the data and spot partial months, which
--          look like false dips in monthly trends.
-- Result (2 Nov 2026): 2019-01-14 to 2026-10-29 at the time of the query.
--          The dataset refreshes over time, so the end date can move.

SELECT
  MIN(created_at) AS first_order,
  MAX(created_at) AS last_order
FROM `bigquery-public-data.thelook_ecommerce.orders`;

-- Purpose: List order item statuses and their share, to decide which
--          statuses count as revenue.
-- Result: Shipped 30.0% | Complete 25.2% | Processing 19.8%
--         | Cancelled 15.0% | Returned 10.0%

SELECT
  status,
  COUNT(*) AS item_count,
  ROUND(100 * COUNT(*) / SUM(COUNT(*)) OVER (), 1) AS pct_of_total
FROM `bigquery-public-data.thelook_ecommerce.order_items`
GROUP BY status
ORDER BY item_count DESC;


-- Purpose: Check order_items for duplicate rows, missing keys, and invalid
--          prices, which silently distort revenue totals.
-- Result: 180,746 rows, 180,746 distinct ids, 0 nulls in order_id,
--         product_id and sale_price, 0 non-positive prices.

SELECT
  COUNT(*) AS total_rows,
  COUNT(DISTINCT id) AS distinct_ids,
  COUNTIF(order_id IS NULL) AS null_order_id,
  COUNTIF(product_id IS NULL) AS null_product_id,
  COUNTIF(sale_price IS NULL) AS null_sale_price,
  COUNTIF(sale_price <= 0) AS non_positive_price
FROM `bigquery-public-data.thelook_ecommerce.order_items`;

-- Purpose: Confirm every order item links to an order and a product, and
--          that the joins do not change the row count (no fan-out).
-- Result: 180,746 rows after joining, 0 items without an order,
--         0 items without a product.

SELECT
  COUNT(*) AS total_items,
  COUNTIF(o.order_id IS NULL) AS items_without_order,
  COUNTIF(p.id IS NULL) AS items_without_product
FROM `bigquery-public-data.thelook_ecommerce.order_items` AS oi
LEFT JOIN `bigquery-public-data.thelook_ecommerce.orders` AS o
  ON oi.order_id = o.order_id
LEFT JOIN `bigquery-public-data.thelook_ecommerce.products` AS p
  ON oi.product_id = p.id;
