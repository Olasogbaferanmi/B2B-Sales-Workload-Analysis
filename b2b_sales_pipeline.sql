
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



INNER JOIN region r     ON sr.region_id = r.id;
