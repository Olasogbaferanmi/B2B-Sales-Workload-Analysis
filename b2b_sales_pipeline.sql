ALTER TABLE web_events
ADD clean_occurred_at DATETIME
----Remove unwanted characters from columns---
UPDATE sales_reps
SET ["id"]=REPLACE(["id"], '"',''),
	["name"]=REPLACE(["name"], '"',''),
	["region_id"]=REPLACE(["region_id"], '"','')

ALTER TABLE orders
ADD OrderYear SMALLINT  NULL,
	OrderMonth TINYINT NULL,
	OrderDay	TINYINT NULL

UPDATE orders
SET "OrderYear" =Year(occured_at),
	"OrderMonth"=Month(occured_at),
	"OrderDay"=Day(occured_at)

	SELECT *
	FROM web_events

----Revenue Analysis Overview---
----To determine Important and Genral revenue metrics---
CREATE VIEW vw_revenueoverview AS
SELECT 
	  COUNT(DISTINCT account_id) AS total_customers,
	  COUNT(DISTINCT id) AS total_orders,
	  SUM(total_qty) AS total_qty_sold,
	  ROUND(SUM(total_amt_usd), 2) AS total_revenue,
	  ROUND(AVG(total_amt_usd), 2) AS avg_revenue,
	  MIN(OrderYear) AS first_order_Year,
	  MAX(OrderYear) AS last_order_Year
FROM orders
WHERE total_qty> 0

---Regional Performance Analysis---
---To determine best performing regions based on different metrics---
CREATE VIEW vw_regional_performance AS
SELECT 
	region.id AS region_id,
	region.name AS region_name,
	COUNT(DISTINCT accounts.id) AS total_customers,
	COUNT(DISTINCT sales_reps.id) AS total_sales_rep,
	COUNT(orders.id) AS total_orders,
	ROUND(SUM(orders.total_amt_usd), 2) AS total_revenue,
	ROUND(AVG(orders.total_amt_usd), 2) AS avg_revenue,
	ROUND(SUM(orders.total_amt_usd), 2) / NULLIF(COUNT(DISTINCT accounts.id), 0) AS revenue_per_customers,
	ROUND(SUM(orders.total_amt_usd), 2) / NULLIF(COUNT(DISTINCT sales_reps.id), 0) AS revenue_per_sales_rep,
	SUM(orders.standard_qty) AS total_standard_qty,
	SUM(orders.gloss_qty) AS total_gloss_qty,
	SUM(orders.poster_qty) AS total_poster_qty,
	ROUND(SUM(orders.standard_amt_usd), 2) AS standard_revenue,
	ROUND(SUM(orders.gloss_amt_usd), 2) AS gloss_revenue,
	ROUND(SUM(orders.poster_amt_usd), 2) AS poster_revenue
FROM region
LEFT JOIN sales_reps ON region.id=sales_reps.region_id
LEFT JOIN accounts ON sales_reps.id=accounts.Sales_rep_id
LEFT JOIN orders ON accounts.id=orders.account_id AND orders.total_qty > 0
GROUP BY region.id, region.name

SELECT s.region_id, s.name, r.id, r.name,COUNT( a.sales_rep_id) AS Frequency
FROM sales_reps s
INNER JOIN region r ON s.region_id=r.id
LEFT JOIN accounts a ON a.sales_rep_id=s.id
GROUP BY s.region_id, s.name, r.id, r.name
ORDER BY Frequency ASC



----Sales Rep Performance Analysis----
----To determine Sales Rep activities and importance to the business---
CREATE VIEW vw_Sales_performance_analysis AS
SELECT
	s.id AS sales_rep_id,
	s.name AS sales_rep_name,
	r.id AS region_id,
	r.name AS region_name,
	COUNT(DISTINCT a.id) AS accounts_mangaed,
	COUNT(o.id) AS total_orders,
	ROUND(SUM(o.total_amt_usd), 2) AS total_revenue,
	ROUND(AVG(o.total_amt_usd), 2) AS avg_order_revenue,
	ROUND(SUM(o.total_amt_usd) / NULLIF(COUNT(DISTINCT a.id), 0), 2) AS revenue_per_account,
    ROUND(SUM(o.total_amt_usd) / NULLIF(COUNT(o.id), 0), 2) AS avg_deal_size,
    SUM(o.standard_qty) AS total_standard_qty,
    SUM(o.gloss_qty) AS total_gloss_qty,
    SUM(o.poster_qty) AS total_poster_qty,
    ROUND(SUM(o.standard_amt_usd), 2) AS standard_revenue,
    ROUND(SUM(o.gloss_amt_usd), 2) AS gloss_revenue,
    ROUND(SUM(o.poster_amt_usd), 2) AS poster_revenue
	FROM sales_reps s
	INNER JOIN region r ON s.region_id=r.id
	LEFT JOIN accounts a ON s.id=a.sales_rep_id
	LEFT JOIN orders o ON a.id=o.account_id AND o.total_qty > 0
	GROUP BY s.id, s.name, r.id, r.name

	----Customers/Accounts Analysis----
    ----To determine best performing customers and their cycle of activities---
	
