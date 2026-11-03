-- Purpose: Analysis layer. Joins order items to products and users once, so
--          every later query is a simple SELECT with no joins.
-- Setup:   Create a dataset named thelook_analysis in the US location (it
--          must match the public dataset's location), then replace
--          YOUR_PROJECT_ID with your own project ID.
--
-- Metric definitions (all defined here, in one place):
--   is_revenue : status is Complete or Shipped. Processing, Cancelled and
--                Returned are excluded.
--   margin     : sale_price minus products.cost, per item.
--   in_window  : 2019-02-01 to 2026-09-30. Excludes the partial first month
--                (Jan 2019), the partial last month (Nov 2026), and an
--                unexplained surge of orders from 23 Oct 2026 onward.
--
-- Validation: 180,746 rows (same as order_items), 166,541 inside the window,
--             0 null categories, costs or traffic sources.

CREATE OR REPLACE VIEW `YOUR_PROJECT_ID.thelook_analysis.vw_order_items_enriched` AS
SELECT
  oi.id AS order_item_id,
  oi.order_id,
  oi.user_id,
  oi.product_id,
  oi.status,
  oi.status IN ('Complete', 'Shipped') AS is_revenue,
  DATE(oi.created_at) AS order_date,
  DATE_TRUNC(DATE(oi.created_at), MONTH) AS order_month,
  DATE(oi.created_at) BETWEEN DATE '2019-02-01' AND DATE '2026-09-30' AS in_window,
  oi.sale_price,
  p.cost,
  oi.sale_price - p.cost AS margin,
  p.category,
  p.brand,
  p.department,
  u.traffic_source,
  u.country,
  u.age,
  u.gender
FROM `bigquery-public-data.thelook_ecommerce.order_items` AS oi
LEFT JOIN `bigquery-public-data.thelook_ecommerce.products` AS p
  ON oi.product_id = p.id
LEFT JOIN `bigquery-public-data.thelook_ecommerce.users` AS u
  ON oi.user_id = u.id;
