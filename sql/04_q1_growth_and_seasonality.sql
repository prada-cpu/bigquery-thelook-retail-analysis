-- ============================================================
-- Question 1: Is the business growing, and is there seasonality?
-- ============================================================

-- 1a. Monthly revenue, number of orders, average order value, margin %, and
-- how much revenue changed from the previous month.
-- What I found: revenue grew steadily until January 2026, then picked up
-- speed from February 2026 (item growth went from roughly 4% to 9% a
-- month). Margin stayed around 52%, so the growth came from selling more,
-- not from earning more per sale.

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

-- 1b. Status mix by month since June 2025. I didn't use the in_window filter
-- here on purpose, so the October spike is still visible.
-- I wanted to check whether the faster growth was real or just caused by
-- counting Shipped orders as revenue.
-- What I found: the mix stayed about the same (roughly 25% Complete, 31%
-- Shipped, 20% Processing, 10% Returned, 15% Cancelled), so the growth is
-- real.

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


-- 1c. Seasonality check 1: compares each calendar month to the average of
-- its own year, then averages that over the full years 2020 to 2025.
-- Limitation: the business keeps growing through the year, so later months
-- score higher no matter what. That's why I added the next check.

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

-- 1d. Seasonality check 2: compares each month to the average of the month
-- before and the month after. Steady growth cancels out, so only real
-- spikes and dips show.
-- What I found: October is the clearest spike (1.118) and February is the
-- weakest (0.911). September doesn't spike (0.92).
-- Limitation: a month sitting next to a spike (like September and November
-- around October) can look like a dip just because of how this is
-- calculated.

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


-- 1e. I thought I saw a September spike on the chart, so I checked
-- September year by year using the same method as 1d.
-- What I found: every year from 2020 to 2025 came in below 1.00 (between
-- 0.83 and 0.98), so there's no consistent September spike. 2019 (1.242)
-- doesn't count because the business was tiny and growing very fast. 2026
-- is empty because there's no October inside the window to compare against.

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

-- 1f. Daily orders from mid-September 2026. I didn't use the in_window
-- filter here on purpose. October 2026 was 79% higher than September, and
-- I wanted to see why.
-- What I found: daily volume climbed gradually until 22 October (about 265
-- to about 350 items a day), then shot up from 23 October and peaked at
-- 1,764 items on 28 October before dropping back. Those 9 days make up
-- about half of October. It doesn't look like normal customer behaviour,
-- so I treated it as a likely data issue and left it out using in_window.

SELECT
  order_date,
  COUNT(*) AS items,
  COUNT(DISTINCT order_id) AS orders
FROM `YOUR_PROJECT_ID.thelook_analysis.vw_order_items_enriched`
WHERE order_date >= DATE '2026-09-15'
GROUP BY order_date
ORDER BY order_date;
