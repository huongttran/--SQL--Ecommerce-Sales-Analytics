--Q1
SELECT 
      FORMAT_DATE('%Y%m' , PARSE_DATE('%Y%m%d', date)) AS month, 
      COUNT(fullVisitorId) AS total,
      SUM(totals.pageviews) AS pageviews,
      SUM(totals.transactions) AS transactions
FROM `bigquery-public-data.google_analytics_sample.ga_sessions_2017*` 
WHERE _TABLE_SUFFIX BETWEEN '0101' AND '0331'
GROUP BY month 
ORDER BY month;



--Q2
SELECT trafficSource.`source`, 
        SUM (totals.visits) AS total_visits,
        SUM (totals.bounces) AS total_no_of_bounces,
        ROUND(SUM (totals.bounces) /SUM (totals.visits) * 100.0,2) AS bounce_rate
FROM `bigquery-public-data.google_analytics_sample.ga_sessions_201707*`
GROUP BY trafficSource.`source`
ORDER BY total_visits DESC



--Q3
WITH month_rev AS (
  SELECT 
      'Month' AS time_type,
      FORMAT_DATE('%Y%m' , PARSE_DATE('%Y%m%d', date)) AS month,
      trafficSource.`source` AS source, 
      ROUND(SUM(SAFE_CAST(product.productRevenue AS INT64)) / 1000000.0,4) AS revenue 
  FROM 
      `bigquery-public-data.google_analytics_sample.ga_sessions_201706`,
      UNNEST (hits) hits,
      UNNEST (hits.product) product
  WHERE product.productRevenue is not null
  GROUP BY month,source
)
,
week_rev AS (
  SELECT
    'Week' AS time_type,
    FORMAT_DATE('%G%V' , PARSE_DATE('%Y%m%d', date)) AS month,
    trafficSource.`source` AS source, 
    ROUND(SUM(SAFE_CAST(product.productRevenue AS INT64)) / 1000000.0,4) AS revenue 
  FROM 
      `bigquery-public-data.google_analytics_sample.ga_sessions_201706`,
      UNNEST (hits) hits,
      UNNEST (hits.product) product
  WHERE product.productRevenue is not null
  GROUP BY month,source
)
SELECT *
FROM month_rev
UNION ALL
SELECT *
FROM week_rev
ORDER BY revenue DESC



--Q4
WITH Purchaser AS (
  SELECT
      FORMAT_DATE('%Y%m' , PARSE_DATE('%Y%m%d', date)) AS month,
      ROUND(SUM(totals.pageviews) / COUNT (DISTINCT fullVisitorId),2) AS avg_pageviews_purchase
  FROM 
      `bigquery-public-data.google_analytics_sample.ga_sessions_2017`,
      UNNEST (hits) hits,
      UNNEST (hits.product) product
  WHERE 
      product.productRevenue IS NOT NULL
      AND totals.transactions >=1
      AND _TABLE_SUFFIX  BETWEEN '0601' AND '0731'
  GROUP BY month
)
,
NonPurchaser AS(
  SELECT 
        FORMAT_DATE('%Y%m' , PARSE_DATE('%Y%m%d', date)) AS month,
        ROUND(SUM(totals.pageviews) / COUNT (DISTINCT fullVisitorId),2) AS avg_pageviews_non_purchase
  FROM 
      `bigquery-public-data.google_analytics_sample.ga_sessions_2017`,
      UNNEST (hits) hits,
      UNNEST (hits.product) product
  WHERE 
      product.productRevenue IS NULL
      AND totals.transactions IS NULL
      AND _TABLE_SUFFIX  BETWEEN '0601' AND '0731'
  GROUP BY month
)
SELECT *
FROM Purchaser
LEFT JOIN NonPurchaser 
USING (month)
ORDER BY month



--Q5
SELECT
      FORMAT_DATE('%Y%m' , PARSE_DATE('%Y%m%d', date)) AS month,
      ROUND(SUM(totals.transactions) / COUNT (DISTINCT fullVisitorId),4) AS avg_pageviews_purchase,
