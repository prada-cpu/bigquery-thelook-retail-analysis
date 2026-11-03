-- I wanted to know what dates the data covers. The first and last months
-- can be incomplete, which makes them look like a drop in sales when
-- they aren't.
-- What I found: 14 Jan 2019 to 29 Oct 2026 when I ran it. The dataset gets
-- refreshed, so the end date can change.

SELECT
  MIN(created_at) AS first_order,
  MAX(created_at) AS last_order
FROM `bigquery-public-data.thelook_ecommerce.orders`;

-- I wanted to see what statuses an order item can have and how common each
-- one is, so I could decide which ones count as real revenue.
-- What I found: Shipped 30.0%, Complete 25.2%, Processing 19.8%,
-- Cancelled 15.0%, Returned 10.0%.

SELECT
  status,
  COUNT(*) AS item_count,
  ROUND(100 * COUNT(*) / SUM(COUNT(*)) OVER (), 1) AS pct_of_total
FROM `bigquery-public-data.thelook_ecommerce.order_items`
GROUP BY status
ORDER BY item_count DESC;


-- I checked order_items for repeated rows, missing values and bad prices
-- before trusting any totals, because any of these would quietly throw
-- off revenue.
-- What I found: no repeated rows (180,746 rows and 180,746 unique ids),
-- no missing order_id, product_id or sale_price, and no prices at zero
-- or below.
SELECT
  COUNT(*) AS total_rows,
  COUNT(DISTINCT id) AS distinct_ids,
  COUNTIF(order_id IS NULL) AS null_order_id,
  COUNTIF(product_id IS NULL) AS null_product_id,
  COUNTIF(sale_price IS NULL) AS null_sale_price,
  COUNTIF(sale_price <= 0) AS non_positive_price
FROM `bigquery-public-data.thelook_ecommerce.order_items`;

-- I checked that every order item matches a real order and a real product,
-- and that joining the tables doesn't change the number of rows.
-- What I found: still 180,746 rows after joining, and no items without a
-- matching order or product.
SELECT
  COUNT(*) AS total_items,
  COUNTIF(o.order_id IS NULL) AS items_without_order,
  COUNTIF(p.id IS NULL) AS items_without_product
FROM `bigquery-public-data.thelook_ecommerce.order_items` AS oi
LEFT JOIN `bigquery-public-data.thelook_ecommerce.orders` AS o
  ON oi.order_id = o.order_id
LEFT JOIN `bigquery-public-data.thelook_ecommerce.products` AS p
  ON oi.product_id = p.id;