CREATE VIEW vw_account_performance AS
SELECT 
    a.id AS account_id,
    a.name AS account_name,
    a.website,
    a.lat AS latitude,
    a.long AS longitude,
    a.primary_poc,
    a.sales_rep_id,
    sr.name AS sales_rep_name,
    r.id AS region_id,
    r.name AS region_name,
    COUNT(o.id) AS total_orders,
    ROUND(COALESCE(SUM(o.total_amt_usd), 0), 2) AS total_revenue,
    ROUND(COALESCE(AVG(o.total_amt_usd), 0), 2) AS avg_order_value,
    SUM(o.total_qty) AS total_units,
    ROUND(COALESCE(SUM(o.standard_amt_usd), 0), 2) AS standard_revenue,
    ROUND(COALESCE(SUM(o.gloss_amt_usd), 0), 2) AS gloss_revenue,
    ROUND(COALESCE(SUM(o.poster_amt_usd), 0), 2) AS poster_revenue,
    MIN(OrderMonth) AS firstMonth,
    MAX(OrderMonth) AS lastMonth,
    CASE 
        WHEN COUNT(o.id) = 0 THEN 'No Orders'
        WHEN COUNT(o.id) = 1 THEN 'One-Time Customer'
        WHEN COUNT(o.id) <= 5 THEN 'Occasional Customer'
        WHEN COUNT(o.id) <= 15 THEN 'Regular Customer'
        ELSE 'Loyal Customer'
    END AS customer_segment
FROM accounts a
INNER JOIN sales_reps sr ON a.sales_rep_id = sr.id
INNER JOIN region r ON sr.region_id = r.id
LEFT JOIN orders o ON a.id = o.account_id AND o.total_qty > 0
GROUP BY a.id, a.name, a.website, a.lat, a.long, a.primary_poc, 
         a.sales_rep_id, sr.name, r.id, r.name;

---Product Performance Analysis---
---To determone which how products perform based on accounts orders---

CREATE VIEW vw_product_performance_regional AS
SELECT 
    r.id AS region_id,
    r.name AS region_name,
    SUM(o.standard_qty) AS standard_qty,
    SUM(o.gloss_qty) AS gloss_qty,
    SUM(o.poster_qty) AS poster_qty,
    SUM(o.total_qty) AS total_qty,
    ROUND(SUM(o.standard_amt_usd), 2) AS standard_revenue,
    ROUND(SUM(o.gloss_amt_usd), 2) AS gloss_revenue,
    ROUND(SUM(o.poster_amt_usd), 2) AS poster_revenue,
    ROUND(SUM(o.total_amt_usd), 2) AS total_revenue,
    ROUND((SUM(o.standard_amt_usd) / NULLIF(SUM(o.total_amt_usd), 0)) * 100, 2) AS standard_pct,
    ROUND((SUM(o.gloss_amt_usd) / NULLIF(SUM(o.total_amt_usd), 0)) * 100, 2) AS gloss_pct,
    ROUND((SUM(o.poster_amt_usd) / NULLIF(SUM(o.total_amt_usd), 0)) * 100, 2) AS poster_pct,
    ROUND(SUM(o.standard_amt_usd) / NULLIF(SUM(o.standard_qty), 0), 2)--- AS standard_avg_price,
    ROUND(SUM(o.gloss_amt_usd) / NULLIF(SUM(o.gloss_qty), 0), 2) AS gloss_avg_price,
    ROUND(SUM(o.poster_amt_usd) / NULLIF(SUM(o.poster_qty), 0), 2) AS poster_avg_price
FROM orders o
INNER JOIN accounts a ON o.account_id = a.id
INNER JOIN sales_reps sr ON a.sales_rep_id = sr.id
INNER JOIN region r ON sr.region_id = r.id
WHERE o.total_qty > 0
GROUP BY r.id, r.name;