FROM 
     `bigquery-public-data.google_analytics_sample.ga_sessions_201707`,
     UNNEST (hits) hits,
     UNNEST (hits.product) product
WHERE product.productRevenue IS NOT NULL
     AND totals.transactions >=1 
GROUP BY month



--Q6
With product_data as (
  SELECT
      FORMAT_DATE('%Y%m' , PARSE_DATE('%Y%m%d', date)) AS month,
      SUM(SAFE_CAST(product.productRevenue AS INT64))/ 1000000.0 AS revenue,
      SUM(totals.visits) AS visit
  FROM 
     `bigquery-public-data.google_analytics_sample.ga_sessions_201707`,
      UNNEST (hits) hits,
      UNNEST (hits.product) product
  WHERE 
      totals.transactions >=1
      AND product.productRevenue IS NOT NULL
      GROUP BY month
)
SELECT month, 
      ROUND(revenue / visit, 2) avg_revenue_by_user_per_visit
FROM product_data



--Q7
WITH ID AS(
  SELECT DISTINCT fullVisitorId AS ID_name
  FROM 
     `bigquery-public-data.google_analytics_sample.ga_sessions_201707`,
      UNNEST (hits) hits,
      UNNEST (hits.product) product
  WHERE 
      product.v2ProductName="YouTube Men's Vintage Henley"
      AND product.productRevenue IS NOT NULL
      AND totals.transactions >=1
)
SELECT product.v2ProductName AS other_purchased_products, 
      SUM(product.productQuantity) AS quantity
FROM 
			`bigquery-public-data.google_analytics_sample.ga_sessions_201707`,
      UNNEST (hits) hits,
      UNNEST (hits.product) product
WHERE 
      product.v2ProductName <>"YouTube Men's Vintage Henley"
      AND fullVisitorId IN (SELECT ID_name FROM ID)
      AND product.productRevenue IS NOT NULL
      AND totals.transactions >=1
GROUP BY product.v2ProductName
ORDER BY quantity DESC



--Q8
WITH ViewProduct AS (
  SELECT
    FORMAT_DATE('%Y%m', PARSE_DATE('%Y%m%d', date)) AS month,
    COUNT(product.v2ProductName) AS num_product_view
  FROM
    `bigquery-public-data.google_analytics_sample.ga_sessions_*`,
    UNNEST (hits) hits,
    UNNEST (hits.product) product
  WHERE
    _TABLE_SUFFIX BETWEEN '20170101' AND '20170331'
    AND hits.ecommerceaction.action_type = '2'
  GROUP BY month
)
,
Addtocart AS (
  SELECT
    FORMAT_DATE('%Y%m', PARSE_DATE('%Y%m%d', date)) AS month,
    COUNT(product.v2ProductName) AS num_addtocart
  FROM
    `bigquery-public-data.google_analytics_sample.ga_sessions_*`,
    UNNEST (hits) hits,
    UNNEST (hits.product) product
  WHERE
    _TABLE_SUFFIX BETWEEN '20170101' AND '20170331'
    AND hits.ecommerceaction.action_type = '3'
  GROUP BY month
)
,
Purchase AS (
  SELECT
    FORMAT_DATE('%Y%m', PARSE_DATE('%Y%m%d', date)) AS month,
    COUNT(product.v2ProductName) AS num_purchase
  FROM
    `bigquery-public-data.google_analytics_sample.ga_sessions_*`,
    UNNEST (hits) hits,
    UNNEST (hits.product) product
  WHERE
    _TABLE_SUFFIX BETWEEN '20170101' AND '20170331'
    AND hits.ecommerceaction.action_type = '6'
    AND product.productRevenue IS NOT NULL 
  GROUP BY
    month
)
SELECT *, 
ROUND(num_addtocart/num_product_view * 100.0, 2) AS add_to_cart_rate, 
ROUND(num_purchase/num_product_view * 100.0, 2) AS purchase_rate
FROM ViewProduct
LEFT JOIN Addtocart
USING(month)
LEFT JOIN Purchase
USING(month)
ORDER BY month;