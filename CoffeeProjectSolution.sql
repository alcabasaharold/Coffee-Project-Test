-- Monday coffee -- data analysis
SELECT * FROM city;
SELECT * FROM products;
SELECT * FROM customers;
SELECT * FROM sales

-- Reports and Data Analysis

-- Q1. Coffee Consumers Count
--How many people in each city are estimated to consume coffee, given that 25% of the population does?
SELECT
	city_name,
	ROUND(
	(population * 0.25)/1000000
	,2) as coffee_consumer_millions,
	city_rank
FROM city
ORDER BY population DESC;

-- Q2 Total Revenue from Coffee Sales
-- What is the total revenue generated from coffee sales across all cities in the last quarter of 2023?
SELECT
	c1.city_name,
	SUM(s.total) as total_revenue,
	DENSE_RANK() OVER (ORDER BY SUM(s.total) DESC) as rnk
FROM sales s
JOIN customers c
ON c.customer_id = s.customer_id
JOIN city c1
ON c1.city_id = c.city_id
WHERE 
	EXTRACT(YEAR FROM s.sale_date) = 2023 
	AND 
	EXTRACT(QUARTER FROM s.sale_date) = 4
GROUP BY c1.city_name;

-- Q3 Sales Count for Each Product
-- How many units of each coffee product have been sold?
SELECT
	p.product_name,
	COUNT(s.sale_id) as coffee_units_sold
FROM products p
LEFT JOIN sales s
ON s.product_id = p.product_id
GROUP BY 
	p.product_name
ORDER BY coffee_units_sold DESC;

-- Q4 Average Sales Amount per City
--What is the average sales amount per customer in each city?
SELECT
	c1.city_name,
	SUM(s.total) as total_revenue,
	COUNT(DISTINCT s.customer_id) as total_customer,
	ROUND(
		SUM(s.total)::numeric/
			COUNT(DISTINCT s.customer_id)::numeric
	,2) as avg_sales_customer_city
FROM sales s
JOIN customers c
ON c.customer_id = s.customer_id
JOIN city c1
ON c1.city_id = c.city_id
GROUP BY c1.city_name
ORDER BY total_revenue DESC;

-- Q5 City Population and Coffee Consumers
-- Provide a list of cities along with their populations and estimated coffee consumers.
WITH city_consumer AS (
SELECT
	city_name,
	ROUND((population * 0.25)/1000000,2) as coffee_consumer_millions
FROM city
),
customer_table AS(
SELECT
	c1.city_name,
	COUNT(DISTINCT c.customer_id) as costumer_per_city
FROM sales s
JOIN customers c
ON c.customer_id = s.customer_id
JOIN city c1
ON c1.city_id = c.city_id
GROUP BY c1.city_name
)
SELECT
	city_consumer.city_name,
	city_consumer.coffee_consumer_millions,
	customer_table.costumer_per_city
FROM city_consumer
JOIN customer_table
ON customer_table.city_name = city_consumer.city_name;
	

-- Q6 Top Selling Products by City
--What are the top 3 selling products in each city based on sales volume?
WITH CTE AS (
SELECT
	ci.city_name,
	p.product_name,
	COUNT(s.sale_id) as total_sales,
	DENSE_RANK() OVER (PARTITION BY ci.city_name ORDER BY COUNT(s.sale_id) DESC) as rank
FROM sales s
JOIN products p
ON p.product_id = s.product_id
JOIN customers c
ON c.customer_id = s.customer_id
JOIN city ci
ON ci.city_id = c.city_id
GROUP BY 1,2
)
SELECT * FROM CTE
WHERE rank <=3;

-- Q7 Customer Segmentation by City
--How many unique customers are there in each city who have purchased coffee products?
SELECT 
	ci.city_name,
	COUNT(DISTINCT c.customer_id) as total_customer
FROM sales s
JOIN products p
ON p.product_id = s.product_id
JOIN customers c
ON c.customer_id = s.customer_id
JOIN city ci
ON ci.city_id = c.city_id
WHERE p.product_id IN (1,2,3,4,5,6,7,8,9,10,11,12,13,14)
GROUP BY 1
ORDER BY 2 DESC;

