# PART 1 

create database sales_and_delivery;
show tables;
use sales_and_delivery;

# 1. Find the top 3 customers who have the maximum number of orders
select cd.Cust_id, Customer_name, count(Ord_id) as no_of_orders
from cust_dimen cd
join market_fact mf on cd.Cust_id=mf.Cust_id
group by 1,2 order by 3 desc limit 3;



# 2. Create a new column DaysTakenForDelivery that contains the date difference between Order_Date and Ship_Date. 

select order_id,Ord_ID, Order_Date, Order_Priority, Order_Date, Ship_Date,
abs(datediff(str_to_date(ship_date,'%d-%m-%y'),
str_to_date(order_date,'%d-%m-%y'))) as daystakenfordelivery
from orders_dimen
join shipping_dimen
using (order_id);


# 3. Find the customer whose order took the maximum time to get delivered

select t.ord_id, mf.cust_id, Customer_Name, DaysTakenForDelivery from 
(select ord_id, abs(datediff(str_to_date(Order_date, '%d-%m-%Y'),
((str_to_date(Ship_date, '%d-%m-%Y'))))) as DaysTakenForDelivery
from orders_dimen 
join shipping_dimen using(Order_id) order by 2 desc limit 1) t 
join market_fact mf on t.Ord_id=mf.Ord_id
join cust_dimen cd on cd.Cust_id=mf.Cust_id; 


# 4. Retrieve total sales made by each product from the data (use Windows function)

select distinct prod_id, 
round(sum(sales)over(partition by prod_id),2) as total_sales
from market_fact order by 2 desc;


# 5. Retrieve the total profit made from each product from the data (use windows function)

select distinct prod_id, 
round(sum(profit)over(partition by prod_id),2) as total_profit 
from market_fact
order by 2 desc;


# 6. Count the total number of unique customers in January and how many of them came back every month over the entire year in 2011
      
select count(distinct JC.cust_id) as January_customers_2011,
sum(case when FYC.total_months >3 then 1 else 0 end) as Returning_customers_2011
from
(select distinct cust_id from market_fact join orders_dimen using(ord_id)
 where year(str_to_date(Order_date, '%d-%m-%Y')) = 2011
 and month(str_to_date(Order_date, '%d-%m-%Y')) = 1) as JC
left join 
(select cust_id, count(distinct month(str_to_date(Order_date, '%d-%m-%Y'))) as total_months
 from market_fact join orders_dimen using(ord_id)
 where year(str_to_date(Order_date, '%d-%m-%Y')) = 2011
 group by 1) FYC on JC.cust_id = FYC.cust_id;








# PART 2

create database restaurant;
use restaurant;

# 1.  We need to find out the total visits to all restaurants under all alcohol categories available.

select alcohol,
sum(count(userid))over(partition by alcohol) as total_visits
from geoplaces2
join rating_final using(placeid)
group by alcohol;


# 2. Let's find out the average rating according to alcohol and price so that we can understand 
#the rating in respective price categories as well.

select alcohol, price, avg(rating) as avg_rating 
from geoplaces2 join rating_final using(placeID) 
group by 1,2 order by 1;


# 3.  Let’s write a query to quantify that what are the parking availability as well in different
## alcohol categories along with the total number of restaurants.

select alcohol,parking_lot,count(placeID) as no_of_resturants
from geoplaces2 join chefmozparking using(placeID) 
group by 1,2 order by 1,2,3 desc;


# 4. Also take out the percentage of different cuisine in each alcohol type

select alcohol, rcuisine, count(*) as cuisine_count,
sum(count(*))over(partition by alcohol) AS total_alcohol_count,
round((count(*) * 100.0) / sum(count(*))over(partition by alcohol),2) as percentage
from geoplaces2 join chefmozcuisine using (placeID)
group by 1,2 order by 1,2;


# 5. let’s take out the average rating of each state.

