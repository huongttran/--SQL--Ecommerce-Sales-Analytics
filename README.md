# [SQL] Ecommerce Sales Analytics
Analyze e-commerce transactions using SQL to discover sales trends, customer behavior, and product performance insights for better business decisions.
## 📕 Table Of Contents


## 🛒 Introduction
> Khi thị trường điện thoại bùng nổ, nhóm phân tích nhận ra rằng dữ liệu giao dịch ẩn chứa vô số câu chuyện thú vị: ai đang mua, họ mua gì, ở đâu và vì sao lại chọn hình thức trả góp hay mua thêm phụ kiện.
> 
> Vì vậy, Hương đã khởi động một project mới – “Phone Data Insight” – nhằm khai phá dữ liệu bán hàng và giúp doanh nghiệp hiểu rõ khách hàng hơn bao giờ hết.
>
> Mục tiêu của dự án là theo dõi xu hướng mua sắm, đo lường doanh thu và phát hiện những hành vi tiềm năng để từ đó giúp doanh nghiệp dự báo nhu cầu, tối ưu chiến lược bán hàng và phát triển bền vững trong tương lai.

## 📂 Dataset
The eCommerce dataset is publicly hosted on Google BigQuery. You can connect and explore it directly without downloading any files.
1. Log in to your [Google Cloud Console](https://console.cloud.google.com/)
2. Open BigQuery and select your working project.
3. In the navigation panel, choose **Add Data** → Search a project **bigquery-public-data.google_analytics_sample.ga_sessions_**
4. You can now write SQL queries directly in the BigQuery Editor.
### `ga_sessions`
<details>
<summary> View Description Table </summary>
  
| Field Name | Data Type | Description |
|-------------|------------|-------------|
| `fullVisitorId` | STRING | The unique visitor ID. |
| `date` | STRING | The date of the session in YYYYMMDD format. |
| `totals.bounces` | INTEGER | Total bounces (for convenience). For a bounced session, the value is 1; otherwise it is null. |
| `totals.hits` | INTEGER | Total number of hits within the session. |
| `totals.pageviews` | INTEGER | Total number of pageviews within the session. |
| `totals.timeOnSite` | INTEGER | Total time on site (in seconds). |
| `totals.transactions` | INTEGER | Total number of e-commerce transactions within the session. |
| `trafficSource.source` | STRING | Source of traffic (search engine, referrer hostname, or UTM source). |
| `hits.eCommerceAction` | RECORD | Contains all e-commerce hits that occurred during the session. Each record entry represents an action (e.g., product view, add to cart, checkout, purchase). |
| `hits.eCommerceAction.action_type` | INTEGER | Indicates the type of e-commerce action. 1=Product list view, 2=Product detail view, 3=Add to cart, 4=Remove from cart, 5=Checkout, 6=Purchase, 7=Refund, 8=Checkout options, 0=Unknown. |
| `hits.product.productQuantity` | INTEGER | Quantity of the product purchased. |
| `hits.product.productRevenue` | INTEGER | Product revenue, expressed as the value passed to Analytics multiplied by 10^6 (e.g., 2.40 would be 2400000). |
| `hits.product.productSKU` | STRING | Product SKU. |
| `hits.product.v2ProductName` | STRING | Product name. |

</details>
  
## 🎯 Case Study Questions
1. Calculate total visit, pageview, transaction for Jan, Feb and March 2017 
2. Bounce rate per traffic source in July 2017
3. Revenue by traffic source by week, by month in June 2017
4. Average number of page views by purchaser type (purchasers vs non-purchasers) in June, July 2017.
5. Average number of transactions per user that made a purchase in July 2017
6. Average amount of money spent per session. Only include purchaser data in July 2017
7. Other products purchased by customers who purchased product "YouTube Men's Vintage Henley" in July 2017. Output should show product name and the quantity was ordered.
8. Calculate cohort map from product view to addtocart to purchase in Jan, Feb and March 2017. For example, 100% product view then 40% add_to_cart and 10% purchase.

## Solutions
### Q1: Calculate total visit, pageview, transaction for Jan, Feb and March 2017
```sql
SELECT 
      FORMAT_DATE('%Y%m' , PARSE_DATE('%Y%m%d', date)) AS month, 
      COUNT(fullVisitorId) AS total,
      SUM(totals.pageviews) AS pageviews,
      SUM(totals.transactions) AS transactions
FROM `bigquery-public-data.google_analytics_sample.ga_sessions_2017*` 
WHERE _TABLE_SUFFIX BETWEEN '0101' AND '0331'
GROUP BY month 
ORDER BY month;
```
| month | total | pageviews | transactions |
|--------|--------|------------|---------------|
| 201701 | 64694 | 257708 | 713 |
| 201702 | 62192 | 233373 | 733 |
| 201703 | 69931 | 259522 | 993 |

### Q2: Bounce rate per traffic source in July 2017
```sql
SELECT trafficSource.`source`, 
        SUM (totals.visits) AS total_visits,
        SUM (totals.bounces) AS total_no_of_bounces,
        ROUND(SUM (totals.bounces) /SUM (totals.visits) * 100.0,2) AS bounce_rate
FROM `bigquery-public-data.google_analytics_sample.ga_sessions_201707*`
GROUP BY trafficSource.`source`
ORDER BY total_visits DESC
```
| source               | total_visits | total_no_of_bounce | bounce_rate |
|----------------------|---------------|---------------------|--------------|
| google               | 38400         | 19798               | 51.557       |
| (direct)             | 19891         | 8606                | 43.266       |
| youtube.com          | 6351          | 4238                | 66.73        |
| analytics.google.com | 1972          | 1064                | 53.955       |
| Partners             | 1788          | 936                 | 52.349       |
| m.facebook.com       | 669           | 430                 | 64.275       |
| google.com           | 368           | 183                 | 49.728       |
| dfa                  | 302           | 124                 | 41.06        |
| sites.google.com     | 230           | 97                  | 42.174       |

### Q3: Revenue by traffic source by week, by month in June 2017

```sql
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
```
| time_type | month  | source   | revenue     |
|------------|---------|----------|-------------|
| Month      | 201706 | (direct) | 97333.6197  |
| Week       | 201724 | (direct) | 30908.9099  |
| Week       | 201725 | (direct) | 27295.3199  |
| Month      | 201706 | google   | 18757.1799  |
| Week       | 201723 | (direct) | 17325.6799  |
| Week       | 201726 | (direct) | 14914.81    |
| Week       | 201724 | google   | 9217.17     |
| Month      | 201706 | dfa      | 8862.23     |
| Week       | 201722 | (direct) | 6888.9      |


### Q4: Average number of page views by purchaser type (purchasers vs non-purchasers) in June, July 2017.

```sql
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
```
| month  | avg_pageviews_purchase | avg_pageviews_non_purchase |
|--------|-------------------------|-----------------------------|
| 201706 | 94.02                  | 316.87                      |
| 201707 | 124.24                 | 334.06                      |

### Q5: Average number of transactions per user that made a purchase in July 2017
```sql
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
```
| month  | avg_pageviews_purchase |
|--------|-------------------------|
| 201707 | 4.1639                 |


### Q6: Average amount of money spent per session. Only include purchaser data in July 2017
```sql
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
```
| month  | avg_revenue_by_user_per_visit |
|--------|-------------------------------|
| 201707 | 43.86                         |


### Q7: Other products purchased by customers who purchased product "YouTube Men's Vintage Henley" in July 2017. Output should show product name and the quantity was ordered.

```sql
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
FROM `bigquery-public-data.google_analytics_sample.ga_sessions_201707`,
      UNNEST (hits) hits,
      UNNEST (hits.product) product
WHERE 
      product.v2ProductName <>"YouTube Men's Vintage Henley"
      AND fullVisitorId IN (SELECT ID_name FROM ID)
      AND product.productRevenue IS NOT NULL
      AND totals.transactions >=1
GROUP BY product.v2ProductName
ORDER BY quantity DESC
```

| other_purchased_products                     | quantity |
|----------------------------------------------|-----------|
| Google Sunglasses                            | 20        |
| Google Women's Vintage Hero T                | 7         |
| SPF-15 Slim & Slender Lip Balm               | 6         |
| Google Women's Short Sleeve H                | 4         |
| YouTube Men's Fleece Hoodie                  | 3         |
| Google Men's Short Sleeve Bad                | 3         |
| Recycled Mouse Pad                           | 2         |
| YouTube Twill Cap                            | 2         |
| Red Shine 15 oz Mug                          | 2         |


### Q8: Calculate cohort map from product view to addtocart to purchase in Jan, Feb and March 2017. For example, 100% product view then 40% add_to_cart and 10% purchase. 
```sql
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
```
| month  | num_product_view | num_addtocart | num_purchase | add_to_cart_rate | purchase_rate |
|--------|------------------|---------------|---------------|------------------|----------------|
| 201701 | 25787            | 7342          | 2143          | 28.47            | 8.31           |
| 201702 | 21489            | 7360          | 2060          | 34.25            | 9.59           |
| 201703 | 23549            | 8782          | 2977          | 37.29            | 12.64          |
