#ALL_ad_hoc_sql_queries.


/*Provide the list of markets in which customer "Atliq Exclusive" operates its
business in the APAC region*/

select distinct market from dim_customer where customer="Atliq exclusive" and region="APAC";

/*2. What is the percentage of unique product increase in 2021 vs. 2020? The
final output contains these fields,
unique_products_2020
unique_products_2021
percentage_chg */

with unique_products_2020 as(
select count(distinct product_code) as 2020_unique_products from fact_sales_monthly
where fiscal_year=2020),

unique_products_2021 as (
select count(distinct product_code) as 2021_unique_products from fact_sales_monthly
where fiscal_year=2021)

select 2020_unique_products,
       2021_unique_products,
       round((2021_unique_products-2020_unique_products)/2020_unique_products*100,2) as pct_chg
from unique_products_2020,unique_products_2021;


/*Provide a report with all the unique product counts for each segment and
sort them in descending order of product counts. The final output contains
2 fields,
segment
product_count*/

select segment,count(product_code) as product_count from dim_product
group by segment
order by product_count desc;

/* Follow-up: Which segment had the most increase in unique products in
2021 vs 2020? The final output contains these fields,
segment
product_count_2020
product_count_2021
difference*/


with x as(
select segment, count(distinct product_code) as product_count_2020
from fact_sales_monthly
join dim_product
using(product_code)
where fiscal_year=2020
group by segment),

 y as(
select segment, count(distinct product_code) as product_count_2021
from fact_sales_monthly
join dim_product
using(product_code)
where fiscal_year=2021
group by segment)

select x.segment,
	   product_count_2020, 
       product_count_2021,
       (product_count_2021-product_count_2020) as diff
from x join y on y.segment=x.segment
order by diff desc;


/*Get the products that have the highest and lowest manufacturing costs.
The final output should contain these fields,
product_code
product
manufacturing_cost*/

with max as(
select p.product_code,
       p.product,
       manufacturing_cost
from fact_manufacturing_cost as m
join dim_product as p
on p.product_code=m.product_code
where manufacturing_cost=(select max(manufacturing_cost) from fact_manufacturing_cost)),

min as(
select p.product_code,
       p.product,
       manufacturing_cost
from fact_manufacturing_cost as m
join dim_product as p
on p.product_code=m.product_code
where manufacturing_cost=(select min(manufacturing_cost) from fact_manufacturing_cost))

select * from max
union
select * from min;

/*6. Generate a report which contains the top 5 customers who received an
average high pre_invoice_discount_pct for the fiscal year 2021 and in the
Indian market. The final output contains these fields,
customer_code
customer
average_discount_percentage*/


select c.customer_code,
	   c.customer,
       round(avg(pre_invoice_discount_pct)*100,2) as average_discount_prt
from dim_customer as c
join fact_pre_invoice_deductions as pid
on pid.customer_code=c.customer_code
where c.market="india" and pid.fiscal_year=2021
group by customer_code,customer
order by average_discount_prt desc
limit 5;


/*7. Get the complete report of the Gross sales amount for the customer “Atliq
Exclusive” for each month. This analysis helps to get an idea of low and
high-performing months and take strategic decisions.
The final report contains these columns:
Month
Year
Gross sales Amount*/


select monthname(s.date) as month,
       s.fiscal_year,
      (round(sum(p.gross_price* s.sold_quantity/1000000),2)) as gross_price_mil
from dim_customer as c
join fact_sales_monthly as s
on s.customer_code=c.customer_code
join fact_gross_price as p
on p.product_code=s.product_code
where c.customer="Atliq Exclusive"
group by monthname(s.date),s.fiscal_year
order by s.fiscal_year;



/*8. In which quarter of 2020, got the maximum total_sold_quantity? The final
output contains these fields sorted by the total_sold_quantity,
Quarter
total_sold_quantity*/

select
case
   when month(date) in (9,10,11) then "Q1"
   when month(date) in (12,1,2) then "Q2"
   when month(date) in (3,4,5) then "Q3"
   When month(date) in (6,7,8) then "Q4"
end as Quaters,
       (round(sum(sold_quantity)/1000000,2)) as total_sold_quantity
from fact_sales_monthly
where fiscal_year=2020
group by quaters
order by total_sold_quantity desc;


/*9. Which channel helped to bring more gross sales in the fiscal year 2021
and the percentage of contribution? The final output contains these fields,
channel
gross_sales_mln
percentage*/


With cte as(
select c.channel,
	   (round(sum(p.gross_price*s.sold_quantity),2)) as gross_sales
from fact_sales_monthly as s
join dim_customer as c on c.customer_code=s.customer_code
join fact_gross_price as p on p.product_code=s.product_code
where s.fiscal_year=2021
group by c.channel)

select channel,
       round(gross_sales/1000000,2) as gross_sales_mln,
       round((gross_sales)/(SELECT SUM(GROSS_SALES) FROM cte)*100,2) as percentage
from cte
group by channel
order by gross_sales_mln DESC;







/*10. Get the Top 3 products in each division that have a high
total_sold_quantity in the fiscal_year 2021? The final output contains these
fields,
division
product_code
codebasics.io
product
total_sold_quantity
rank_order*/


with cte as (
select 
      p.division,
      p.product_code,
      p.product,
      concat(round(sum(s.sold_quantity/1000000),2)) as total_sold_quantity_Mil,
      dense_rank() over(partition by p.division order by sum(s.sold_quantity) desc) as rank_order
from dim_product as p
join fact_sales_monthly as s
on s.product_code=p.product_code
where s.fiscal_year=2021
group by p.division,p.product_code,p.product)

select * from cte 
where rank_order<=3
order by division,rank_order;













