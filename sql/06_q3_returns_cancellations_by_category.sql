
-- ============================================================
-- Question 3a: Returns and Cancellations by Category
-- ============================================================
-- Business question:
-- Which product categories have the highest return and
-- cancellation rates?
--
-- Return rate:
-- Returned items / Fulfilled items
-- (Complete, Shipped, Returned)
--
-- Cancellation rate:
-- Cancelled items / All ordered items
--
-- Returned value:
-- Original sale price of returned items.
--
-- Analysis window: Uses the in_window flag defined
-- in the enriched view.
-- ============================================================

SELECT
  category,
  COUNT(*) AS total_items,
  COUNTIF(status = 'Returned') AS returned_items,
  ROUND(100 * SAFE_DIVIDE(
    COUNTIF(status = 'Returned'),
    COUNTIF(status IN ('Complete', 'Shipped', 'Returned'))
  ), 1) AS return_rate_pct,
  ROUND(100 * COUNTIF(status = 'Cancelled') / COUNT(*), 1) AS cancel_rate_pct,
  ROUND(SUM(IF(status = 'Returned', sale_price, 0)), 0) AS returned_value
FROM `project-583f9618-c8dc-4022-835.thelook_analysis.vw_order_items_enriched`
WHERE in_window
GROUP BY category
ORDER BY returned_value DESC;

-- ============================================================
-- Question 3b: Returns and Cancellations by Brand
-- ============================================================
-- Business question:
-- Do certain brands have unusually high return or
-- cancellation rates?
--
-- Minimum sample size:
-- 500 fulfilled items per brand.
--
-- This threshold reduces volatility from very small
-- samples but does not establish statistical significance.
--
-- Results:
-- Top 15 brands ranked by return rate.
-- ============================================================
SELECT
  brand,
  COUNTIF(status IN ('Complete', 'Shipped', 'Returned')) AS shipped_items,
  COUNTIF(status = 'Returned') AS returned_items,
  ROUND(100 * SAFE_DIVIDE(
    COUNTIF(status = 'Returned'),
    COUNTIF(status IN ('Complete', 'Shipped', 'Returned'))
  ), 1) AS return_rate_pct,
  ROUND(100 * COUNTIF(status = 'Cancelled') / COUNT(*), 1) AS cancel_rate_pct
FROM `project-583f9618-c8dc-4022-835.thelook_analysis.vw_order_items_enriched`
WHERE in_window
GROUP BY brand
HAVING COUNTIF(status IN ('Complete', 'Shipped', 'Returned')) >= 500
ORDER BY return_rate_pct DESC
LIMIT 15;
