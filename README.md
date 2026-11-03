# Retail analysis on BigQuery: TheLook eCommerce

I built this project to learn BigQuery by answering practical business questions with SQL. I already knew SQL, so I focused on what is specific to BigQuery: how it handles cost, how its tables are named, and how its SQL differs from what I'd used before.

I'm a BI analyst building my skills in BigQuery and cloud data warehousing. I chose a retail dataset because retail questions (growth, margins, returns, customer loyalty) are the ones businesses ask most, and I wanted to practice answering them end to end: checking the data, defining the metrics, and explaining what I found.

## The data

I used the public dataset `bigquery-public-data.thelook_ecommerce`, a made-up online clothing store with orders, order items, products, users and inventory.

**This data is synthetic.** The findings show how I approach an analysis, not what is true about a real business.

| Table | Rows (2 Nov 2026) |
|---|---|
| orders | 124,452 |
| order_items | 180,746 |
| products | 29,120 |
| users | 100,000 |
| inventory_items | 487,914 |
| distribution_centers | 10 |

The dataset gets refreshed over time, so the row counts and the latest date can change.

## How I worked

1. **Checked the data first.** Row counts, date range, order statuses, duplicates, missing values, and whether the joins between tables keep the row count the same. Everything came back clean.
2. **Built one view** that joins order items to products and users once, so my later queries stay short.
3. **Wrote queries for each business question**, and kept the reasoning in comments in the SQL files.

## The rules I set

I defined these once, inside the view (`sql/03_view_order_items_enriched.sql`), so every query uses the same definitions.

- **Revenue** counts only items with status **Complete** or **Shipped**. Processing items haven't shipped yet, Cancelled items never happened, and Returned items were refunded.
- **Margin** is the sale price minus the product's cost, per item. I used the cost from the products table.
- **Analysis window** runs from 1 Feb 2019 to 30 Sep 2026. I left out January 2019 and November 2026 because those months are incomplete, and late October 2026 because of the data issue explained below.
- Dates use UTC, which is how BigQuery stores timestamps.

## Questions

| # | Question | Status |
|---|---|---|
| 1 | Is the business growing, and is there a seasonal pattern? | Done |
| 2 | Which categories and brands look strong on revenue but weak on margin? | Done |
| 3 | Where are returns and cancellations hurting most? | Done |
| 4 | Which traffic sources bring the most valuable customers? | Planned |
| 5 | Do customers come back, and does it differ by when they joined? | Planned |

## Question 1: findings

**Growth.** Revenue grew steadily until January 2026, then sped up from February 2026. Monthly item growth went from roughly 4% to roughly 9%.

**Is the growth real?** I wondered whether counting Shipped items as revenue could be creating fake growth. It isn't. The share of each status stayed about the same across the whole period (roughly 25% Complete, 31% Shipped, 20% Processing, 10% Returned, 15% Cancelled), so more orders really came in.

**Margin.** Margin stayed around 52% throughout, so the growth came from selling more, not from earning more per sale.

**Seasonality.** I used two different checks:
- October is the clearest spike, about 12% above the months around it, and it showed up consistently over six years.
- February is the weakest period.
- **I thought I saw a September spike on the chart, but it doesn't hold up.** Checked year by year from 2020 to 2025, September came in below the months around it every time.

I'm treating the seasonal pattern as consistent in this data, not as proven. It is six years of synthetic data.

## Question 2: findings

**Overall.** Margin across all categories is 51.9%, and individual categories range from about 38% to 62%.

**Strong on both.** Outerwear & Coats is the biggest category (12.1% of revenue) and has a healthy 55.5% margin. Suits & Sport Coats is 4th on both revenue and margin.

**Big on revenue, weak on margin.** Jeans is the main one. It's the second-biggest category (11.8% of revenue) but ranks 21st of 26 on margin at 46.5%, which is 5.4 points below average. If Jeans earned the average margin, it would add about $35k, roughly 1.2% of total margin. Tops & Tees (44.0%), Intimates (46.8%) and Fashion Hoodies & Sweatshirts (48.0%) are smaller versions of the same pattern.

**Is it one bad brand?** No. I looked at the top 10 brands in Jeans and in Tops & Tees. Every Jeans brand sits between 45.6% and 47.5%, and every Tops & Tees brand between 43.1% and 45.0%, even though Jeans prices range from about $45 to $245 per item. The low margin is category-wide, and it looks like margin is set at category level in this data.

**What I'd look at.** Because it isn't one brand, dropping a brand wouldn't help. The question is whether Jeans pricing or sourcing costs can improve. Each extra point of Jeans margin is worth about $6.4k in this data, so the opportunity is real but modest.

## Question 3: findings

**Overall.** About 15% of fulfilled items were returned, and 15.0% of all ordered items were cancelled. This represents approximately 18,039 returned items out of 117,800 fulfilled items. Returns accounted for roughly $967k in sales value.

**Category-level analysis.** Returns and cancellations are spread fairly evenly across the 26 categories. Return rates were between 14.0% and 16.3% for 24 categories, close to the overall rate of 15%.

**Do weak-margin categories also have higher returns?** No. Jeans (15.2%), Tops & Tees (14.7%), Intimates (15.7%) and Fashion Hoodies & Sweatshirts (15.2%) all have return rates close to the average. This means returns don't appear to make the margin problem identified in Question 2 worse.

**Brand-level analysis.** I also compared brands with at least 500 fulfilled items to avoid drawing conclusions from very small samples. Dickies had the highest return rate at 18.3%, followed by Diesel at 17.5%. However, neither provides enough evidence to establish a meaningful brand-specific problem. The remaining brands were also relatively close to the overall rate.

**What I'd look at.** Neither category nor brand appears to explain the return and cancellation rates. Rather than targeting individual products or brands, I'd investigate broader operational factors behind returns and cancellations.

**Data interpretation.** The rates are unusually consistent across categories and brands. Given that this is synthetic data, the uniformity may reflect how returns and cancellations were generated rather than actual retail behaviour. These findings should be treated as an analytical exercise, not evidence that a real retailer would have the same patterns.

## A data issue I found

October 2026 had 79% more items than September, far more than any other month-to-month change. Looking at it day by day, volume climbed gradually until 22 October, then shot up from 23 October and peaked at 1,764 items on 28 October (about five times a normal day) before dropping back. Those nine days hold about half of October's items.

I couldn't explain it from the data. It doesn't look like normal customer behaviour, so I treated it as a likely data issue and excluded it, but I can't say for sure what caused it. All 180,746 rows stay in the view, and a flag called `in_window` makes the cutoff visible.

## Limitations

- The data is synthetic, so the conclusions describe my method, not a real business.
- I used `products.cost` for margin. The inventory table also has a cost column, and I haven't checked whether the two match.
- Revenue counts Shipped items, which could still be returned or cancelled later.
- Seasonality rests on six full years, which is a small sample.

## BigQuery cost notes

[To be added after I finish the optimisation step: bytes processed on the raw tables compared with a partitioned and clustered summary table, with screenshots.]

## Repo contents

- `sql/`: all queries, in the order I ran them, with comments on what I found
- `screenshots/`: query results showing bytes processed

## How to run it yourself

1. Create a free BigQuery sandbox project (a Google account is enough, no credit card).
2. Create a dataset called `thelook_analysis` in the **US** location, which has to match where the public data lives.
3. Replace `YOUR_PROJECT_ID` in the SQL files with your project ID.
4. Run `sql/06_view_order_items_enriched.sql` first, then the other files.

Tools: BigQuery (sandbox), SQL.
