# RFM Customer Segmentation Analysis 

## Project Overview
- This project analyzes retail transaction data using SQL to uncover customer purchasing patterns and segment customers with RFM (Recency, Frequency, Monetary) analysis.
- The goal is to help the business better target marketing campaigns and understand customer behavior.

## Technologies Used
Excel: Retail Analysis on Large Dataset (in csv format from Kaggle)
SQL Server: For data extraction and transformation.
Power BI: For data visualization and dashboard creation.

## Business Question
### “Which customers generate the highest value for the company and how do they differ from others?”

## Hypotheses
H1: Customers with higher income purchase more frequently and spend more.
H2: Certain age groups have higher average purchase frequency and purchase value.
H3: Customers from specific cities/countries generate higher revenue.

## Dataset
Source: Retail Analysis on Large Dataset – Kaggle
Rows: 302,010
Columns: 30

### Main areas covered:
- Customers: ID, Age, Gender, Income, Address, Country
- Transactions: Transaction ID, Date, Amount, Payment/Shipping Method
- Products: Category (electronics, clothing, groceries, books, decorations), Brand, Products
- Geography: City, State, Country
- Time: Date and Time of purchase

##  SQL Techniques Used
- Aggregations: SUM(), COUNT(), AVG(), MAX(), MIN()
- Conditional logic: CASE WHEN … THEN … END
- CTEs (Common Table Expressions)
- Window Functions: ROW_NUMBER(), NTILE(), DENSE_RANK(), OVER (PARTITION BY …)
- JOINs
- Temporary Tables
- TRY_CONVERT / TRY_PARSE for data cleaning

## Techniques & Visuals Used in Power BI Dashboard
- KPI cards – displaying main metrics (Total Customers, average RFM scores – Recency, Frequency, Monetary, Total Revenue).
   Slicers / interactive filters – enabling filtering of customers by segment, age, gender, and income.
- Bar/column chart – showing top 10 products in the “Champions” segment compared to other segments.
- Treemap / stacked bar – visualizing the distribution of customers by segments or demographics.
- Map visualization (bubble map) – displaying Total Revenue by cities and countries (USA, UK, Australia, Germany), with bubble size representing sales volume.
- Interactive tooltips – KPI values and charts dynamically change when a segment is selected.
- Cross-filtering – all visuals are interconnected, allowing multiple perspectives on the data.

## Project Phase 1 – Data Cleaning
Objective: Prepare data for RFM analysis and segmentation.

- Removed duplicates (ROW_NUMBER() + CTE)
- Replaced blanks with NULL
- Standardized and validated data (age, revenue, ratings, date formats, emails)
- Verified logical relations (e.g., Total_Amount = Amount × Total_Purchases)
- Used TRIM to remove whitespace
- Ensured unique Transaction_ID values
- Created a unified datetime column

## Project Phase 2 – Data Analysis
Marketing Model Applied: RFM (Recency, Frequency, Monetary)

- Recency (R): How recently a customer purchased
- Frequency (F): How often a customer purchases
- Monetary (M): How much a customer spends

Customer Segmentation (7 Categories)
- Champions – best customers
- Loyal Customers – frequent buyers
- Potential Loyalists – likely to become loyal
- Big Spenders – high-value customers
- At Risk – customers showing churn risk
- Need Attention – average customers
- Lost – inactive customers

## Project Phase 3 - Data Visualization in Power BI
- The final dashboard answers the business question and hypotheses. 
- It also allows marketers to quickly identify segments (and their characteristics) with the highest (or lowest) value and target campaigns accordingly.

## Results
Total Revenue: $338.40M
  
Revenue by RFM Segmenatiton:
- Big Spenders $154M (45,69% of Total Revenue)
- Champions $102M (30,21%)
- Loyal Customers: $32M (9,68%)
- Need Attention: $19M (5,73%)
- Others: $13M (3,9%)
- At Risk: $9.6M (2,8%)
-  Lost: $6.5M (1,93%)

Total Number of Customers: 294 423 (100%)
  
Number of customers by RFM Segmentation:
- Loyal Customers: 70 836 (24% of all customers)
- Big Spenders: 70 836 (24%)
- Champions: 46 934 (15,9%)
- Need Attention: 35 390 (12%)
- Others: 11,9 %
- Lost: 23 482 (8%)
- At Risk (3,%)

Champions (Highest Value Customers)
- Contribute 30% of total annual revenue ($102.25M out of $338.40M) despite making up only 16% of customers
- Gender: 62% male, 38% female
- Income: 43% medium income, 32% high, 25% low
- Age: 59% aged 18–35, 28% aged 36–55, 13% aged 56+ 
- Most frequent purchases: electronics and groceries
- Prefer same-day delivery
- Favorite brands: Pepsi, Coca-Cola, Samsung, Home Depot, Sony, Bed & Beyond, HarperCollins, Apple, Nike, Nestlé

Hypotheses Validation
- H1 – Rejected: Low-income customers generated the highest total revenue ($118M), compared to middle ($107M) and high-income groups ($113M).
- H2 – Confirmed: Customers aged 36–55 had the highest purchase value per customer (avg. $1,850) compared to 18–35 (avg. $1,430) and 56+ (avg. $1,220).
- H3 – Confirmed: Revenue by country: USA ($105M, 31%), UK ($71M, 21%), Germany ($58M, 17%).
- In the UK, Portsmouth alone contributed 32% of national revenue ($22.7M)

## Marketing Recommendations
- Focus campaigns on Big Spenders with loyalty incentives – potential to convert them into Champions, increasing revenue further.
- Focus campaigns on Champions and Loyal Customers → personalized offers, loyalty programs.
- Investigate why Portsmouth (UK) has significantly higher revenue → replicate best practices elsewhere.
- Target the 36–55 age group with promotions (they make more frequent and higher-value purchases).
- Improve retention of At Risk and Need Attention segments through discounts and reactivation offers (goal: customer retention).

## Further Research Questions
- What is the predicted lifetime value (CLV) of customers across different RFM segments and how can this guide long-term marketing investment?
- Why do low-income customers drive the highest revenue?
- What factors explain Portsmouth’s dominance in the UK?
- How do seasonality and purchase time influence revenue?