----Distribution Analysis for SalesRep---
---To determine each Sales rep capacity and ability to cater for accounts---
CREATE VIEW vw_workload_distribution AS
SELECT 
    sr.id AS sales_rep_id,
    sr.name AS sales_rep_name,
    r.name AS region_name,
    COUNT(DISTINCT a.id) AS accounts_managed,
    COUNT(o.id) AS total_orders,
    ROUND(COALESCE(SUM(o.total_amt_usd), 0), 2) AS total_revenue,
    ROUND(
        COUNT(o.id) * 1.0 / NULLIF(COUNT(DISTINCT a.id), 0), 
        2
    ) AS orders_per_account,
    CASE 
        WHEN COUNT(DISTINCT a.id) = 0 THEN 'No Accounts'
        WHEN COUNT(DISTINCT a.id) < 5 THEN 'Underutilized'
        WHEN COUNT(DISTINCT a.id) <= 8 THEN 'Optimal'
        WHEN COUNT(DISTINCT a.id) <= 12 THEN 'High Load'
        ELSE 'Overloaded'
    END AS workload_status,
    CASE 
        WHEN COUNT(DISTINCT a.id) < 5 THEN 'Can Take More Accounts'
        WHEN COUNT(DISTINCT a.id) > 12 THEN 'Needs Support'
        ELSE 'Balanced'
    END AS recommendation
FROM sales_reps sr
INNER JOIN region r ON sr.region_id = r.id
LEFT JOIN accounts a ON sr.id = a.sales_rep_id
LEFT JOIN orders o ON a.id = o.account_id AND o.total_qty > 0
GROUP BY sr.id, sr.name, r.name;


---Monthly Revenue Trends
CREATE VIEW vw_monthly_revenue AS
SELECT
    DATETRUNC(month, o.occurred_at)     AS month_start,
    YEAR(o.occurred_at)        AS year,
    MONTH(o.occurred_at)        AS month_num,
    DATENAME(month, o.occurred_at)        AS month_name,
    DATEPART(quarter, o.occurred_at)         AS quarter,
    r.id        AS region_id,
    r.name                                   AS region_name,
    COUNT(o.id)              AS total_orders,
    ROUND(SUM(o.total_amt_usd), 2)           AS total_revenue,
    ROUND(AVG(o.total_amt_usd), 2)     AS avg_order_value,
    SUM(o.total_qty)                             AS total_units,
    ROUND(SUM(o.standard_amt_usd), 2)        AS standard_revenue,
    ROUND(SUM(o.gloss_amt_usd), 2)           AS gloss_revenue,
    ROUND(SUM(o.poster_amt_usd), 2)          AS poster_revenue
FROM orders o
INNER JOIN accounts a ON o.account_id = a.id
INNER JOIN sales_reps sr ON a.sales_rep_id = sr.id
INNER JOIN region r ON sr.region_id = r.id


