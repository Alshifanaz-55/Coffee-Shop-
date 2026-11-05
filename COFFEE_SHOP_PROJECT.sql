
CREATE DATABASE Coffeeshopdb

USE coffeeshopdb

SELECT * FROM City 
SELECT*FROM customers 
SELECT*FROM Products
SElECT*FROM Sales

--1.Coffee Consumers Count
--How many people in each city are estimated to consume coffee, given that 25% of the population does?

SELECT city_name,
FORMAT((Population*0.25)/1000000,'N2') AS coffee_consumer_in_millions,
City_rank
FROM city
ORDER BY 2 DESC

--2.Total Revenue from Coffee Sales
--What is the total revenue generated from coffee sales across all cities in the last quarter of 2023?

SELECT SUM(total)AS total_revenue
FROM sales
WHERE DATEPART( YEAR, sale_date)=2023
AND 
DATEPART(QUARTER, sale_date)=4


SELECT ci.city_name,
SUM(s.total) AS total_revenue
FROM sales s
JOIN customers c
ON s.customer_id=c.customer_id
JOIN city ci
ON ci.city_id=c.city_id
WHERE DATEPART(YEAR,s.sale_date) =2023
AND DATEPART(QUARTER, s.sale_date)=4
GROUP BY ci.city_name
ORDER BY 2 DESC

--3.Sales Count for Each Product
--How many units of each coffee product have been sold?

SELECT p.Product_name,
COUNT(s.sale_id)AS total_unit_sold
From Products p
LEFT JOIN Sales s
ON p.Product_id=s.Product_id
GROUP BY p.product_name
ORDER BY 2 DESC

--4.Average Sales Amount per City
--What is the average sales amount per customer in each city?

SELECT c.city_name,
SUM(s.total)/COUNT(DISTINCT S.customer_id)AS avg_sales_per_customer
FROM sales s
JOIN customers cust 
ON s.customer_id=cust.customer_id
JOIN city c 
ON cust.city_id=c.city_id
GROUP BY c.city_name 

--5.City Population and Coffee Consumers
--Provide a list of cities along with their populations and estimated coffee consumers.

WITH city_table as 

	(SELECT 
		city_name,
		ROUND((population * 0.25)/1000000, 2) as coffee_consumers
	FROM city),

customers_table
AS
(
	SELECT 
		ci.city_name,
		ci.population,
		COUNT(DISTINCT c.customer_id) as unique_cx
	FROM customers c
	JOIN city as ci
	ON ci.city_id = c.city_id
	GROUP BY ci.city_name,ci.population
)
SELECT 
	customers_table.city_name,
	customers_table.population,
	city_table.coffee_consumers as coffee_consumer_in_millions,
	customers_table.unique_cx
FROM city_table
JOIN 
customers_table
ON city_table.city_name = customers_table.city_name

--6.Top Selling Products by City
--What are the top 3 selling products in each city based on sales volume?

SELECT*FROM
   ( SELECT
	     c.city_name,
		 p.product_name,
		 COUNT(s.sale_id) AS sales_volume,
		 DENSE_RANK() OVER (PARTITION BY c.city_name ORDER BY COUNT(s.sale_id) DESC) AS product_rank
     FROM
	     city c
	 JOIN
	     customers cust ON c.city_id=cust.city_id
	 JOIN
	     sales s ON cust.customer_id=s.customer_id
     JOIN 
	     Products p ON s.product_id=p.product_id
	 GROUP BY 
	     c.city_name,
		 p.product_name
		 ) AS t1
		WHERE product_rank <= 3 


--7.Customer Segmentation by City
--How many unique customers are there in each city who have purchased coffee products?

SELECT c.city_name,
COUNT(DISTINCT cust.customer_id) AS unique_customers
FROM city c
JOIN customers cust
ON c.city_id=cust.city_id
GROUP  BY c.city_name
ORDER by unique_customers DESC

--8.Average Sale vs Rent
--Find each city and their average sale per customer and avg rent per customer

SELECT 
    c.city_name,
   
    CAST(SUM(p.price)*1.0/ COUNT(DISTINCT s.customer_id) AS Decimal(18,2)) AS avg_sale_per_customer,
   
    CAST(c.estimated_rent*1.0 / COUNT(DISTINCT s.customer_id) AS Decimal(18,2)) AS avg_rent_per_customer
FROM 
    city c
JOIN 
    customers cus ON c.city_id = cus.city_id
JOIN 
    sales s ON cus.customer_id = s.customer_id
JOIN 
    products p ON s.product_id = p.product_id
GROUP BY 
    c.city_name, 
    c.estimated_rent
ORDER BY 
        avg_sale_per_customer DESC

--9.Monthly Sales Growth
--Sales growth rate: Calculate the percentage growth (or decline) in sales over different time periods (monthly).

WITH
monthly_sales
AS
(
	SELECT 
		ci.city_name,
		DATEPART(MONTH,sale_date) as month,
		DATEPART(YEAR,sale_date) as YEAR,
		SUM(s.total) as total_sale
	FROM sales as s
	JOIN customers as c
	ON c.customer_id = s.customer_id
	JOIN city as ci
	ON ci.city_id = ci.city_id
	GROUP BY ci.city_name,DATEPART(MONTH,sale_date),DATEPART(YEAR,sale_date) 
	
),
growth_ratio
AS
(
		SELECT
			city_name,
			month,
			year,
			total_sale as cr_month_sale,
			LAG(total_sale, 1) OVER(PARTITION BY city_name ORDER BY year, month) as last_month_sale
		FROM monthly_sales
)

SELECT
	city_name,
	month,
	year,
	cr_month_sale,
	last_month_sale,
	ROUND(
		(cr_month_sale-last_month_sale)* 100/
		last_month_sale, 2
		) as growth_ratio

FROM growth_ratio
WHERE 
	last_month_sale IS NOT NULL

--10.Market Potential Analysis
--Identify top 3 city based on highest sales, return city name, total sale, total rent, total customers, estimated coffee consumer

SELECT TOP 3
c.city_name,
SUM(s.total) AS total_sale,
c.estimated_rent AS total_rent,
COUNT(DISTINCT s.customer_id) AS total_customers,
c.population AS estimated_coffee_consumer
FROM sales s
JOIN customers cust
ON s.customer_id=cust.customer_id
JOIN city c
ON cust.city_id=c.city_id
GROUP BY c.city_name,
c.estimated_rent,
c.population 
ORDER BY total_sale DESC

--11.City Revenue Contribution
--Calculate each city's percentage contribution to total company revenue.
--Rank the cities from highest to lowest contribution.

SELECT 
    c.city_name,
    SUM(p.price) AS city_revenue,
    CAST((SUM(p.price) * 100.0) / SUM(SUM(p.price)) OVER() AS DECIMAL(18, 2)) AS percentage_contribution,
			 DENSE_RANK() OVER (ORDER BY SUM(p.price)DESC) AS city_rank

FROM 
    city c
JOIN 
    customers cus ON c.city_id = cus.city_id
JOIN 
    sales s ON cus.customer_id = s.customer_id
JOIN 
    products p ON s.product_id = p.product_id
GROUP BY 
    c.city_name
ORDER BY 
    percentage_contribution DESC