select case when state in ('SLP', 'S.L.P.', 'SAN LUIS POTOS', 'SAN LUIS POTOSI') then 'SLP'
when state='?' then 'UNKNOWN' else upper(state) end as state, avg(rating) as avg_rating
from geoplaces2 join rating_final using (placeID) group by 1 order by 1;


# 6. ' Tamaulipas' Is the lowest average rated state. Quantify the reason why it is the lowest rated by 
## providing the summary on the basis of State, alcohol, and Cuisine.

select state, alcohol, rcuisine
from geoplaces2 join chefmozcuisine using(placeID) 
where state='Tamaulipas'
group by 3,2,1;


# 7. Find the average weight, food rating, and service rating of the customers who have visited KFC and 
## tried Mexican or Italian types of cuisine, and also their budget level is low. We encourage you to give it a try by not using joins.

select round(avg(food_rating),2) as avg_food_rating, round(avg(service_rating),2) as avg_serv_rating,
(select round(avg(weight),2) from userprofile where userid in
(select userid from usercuisine where rcuisine like '%Mex%' or rcuisine like '%ital%') 
and userid in (select userid from userprofile where budget='low')) as avg_wgt
from rating_final
where userid in
(select userid from userprofile
where userid in (select userid from usercuisine where rcuisine like '%Mex%' or rcuisine like '%ital%') 
and userid in (select userid from userprofile where budget='low'))
and placeID = (select placeID from geoplaces2 where name like '%kfc%' );






# PART 3 - TRIGGERS

create database miniproject;
use miniproject;

create table Student_details (Student_id int auto_increment primary key,
							  Student_name varchar(50),
							  mail_id varchar(50),
							  mobile_no varchar(15));

create table Student_details_backup (Student_id int primary key,
									 Student_name varchar(50),
									 mail_id varchar(50),
									 mobile_no varchar(15));

insert into Student_details (Student_name, mail_id, mobile_no)
values ('Rajesh Khanna', 'Raj@gmail.com', '9845287917'),
       ('Amitabh Bacchan', 'Amit@gmail.com', '7866836345'),
       ('Dharmendra Deol', 'Dharm@gmail.com', '9489095621'),
       ('Rishi Kapoor', 'Rishi@gmail.com', '6638945690');

select * from student_details;
select * from student_details_backup;
       
-- Your query should insert the rows in the backup table before deleting the records from student details.

delimiter //
create trigger backing_up after delete on student_details
for each row begin 
insert into student_details_backup (Student_id,Student_name,mail_id,mobile_no)
values (OLD.Student_id, OLD.Student_name, OLD.mail_id, OLD.mobile_no);
end ; 
// delimiter ;


delete from student_details where student_name='Dharmendra Deol';

select * from student_details;
select * from student_details_backup;



## Major Challenges:

use restaurant;
# Q1: find places that serve alcohol that open in the morning;  

select distinct placeID, name, hours, alcohol
from chefmozhours4 join geoplaces2 using (placeID)
where alcohol not like '%no%'
and substring(hours,1,2) between 7 and 8
order by 4,3;

#Q2: What affect does the dress_code have on the service_rating? 

select distinct dress_code, dress_preference, avg(service_rating) as avg_service_rating 
from geoplaces2 gp join rating_final rf on rf.placeID=gp.placeID 
join userprofile up on rf.userID=up.userID
where dress_preference <> '?' group by 1,2;


use sales_and_delivery;
#Q3: Display the minimum and maximum shipping cost and the shipping mode of that.

select cust_id, shipping_cost, ship_mode
from market_fact join shipping_dimen using(ship_id)
where Shipping_Cost = (select min(shipping_cost) from market_fact) 
or shipping_cost = (select max(shipping_cost) from market_fact)
order by 3;


#Q4: Sort Products on the basis of their demand

SELECT Product_Category, Product_sub_category, Prod_id, SUM(Order_Quantity) AS Total_Demand
FROM market_fact join prod_dimen using (prod_id)
GROUP BY 3,2,1 order by 4 desc;


-- THE END