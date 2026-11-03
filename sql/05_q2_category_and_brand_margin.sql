-- Question 2: Which categories and brands look strong on revenue but weak
-- on margin?

-- 2a. Revenue, margin and rankings for every category.
-- I ranked margin by percentage, not dollars, because ranking by dollars
-- would just repeat the revenue ranking (big categories earn more margin
-- in dollars).
-- What I found: overall margin is 51.9%. Jeans is the clearest problem: 2nd
-- biggest category (11.8% of revenue) but 21st of 26 on margin (46.5%).
-- Tops & Tees (44.0%), Intimates (46.8%) and Fashion Hoodies & Sweatshirts
-- (48.0%) are also big categories with below-average margin. Outerwear &
-- Coats is strong on both (1st on revenue, 55.5% margin).
-- Note: some category labels overlap (Socks vs Socks & Hosiery, Suits vs
-- Suits & Sport Coats, Pants vs Pants & Capris) and their margins differ a
-- lot. I couldn't confirm they're the same products, so I left each label
-- as its own category.
SELECT
  category,
  ROUND(SUM(sale_price), 0) AS revenue,
  ROUND(SUM(margin), 0) AS gross_margin,
  ROUND(100 * SUM(margin) / SUM(sale_price), 1) AS margin_pct,
  ROUND(100 * SUM(sale_price) / SUM(SUM(sale_price)) OVER (), 1) AS revenue_share_pct,
  RANK() OVER (ORDER BY SUM(sale_price) DESC) AS revenue_rank,
  RANK() OVER (ORDER BY SUM(margin) / SUM(sale_price) DESC) AS margin_rank
FROM `YOUR_PROJECT_ID.thelook_analysis.vw_order_items_enriched`
WHERE in_window
  AND is_revenue
GROUP BY category
ORDER BY revenue DESC;


-- 2b. Top 10 brands by revenue inside the two weakest big categories, Jeans
-- and Tops & Tees, to see whether the low margin comes from a few brands or
-- the whole category. I included the item count so I can see how many items
-- each margin is based on.
-- What I found: it's the whole category. Every top-10 Jeans brand is
-- between 45.6% and 47.5%, and every top-10 Tops & Tees brand is between
-- 43.1% and 45.0%. Margin barely changes even though prices vary a lot
-- (about $45 to $245 per jeans item), so it looks like margin is set at the
-- category level in this data.
-- Limitation: the top 10 brands cover 57% of Jeans revenue but only 24% of
-- Tops & Tees revenue, so I can't speak for the smaller brands.
SELECT
  category,
  brand,
  ROUND(SUM(sale_price), 0) AS revenue,
  ROUND(100 * SUM(margin) / SUM(sale_price), 1) AS margin_pct,
  COUNT(*) AS items
FROM `YOUR_PROJECT_ID.thelook_analysis.vw_order_items_enriched`
WHERE in_window
  AND is_revenue
  AND category IN ('Jeans', 'Tops & Tees')
GROUP BY category, brand
QUALIFY RANK() OVER (PARTITION BY category ORDER BY SUM(sale_price) DESC) <= 10
ORDER BY category, revenue DESC;
