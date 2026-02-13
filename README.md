# B2B Sales Operations: Workload & Capacity Analysis 📊💼

## 📌 Project Overview
Most sales dashboards only track top-line revenue, which masks underlying inefficiencies and rep burnout. In this project, I used Microsost SQL server to analyze a B2B dataset of 50 sales representatives generating $10.4M in revenue. 

I built an automated **Workload Distribution Engine** to normalize revenue against account capacity, identifying severely overloaded reps and uncovering hidden excess capacity within the team.

Medium Article Case Study:

## 📂 File Structure
* `/b2b_sales_pipeline.sql./`: The complete SQL script containing data cleaning, RFM modeling, and workload distribution logic.
* `sales_rep_workload_data.csv`: The exported results showing the exact account distribution across the 50-person team.

## 🛠️ Key Techniques Used
* **Advanced Joins & CTEs:** Connected web events, orders, and sales rep tables to track the full customer journey.
* **Window Functions (`LAG`):** Used to identify shrinking order values to build an early-warning churn risk model.
* **Conditional Logic (`CASE WHEN`):** Built an automated categorization engine to classify reps as "Underutilized," "Optimal," "High Load," or "Overloaded."

## 📊 Strategic Findings
* **The Workload Illusion:** Top-line revenue does not equal efficiency. Rep A generated $160k but was critically overloaded with **15 accounts**. Rep B generated $199k while only managing **3 accounts**.
* **Uncovering Capacity:** The SQL algorithm automatically flagged that **13 of the 50 reps were underutilized**.
* **Business Recommendation:** By re-routing leads from overloaded reps (mostly in the West/Southeast) to the 13 underutilized reps (Midwest/Northeast), the business can increase overall closing rates without increasing headcount.

---
*Author: **Olasogba Mayowa***
*Tools: **Microsoft SQL Server, Data Modeling, RevOps Strategy***
