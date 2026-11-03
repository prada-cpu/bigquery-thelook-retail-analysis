-- ============================================================
-- Question 1: Is the business growing, and is there seasonality?
-- Replace YOUR_PROJECT_ID with your own project ID.
-- ============================================================


-- 1a. Monthly revenue, orders, AOV, margin % and month-over-month growth.
-- Finding: steady growth to Jan 2026, then faster from Feb 2026 (monthly
-- item growth roughly 4% -> 9%). Margin stable at about 52%, so growth is
-- driven by volume, not by higher margins.
WITH monthly AS (
  SELECT
    order_month,
    SUM(sale_price) AS revenue,
    COUNT(DISTINCT order_id) AS orders,
    SUM(margin) AS gross_margin
  FROM `YOUR_PROJECT_ID.thelook_analysis.vw_order_items_enriched`
  WHERE is_revenue AND in_window
  GROUP BY order_month
)
SELECT
  order_month,
  ROUND(revenue, 0) AS revenue,
  orders,
  ROUND(revenue / orders, 2) AS aov,
  ROUND(100 * gross_margin / revenue, 1) AS margin_pct,
  ROUND(
    100 * (revenue - LAG(revenue) OVER (ORDER BY order_month))
        / LAG(revenue) OVER (ORDER BY order_month),
    1
  ) AS mom_growth_pct
FROM monthly
ORDER BY order_month;


-- 1b. Status mix by month since Jun 2025 (deliberately NOT filtered by
-- in_window, so the October surge is visible).
-- Finding: the mix of statuses is stable (about 25% Complete, 31% Shipped,
-- 20% Processing, 10% Returned, 15% Cancelled), so counting Shipped as
-- revenue does not distort the trend, and the Feb 2026 acceleration is a
-- genuine rise in order volume.
SELECT
  order_month,
  COUNTIF(status = 'Complete') AS complete_items,
  COUNTIF(status = 'Shipped') AS shipped_items,
  COUNTIF(status = 'Processing') AS processing_items,
  COUNTIF(status = 'Returned') AS returned_items,
  COUNTIF(status = 'Cancelled') AS cancelled_items
FROM `YOUR_PROJECT_ID.thelook_analysis.vw_order_items_enriched`
WHERE order_month >= DATE '2025-06-01'
GROUP BY order_month
ORDER BY order_month;


-- 1c. Seasonality index: each calendar month vs. its own year's average,
-- averaged over the complete years 2020-2025.
-- Caveat: the business grows through each year, so later months score
-- higher regardless of season. Read this together with 1d.
WITH monthly AS (
  SELECT order_month, SUM(sale_price) AS revenue
  FROM `YOUR_PROJECT_ID.thelook_analysis.vw_order_items_enriched`
  WHERE is_revenue
    AND order_month BETWEEN DATE '2020-01-01' AND DATE '2025-12-01'
  GROUP BY order_month
),
with_year AS (
  SELECT
    EXTRACT(MONTH FROM order_month) AS mth,
    revenue,
    AVG(revenue) OVER (PARTITION BY EXTRACT(YEAR FROM order_month)) AS year_avg
  FROM monthly
)
SELECT
  mth,
  ROUND(AVG(revenue / year_avg), 2) AS seasonality_index
FROM with_year
GROUP BY mth
ORDER BY mth;


-- 1d. Spike index: each month vs. the average of the month before and
-- after, which cancels out a steady growth trend.
-- Finding: October is the clearest spike (1.118), February the weakest
-- period (0.911). No September spike (0.92).
-- Caveat: a dip beside a spike (Sep and Nov around Oct) is partly an
-- artifact of the method.
WITH monthly AS (
  SELECT order_month, SUM(sale_price) AS revenue
  FROM `YOUR_PROJECT_ID.thelook_analysis.vw_order_items_enriched`
  WHERE is_revenue AND in_window
  GROUP BY order_month
),
neighbors AS (
  SELECT
    order_month,
    revenue,
    (LAG(revenue) OVER (ORDER BY order_month)
     + LEAD(revenue) OVER (ORDER BY order_month)) / 2 AS neighbor_avg
  FROM monthly
)
SELECT
  EXTRACT(MONTH FROM order_month) AS mth,
  ROUND(AVG(revenue / neighbor_avg), 3) AS spike_index,
  COUNT(*) AS years_counted
FROM neighbors
WHERE order_month BETWEEN DATE '2020-01-01' AND DATE '2025-12-01'
GROUP BY mth
ORDER BY mth;


-- 1e. September, year by year, using the same neighbor logic as 1d.
-- Finding: every year 2020-2025 scores below 1.00 (0.83 to 0.98), so there
-- is no consistent September spike. 2019 (1.242) is not meaningful because
-- the business was tiny and growing very fast. 2026 is null because there
-- is no October inside the window.
WITH monthly AS (
  SELECT order_month, SUM(sale_price) AS revenue
  FROM `YOUR_PROJECT_ID.thelook_analysis.vw_order_items_enriched`
  WHERE is_revenue AND in_window
  GROUP BY order_month
)
SELECT
  order_month,
  ROUND(revenue / ((LAG(revenue) OVER (ORDER BY order_month)
                   + LEAD(revenue) OVER (ORDER BY order_month)) / 2), 3) AS spike_index
FROM monthly
QUALIFY EXTRACT(MONTH FROM order_month) = 9
ORDER BY order_month;


-- 1f. Daily volume from mid-September 2026 (deliberately NOT filtered by
-- in_window). Used to investigate why October 2026 jumped 79% over
-- September.
-- Finding: volume rises gradually through 22 Oct (about 265 -> about 350
-- items a day), then surges from 23 Oct, peaking at 1,764 items on 28 Oct,
-- before falling back. These 9 days hold about half of October's items, and
-- the build-up-and-decay shape does not look like customer behaviour. It is
-- treated as a probable data-generation artifact and excluded via in_window.
SELECT
  order_date,
  COUNT(*) AS items,
  COUNT(DISTINCT order_id) AS orders
FROM `YOUR_PROJECT_ID.thelook_analysis.vw_order_items_enriched`
WHERE order_date >= DATE '2026-09-15'
GROUP BY order_date
ORDER BY order_date;