---Accounts Conversion Overview
CREATE vw_account_conversion_overview AS
WITH account_timeline AS (
    
WHERE o.total_qty > 0
GROUP BY 
    DATETRUNC(month, o.occurred_at),
    YEAR(o.occurred_at),
    MONTH(o.occurred_at),
    DATENAME(month, o.occurred_at),
    DATEPART(quarter, o.occurred_at),
    r.id, 
    r.name;


    
CREATE VIEW vw_account_conversion_overview AS
WITH account_timeline AS (
    SELECT 
        a.id AS account_id,
        a.name AS account_name,
        sr.name AS sales_rep_name,
        r.name AS region_name,
        MIN(w.occurred_at) AS first_web_event_date,
        MAX(w.occurred_at) AS last_web_event_date,
        MIN(o.occurred_at) AS first_order_date,
        MAX(o.occurred_at) AS last_order_date,
        COUNT(DISTINCT w.id) AS total_web_events,
        COUNT(DISTINCT o.id) AS total_orders
    FROM accounts a
    INNER JOIN sales_reps sr ON a.sales_rep_id = sr.id
    INNER JOIN region r ON sr.region_id = r.id
    LEFT JOIN web_events w ON a.id = w.account_id
    LEFT JOIN orders o ON a.id = o.account_id AND o.total_qty > 0
    GROUP BY a.id, a.name, sr.name, r.name
)
SELECT 
    account_id,
    account_name,
    sales_rep_name,
    region_name,
    first_web_event_date,
    last_web_event_date,
    first_order_date,
    last_order_date,
    total_web_events,
    total_orders,
    CASE 
        WHEN first_order_date IS NOT NULL THEN 'Converted'
        WHEN total_web_events > 0 THEN 'Engaged - Not Converted'
        ELSE 'No Engagement'
    END AS conversion_status,
    CASE 
        WHEN first_order_date IS NOT NULL 
        THEN DAY (first_order_date - first_web_event_date)
        ELSE NULL
    END AS days_to_first_conversion,
    CASE 
        WHEN first_order_date IS NOT NULL AND total_web_events > 0
        THEN ROUND(total_web_events * 1.0 / total_orders, 2)
        ELSE NULL
    END AS web_events_per_order,
    CASE 
        WHEN first_order_date IS NOT NULL THEN 1
        ELSE 0
    END AS is_converted
FROM account_timeline;


---Channel Conversion Rates
---How each marketing channel converts

CREATE VIEW vw_channel_conversion_rates AS
WITH channel_metrics AS (
    SELECT 
        w.channel,
        r.name AS region_name,
        w.account_id,
        COUNT(w.id) AS events_count,
        MIN(w.occurred_at) AS first_event_date
    FROM web_events w
    INNER JOIN accounts a ON w.account_id = a.id
    INNER JOIN sales_reps sr ON a.sales_rep_id = sr.id
    INNER JOIN region r ON sr.region_id = r.id
    GROUP BY w.channel, r.name, w.account_id
),
channel_orders AS (
    SELECT 
        cm.channel,
        cm.region_name,
        cm.account_id,
        cm.events_count,
        cm.first_event_date,
        COUNT(DISTINCT o.id) AS orders_count,
        ROUND(COALESCE(SUM(o.total_amt_usd), 0), 2) AS total_revenue,
        MIN(o.occurred_at) AS first_order_date
    FROM channel_metrics cm
    LEFT JOIN orders o ON cm.account_id = o.account_id 
        AND o.occurred_at >= cm.first_event_date
        AND o.total_qty > 0
    GROUP BY cm.channel, cm.region_name, cm.account_id, cm.events_count, cm.first_event_date
)
SELECT 
    channel,
    region_name,
    COUNT(DISTINCT account_id) AS total_accounts_engaged,
    SUM(events_count) AS total_events,
    COUNT(DISTINCT CASE WHEN orders_count > 0 THEN account_id END) AS accounts_converted,
    SUM(orders_count) AS total_orders_generated,
    SUM(total_revenue) AS total_revenue_generated,
    ROUND(
        (COUNT(DISTINCT CASE WHEN orders_count > 0 THEN account_id END) * 100.0) / 
        NULLIF(COUNT(DISTINCT account_id), 0), 
        2
    ) AS conversion_rate_pct,
    ROUND(
        SUM(total_revenue) / NULLIF(COUNT(DISTINCT account_id), 0), 
        2
    ) AS revenue_per_engaged_account,
    ROUND(
        SUM(total_revenue) / NULLIF(SUM(events_count), 0), 
        2
    ) AS revenue_per_event,
    ROUND(
        AVG(CASE 
            WHEN first_order_date IS NOT NULL AND first_event_date IS NOT NULL
            THEN DAY  (first_order_date - first_event_date)
            ELSE NULL
        END),
        1
    ) AS avg_days_to_conversion
FROM channel_orders
GROUP BY channel, region_name;


---Sales Cycle Analysis

CREATE VIEW vw_sales_cycle_analysis AS
WITH account_first_touch AS (
    SELECT 
        account_id,
        MIN(occurred_at) AS first_touch_date
    FROM web_events
    GROUP BY account_id
),
account_orders AS (
    SELECT 
        o.id AS order_id,
        o.account_id,
        o.occurred_at AS order_date,
        o.total_amt_usd AS order_value,
        ROW_NUMBER() OVER (PARTITION BY o.account_id ORDER BY o.occurred_at ASC) AS order_number
    FROM orders o
    WHERE o.total_qty > 0
)
SELECT 
    ao.order_id,
    ao.account_id,
    a.name AS account_name,
    sr.name AS sales_rep_name,
    r.name AS region_name,
    aft.first_touch_date,
    ao.order_date,
    ROUND(ao.order_value, 2) AS order_value,
    ao.order_number,
   DAY  (ao.order_date - aft.first_touch_date) AS sales_cycle_days,
    CASE 
        WHEN DAY (ao.order_date - aft.first_touch_date)<= 7 THEN '0-7 days'
        WHEN DAY  (ao.order_date - aft.first_touch_date) <= 30 THEN '8-30 days'
        WHEN DAY(ao.order_date - aft.first_touch_date) <= 60 THEN '31-60 days'
        WHEN DAY  (ao.order_date - aft.first_touch_date) <= 90 THEN '61-90 days'
        ELSE '90+ days'
    END AS sales_cycle_bucket,
    CASE 
        WHEN ao.order_number = 1 THEN 'First Order'
        ELSE 'Repeat Order'
    END AS order_type
FROM account_orders ao
INNER JOIN account_first_touch aft ON ao.account_id = aft.account_id
INNER JOIN accounts a ON ao.account_id = a.id
INNER JOIN sales_reps sr ON a.sales_rep_id = sr.id
INNER JOIN region r ON sr.region_id = r.id;


---Customer?Accounts Purchase Patterns
---purpose is to help understand behaviour and buying frequency, and consistency

CREATE VIEW vw_customer_purchase_patterns AS
WITH order_intervals AS (
    SELECT
        account_id,
        occurred_at,
        total_amt_usd,
        LAG(occurred_at) OVER (PARTITION BY account_id ORDER BY occurred_at) AS previous_order_date,
        DATEDIFF(DAY, LAG(occurred_at) OVER (PARTITION BY account_id ORDER BY occurred_at), occurred_at) AS days_since_last_order
    FROM orders
    WHERE total_qty > 0
),
customer_metrics AS (
    SELECT
        account_id,
        COUNT(*) AS total_orders,
        MIN(occurred_at) AS first_order_date,
        MAX(occurred_at) AS last_order_date,
        ROUND(AVG(total_amt_usd), 2) AS avg_order_value,
        ROUND(STDEV(total_amt_usd), 2) AS order_value_stddev,
        ROUND(AVG(days_since_last_order), 1) AS avg_days_between_orders,
        ROUND(STDEV(days_since_last_order), 1) AS days_between_orders_stddev,
        MIN(days_since_last_order) AS min_days_between_orders,
        MAX(days_since_last_order) AS max_days_between_orders
    FROM order_intervals
    GROUP BY account_id
)
SELECT
    cm.account_id,
    a.name AS account_name,
    sr.name AS sales_rep_name,
    r.name AS region_name,
    cm.total_orders,
    cm.first_order_date,
    cm.last_order_date,
    DATEDIFF(DAY, cm.last_order_date, CAST(GETDATE() AS DATE)) AS days_since_last_order,
    cm.avg_order_value,
    cm.order_value_stddev,
    cm.avg_days_between_orders,
    cm.days_between_orders_stddev,
    cm.min_days_between_orders,
    cm.max_days_between_orders,
    -- Purchase pattern classification
    CASE
        WHEN cm.days_between_orders_stddev <= cm.avg_days_between_orders * 0.3 THEN 'Highly Consistent'
        WHEN cm.days_between_orders_stddev <= cm.avg_days_between_orders * 0.5 THEN 'Consistent'
        WHEN cm.days_between_orders_stddev <= cm.avg_days_between_orders * 0.8 THEN 'Somewhat Irregular'
        ELSE 'Very Irregular'
    END AS purchase_consistency,
    -- Order frequency category
    CASE
        WHEN cm.avg_days_between_orders <= 15 THEN 'Very Frequent (Bi-weekly)'
        WHEN cm.avg_days_between_orders <= 30 THEN 'Frequent (Monthly)'
        WHEN cm.avg_days_between_orders <= 60 THEN 'Regular (Bi-monthly)'
        WHEN cm.avg_days_between_orders <= 90 THEN 'Occasional (Quarterly)'
        ELSE 'Infrequent (Irregular)'
    END AS order_frequency_type,
    -- Expected next order date (SQL Server version)
    DATEADD(DAY, CAST(cm.avg_days_between_orders AS INT), cm.last_order_date) AS expected_next_order_date,
    -- Is customer overdue?
    CASE
        WHEN DATEDIFF(DAY, cm.last_order_date, CAST(GETDATE() AS DATE)) > cm.avg_days_between_orders * 1.5 THEN 'Overdue'
        WHEN DATEDIFF(DAY, cm.last_order_date, CAST(GETDATE() AS DATE)) > cm.avg_days_between_orders THEN 'Due Soon'
        ELSE 'On Track'
    END AS reorder_status
FROM customer_metrics cm
INNER JOIN accounts a ON cm.account_id = a.id
INNER JOIN sales_reps sr ON a.sales_rep_id = sr.id
INNER JOIN region r ON sr.region_id = r.id;


---Customer Spending Trends
--Customer Lifetime Value and lifecycle
CREATE VIEW vw_customer_lifecycle_stage AS
WITH customer_timeline AS (
    SELECT 
        account_id,
        MIN(occurred_at) AS first_order_date,
        MAX(occurred_at) AS last_order_date,
        COUNT(*) AS total_orders,
        SUM(total_amt_usd) AS lifetime_value,
        DATEDIFF(DAY, MIN(occurred_at), MAX(occurred_at)) AS customer_tenure_days
    FROM orders
    WHERE total_qty > 0
    GROUP BY account_id
)
SELECT 
    ct.account_id,
    a.name AS account_name,
    sr.name AS sales_rep_name,
    r.name AS region_name,
    ct.first_order_date,
    ct.last_order_date,
    DATEDIFF(DAY, ct.last_order_date, CAST(GETDATE() AS DATE)) AS days_since_last_order,
    ct.total_orders,
    ROUND(ct.lifetime_value, 2) AS lifetime_value,
    ct.customer_tenure_days,
    ROUND(ct.customer_tenure_days / 30.0, 1) AS customer_tenure_months,
    
    -- Lifecycle stage (using CASE as before)
    CASE 
        WHEN ct.total_orders = 1 
             AND DATEDIFF(DAY, ct.first_order_date, CAST(GETDATE() AS DATE)) <= 90 
            THEN 'New Customer'
        WHEN ct.total_orders <= 3 
             AND ct.customer_tenure_days <= 180 
            THEN 'Early Stage'
        WHEN DATEDIFF(DAY, ct.last_order_date, CAST(GETDATE() AS DATE)) > 180 
            THEN 'Churned'
        WHEN DATEDIFF(DAY, ct.last_order_date, CAST(GETDATE() AS DATE)) > 90 
            THEN 'At Risk'
        WHEN ct.total_orders >= 10 
             AND ct.customer_tenure_days >= 365 
            THEN 'Loyal'
        WHEN ct.total_orders >= 5 
            THEN 'Active'
        ELSE 'Growing'
    END AS lifecycle_stage,
    
    -- Activity status
    CASE 
        WHEN DATEDIFF(DAY, ct.last_order_date, CAST(GETDATE() AS DATE)) <= 30 
            THEN 'Highly Active'
        WHEN DATEDIFF(DAY, ct.last_order_date, CAST(GETDATE() AS DATE)) <= 60 
            THEN 'Active'
        WHEN DATEDIFF(DAY, ct.last_order_date, CAST(GETDATE() AS DATE)) <= 90 
            THEN 'Moderately Active'
        WHEN DATEDIFF(DAY, ct.last_order_date, CAST(GETDATE() AS DATE)) <= 180 
            THEN 'Inactive'
        ELSE 'Dormant'
    END AS activity_status,
    
    -- Customer value tier
    CASE 
        WHEN ct.lifetime_value >= 50000 THEN 'Platinum'
        WHEN ct.lifetime_value >= 25000 THEN 'Gold'
        WHEN ct.lifetime_value >= 10000 THEN 'Silver'
        ELSE 'Bronze'
    END AS value_tier

FROM customer_timeline ct
INNER JOIN accounts a ON ct.account_id = a.id
INNER JOIN sales_reps sr ON a.sales_rep_id = sr.id
INNER JOIN region r ON sr.region_id = r.id;

---Chrun Risk Prediction
---purpose is to calculate  and identify customers at high risk of churning
CREATE VIEW vw_churn_risk_prediction AS
WITH customer_metrics AS (
    SELECT 
        o.account_id,
        COUNT(*) AS total_orders,
        MAX(o.occurred_at) AS last_order_date,
        AVG(CAST(DATEDIFF(DAY, LAG(o.occurred_at) OVER (PARTITION BY o.account_id ORDER BY o.occurred_at), o.occurred_at) AS FLOAT)) AS avg_days_between_orders,
        AVG(o.total_amt_usd) AS avg_order_value,
        SUM(o.total_amt_usd) AS lifetime_value,
        STDEV(o.total_amt_usd) AS order_value_variance
    FROM orders o
    WHERE o.total > 0
    GROUP BY o.account_id
),
engagement_metrics AS (
    SELECT 
        account_id,
        COUNT(*) AS total_web_events,
        MAX(occurred_at) AS last_web_event,
        COUNT(DISTINCT channel) AS channels_used
    FROM web_events
    GROUP BY account_id
),
recent_order_trend AS (
    SELECT 
        account_id,
        AVG(CASE WHEN row_num <= 3 THEN total_amt_usd ELSE NULL END) AS last_3_orders_avg,
        AVG(CASE WHEN row_num BETWEEN 4 AND 6 THEN total_amt_usd ELSE NULL END) AS prev_3_orders_avg
    FROM (
        SELECT 
            account_id,
            total_amt_usd,
            ROW_NUMBER() OVER (PARTITION BY account_id ORDER BY occurred_at DESC) AS row_num
        FROM orders
        WHERE total > 0
    ) ranked_orders
    GROUP BY account_id
)
SELECT 
    cm.account_id,
    a.name AS account_name,
    sr.name AS sales_rep_name,
    r.name AS region_name,
    cm.total_orders,
    cm.last_order_date,
    DATEDIFF(DAY, cm.last_order_date, CAST(GETDATE() AS DATE)) AS days_since_last_order,
    ROUND(cm.avg_days_between_orders, 1) AS avg_days_between_orders,
    ROUND(cm.avg_order_value, 2) AS avg_order_value,
    ROUND(cm.lifetime_value, 2) AS lifetime_value,
    COALESCE(em.total_web_events, 0) AS total_web_events,
    COALESCE(DATEDIFF(DAY, em.last_web_event, CAST(GETDATE() AS DATE)), 999) AS days_since_last_web_event,
    ROUND(rot.last_3_orders_avg, 2) AS last_3_orders_avg,
    ROUND(rot.prev_3_orders_avg, 2) AS prev_3_orders_avg,
    
    -- Churn risk score (0-100)
    LEAST(100, GREATEST(0,
        -- Days overdue factor (40 points max)
        (CASE 
            WHEN DATEDIFF(DAY, cm.last_order_date, CAST(GETDATE() AS DATE)) > cm.avg_days_between_orders * 2 THEN 40
            WHEN DATEDIFF(DAY, cm.last_order_date, CAST(GETDATE() AS DATE)) > cm.avg_days_between_orders * 1.5 THEN 30
            WHEN DATEDIFF(DAY, cm.last_order_date, CAST(GETDATE() AS DATE)) > cm.avg_days_between_orders THEN 20
            ELSE 0 
        END) +
        -- Declining order value (30 points max)
        (CASE 
            WHEN rot.last_3_orders_avg < rot.prev_3_orders_avg * 0.7 THEN 30
            WHEN rot.last_3_orders_avg < rot.prev_3_orders_avg * 0.85 THEN 20
            WHEN rot.last_3_orders_avg < rot.prev_3_orders_avg THEN 10
            ELSE 0 
        END) +
        -- Low engagement (30 points max)
        (CASE 
            WHEN COALESCE(DATEDIFF(DAY, em.last_web_event, CAST(GETDATE() AS DATE)), 999) > 90 THEN 30
            WHEN COALESCE(DATEDIFF(DAY, em.last_web_event, CAST(GETDATE() AS DATE)), 999) > 60 THEN 20
            WHEN COALESCE(DATEDIFF(DAY, em.last_web_event, CAST(GETDATE() AS DATE)), 999) > 30 THEN 10
            ELSE 0 
        END)
    )) AS churn_risk_score,

    -- Churn risk category
    CASE 
        WHEN LEAST(100, GREATEST(0, 
            (CASE WHEN DATEDIFF(DAY, cm.last_order_date, CAST(GETDATE() AS DATE)) > cm.avg_days_between_orders * 2 THEN 40
                  WHEN DATEDIFF(DAY, cm.last_order_date, CAST(GETDATE() AS DATE)) > cm.avg_days_between_orders * 1.5 THEN 30
                  WHEN DATEDIFF(DAY, cm.last_order_date, CAST(GETDATE() AS DATE)) > cm.avg_days_between_orders THEN 20
                  ELSE 0 END) +
            (CASE WHEN rot.last_3_orders_avg < rot.prev_3_orders_avg * 0.7 THEN 30
                  WHEN rot.last_3_orders_avg < rot.prev_3_orders_avg * 0.85 THEN 20
                  WHEN rot.last_3_orders_avg < rot.prev_3_orders_avg THEN 10
                  ELSE 0 END) +
            (CASE WHEN COALESCE(DATEDIFF(DAY, em.last_web_event, CAST(GETDATE() AS DATE)), 999) > 90 THEN 30
                  WHEN COALESCE(DATEDIFF(DAY, em.last_web_event, CAST(GETDATE() AS DATE)), 999) > 60 THEN 20
                  WHEN COALESCE(DATEDIFF(DAY, em.last_web_event, CAST(GETDATE() AS DATE)), 999) > 30 THEN 10
                  ELSE 0 END)
        )) >= 70 THEN 'Critical Risk'
        WHEN LEAST(100, GREATEST(0, /* same expression as above */) ) >= 40 THEN 'High Risk'
        WHEN LEAST(100, GREATEST(0, /* same expression as above */) ) >= 20 THEN 'Medium Risk'
        ELSE 'Low Risk'
    END AS churn_risk_category,

    -- Recommended action (same logic as category)
    CASE 
        WHEN LEAST(100, GREATEST(0, /* same expression as above */) ) >= 70 THEN 'Urgent: Executive escalation required'
        WHEN LEAST(100, GREATEST(0, /* same expression as above */) ) >= 40 THEN 'Sales rep should call immediately with retention offer'
        WHEN LEAST(100, GREATEST(0, /* same expression as above */) ) >= 20 THEN 'Schedule check-in call this week'
        ELSE 'Continue normal engagement'
    END AS recommended_action

FROM customer_metrics cm
INNER JOIN accounts a ON cm.account_id = a.id
INNER JOIN sales_reps sr ON a.sales_rep_id = sr.id
INNER JOIN region r ON sr.region_id = r.id
LEFT JOIN engagement_metrics em ON cm.account_id = em.account_id
LEFT JOIN recent_order_trend rot ON cm.account_id = rot.account_id;

---Customer Engagement Score
---to measure customer engagment value and assign different points based on this
CREATE VIEW vw_customer_engagement_score AS
WITH order_metrics AS (
    SELECT 
        account_id,
        COUNT(*) AS total_orders,
        MAX(occurred_at) AS last_order_date,
        SUM(total_amt_usd) AS lifetime_value,
        AVG(total_amt_usd) AS avg_order_value
    FROM orders
    WHERE total_qty > 0
    GROUP BY account_id
),
web_metrics AS (
    SELECT 
        account_id,
        COUNT(*) AS total_web_events,
        MAX(occurred_at) AS last_web_event,
        COUNT(DISTINCT channel) AS unique_channels_used,
        COUNT(DISTINCT 
            DATEADD(MONTH, DATEDIFF(MONTH, 0, occurred_at), 0)
        ) AS months_with_activity
    FROM web_events
    GROUP BY account_id
),
engagement_scores AS (
    SELECT 
        om.account_id,
        
        -- Recency score (0-25 points) - based on days since last order
        CASE 
            WHEN DATEDIFF(DAY, om.last_order_date, CAST(GETDATE() AS DATE)) <= 30 THEN 25
            WHEN DATEDIFF(DAY, om.last_order_date, CAST(GETDATE() AS DATE)) <= 60 THEN 20
            WHEN DATEDIFF(DAY, om.last_order_date, CAST(GETDATE() AS DATE)) <= 90 THEN 15
            WHEN DATEDIFF(DAY, om.last_order_date, CAST(GETDATE() AS DATE)) <= 180 THEN 10
            ELSE 5 
        END AS recency_score,
        
        -- Frequency score (0-25 points)
        CASE 
            WHEN om.total_orders >= 20 THEN 25
            WHEN om.total_orders >= 15 THEN 20
            WHEN om.total_orders >= 10 THEN 15
            WHEN om.total_orders >= 5  THEN 10
            ELSE 5 
        END AS frequency_score,
        
        -- Monetary score (0-25 points)
        CASE 
            WHEN om.lifetime_value >= 50000 THEN 25
            WHEN om.lifetime_value >= 25000 THEN 20
            WHEN om.lifetime_value >= 10000 THEN 15
            WHEN om.lifetime_value >=  5000 THEN 10
            ELSE 5 
        END AS monetary_score,
        
        -- Engagement score (0-25 points) - web activity components
        LEAST(25, 
            (CASE WHEN wm.total_web_events >= 50 THEN 10
                  WHEN wm.total_web_events >= 20 THEN  7
                  WHEN wm.total_web_events >= 10 THEN  5
                  ELSE 3 END) +
            (CASE WHEN wm.unique_channels_used >= 4 THEN 8
                  WHEN wm.unique_channels_used >= 3 THEN 6
                  WHEN wm.unique_channels_used >= 2 THEN 4
                  ELSE 2 END) +
            (CASE WHEN COALESCE(DATEDIFF(DAY, wm.last_web_event, CAST(GETDATE() AS DATE)), 999) <= 7  THEN 7
                  WHEN COALESCE(DATEDIFF(DAY, wm.last_web_event, CAST(GETDATE() AS DATE)), 999) <= 30 THEN 5
                  WHEN COALESCE(DATEDIFF(DAY, wm.last_web_event, CAST(GETDATE() AS DATE)), 999) <= 60 THEN 3
                  ELSE 1 END)
        ) AS engagement_score,
        
        om.total_orders,
        om.last_order_date,
        om.lifetime_value,
        om.avg_order_value,
        wm.total_web_events,
        wm.last_web_event,
        wm.unique_channels_used
        
    FROM order_metrics om
    LEFT JOIN web_metrics wm ON om.account_id = wm.account_id
)
SELECT 
    es.account_id,
    a.name AS account_name,
    sr.name AS sales_rep_name,
    r.name AS region_name,
    
    es.recency_score,
    es.frequency_score,
    es.monetary_score,
    es.engagement_score,
    
    (es.recency_score + es.frequency_score + es.monetary_score + es.engagement_score) AS total_engagement_score,
    
    ROUND(es.lifetime_value, 2) AS lifetime_value,
    es.total_orders,
    es.total_web_events,
    es.last_order_date,
    es.last_web_event,
    
    -- Customer health category
    CASE 
        WHEN (es.recency_score + es.frequency_score + es.monetary_score + es.engagement_score) >= 80 THEN 'Excellent Health'
        WHEN (es.recency_score + es.frequency_score + es.monetary_score + es.engagement_score) >= 60 THEN 'Good Health'
        WHEN (es.recency_score + es.frequency_score + es.monetary_score + es.engagement_score) >= 40 THEN 'Fair Health'
        ELSE 'Poor Health'
    END AS customer_health,
    
    -- Recommended focus
    CASE 
        WHEN es.recency_score    < 15 THEN 'Focus on Re-engagement'
        WHEN es.frequency_score  < 15 THEN 'Focus on Increasing Order Frequency'
        WHEN es.monetary_score   < 15 THEN 'Focus on Upselling'
        WHEN es.engagement_score < 15 THEN 'Focus on Multi-Channel Engagement'
        ELSE 'Maintain and Grow'
    END AS recommended_focus

FROM engagement_scores es
INNER JOIN accounts a   ON es.account_id = a.id
INNER JOIN sales_reps sr ON a.sales_rep_id = sr.id
INNER JOIN region r     ON sr.region_id = r.id;