-- Q8 Average Sale vs Rent
--Find each city and their average sale per customer and avg rent per customer
WITH city_table AS (
SELECT
	c1.city_name,
	COUNT(DISTINCT s.customer_id) as total_customer,
	ROUND(
		SUM(s.total)::numeric/
			COUNT(DISTINCT s.customer_id)::numeric
	,2) as avg_sales_customer_city
FROM sales s
JOIN customers c
ON c.customer_id = s.customer_id
JOIN city c1
ON c1.city_id = c.city_id
GROUP BY 1
ORDER BY 3 DESC
)
SELECT
	c.city_name,
	ct.total_customer,
	ct.avg_sales_customer_city,
	ROUND((c.estimated_rent::numeric)/ct.total_customer::numeric,2) as avg_rent
FROM city c
JOIN city_table ct
ON ct.city_name = c.city_name
ORDER BY 3 DESC;

-- Q9Monthly Sales Growth
-- Sales growth rate: Calculate the percentage growth (or decline) in sales over different time periods (monthly).
WITH sale_per_year AS (
SELECT
	ci.city_name,
	EXTRACT(MONTH FROM s.sale_date) as month,
	EXTRACT(YEAR FROM s.sale_date) as year,
	SUM(s.total) as total_sale
FROM sales s
JOIN customers c
ON c.customer_id = s.customer_id
JOIN city ci
ON ci.city_id = c.city_id
GROUP BY 1,2,3
ORDER BY 1,3,2
),
growth_ratio AS(
SELECT
	city_name,
	month,
	year,
	total_sale as Monthly_Sales,
	LAG(total_sale,1) OVER (PARTITION BY city_name ORDER BY year, month) as prev_month
FROM sale_per_year
)
SELECT
	city_name,
	month,
	year,
	Monthly_Sales,
	prev_month,
	ROUND(
		(Monthly_Sales - prev_month)::numeric 
			/ prev_month::numeric * 100
				,2) as growth_per_month
FROM growth_ratio
WHERE prev_month IS NOT NULL;

-- Q10Market Potential Analysis
-- Identify top 3 city based on highest sales, return city name, total sale, total rent, total customers, estimated coffee consumer
WITH cte AS (
SELECT 
	ci.city_name,
	ci.estimated_rent,
	SUM(s.total) as total_sale,
	ROUND(SUM(s.total)::numeric/COUNT(DISTINCT c.customer_id)::numeric,2) as avg_sale_per_costumer,
	ROUND(ci.estimated_rent::numeric/COUNT(DISTINCT c.customer_id)::numeric,2) as avg_rent_per_customer,
	COUNT(DISTINCT c.customer_id) as total_customer,
	ROUND((ci.population * 0.25)/1000000,4) as estimated_consumer_millions
FROM sales s
JOIN products p
ON p.product_id = s.product_id
JOIN customers c
ON c.customer_id = s.customer_id
JOIN city ci
ON ci.city_id = c.city_id
GROUP BY 1, 7, 2
ORDER BY 3 DESC
)
SELECT
	city_name,
	total_sale,
	estimated_rent as total_rent,
	avg_sale_per_costumer,
	avg_rent_per_customer,
	total_customer,
	estimated_consumer_millions,
	DENSE_RANK() OVER (ORDER BY total_sale DESC) as ranking
FROM cte;

/*
-- Recomendation
City 1: Pune
	1. It has the highest total sales (1258290)
	2. It has the highest average sale per costumer (24197.88)
	3. The average rent is below 300
	
City 2: Chennai
	1. It has the 2nd highest total sales (944120)
	2. It has the 2nd highest average sale per costumer (17100)
	3. The average rent is below 500
	
City 3: Delhi
	1. It has the highest estimated consumer (7.7500 million)
	2. It has a good total sales (750420)
	3. The average rent is below 400
*/


























