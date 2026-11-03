-- This view joins order items to products and users once, so my later
-- queries don't need to repeat the joins.
--
-- Setup: create a dataset called thelook_analysis in the US location (it
-- has to match where the public data is stored), then replace
-- YOUR_PROJECT_ID with your own project ID.
--
-- Rules I set up here so they're defined in one place:
--   is_revenue: only Complete and Shipped items count as revenue.
--               Processing, Cancelled and Returned don't.
--   margin:     sale price minus the product's cost, per item.
--   in_window:  only 2019-02-01 to 2026-09-30. I left out January 2019 and
--               November 2026 because those months are incomplete, and the
--               late-October 2026 spike because it looked unusual (I explain
--               it in the Question 1 file).
--
-- Check: the view has 180,746 rows, the same as order_items, and 166,541 of
-- them are inside the window. No missing categories, costs or traffic
-- sources.


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
