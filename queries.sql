--  запрос, который считает общее количество покупателей из таблицы customers. Назовите колонку customers_count
select count (distinct customer_id ) as customers_count 
from customers c 
-- 5 ШАГ И ТРИ ОТЧЕТА--
/*Первый отчет о десятке лучших продавцов. 
 * Таблица состоит из трех колонок - данных о продавце, 
 * суммарной выручке с проданных товаров и количестве проведенных сделок, и отсортирована по убыванию выручки
 */
select
	CONCAT(e.first_name , ' ', e.last_name) as seller,
	count(s.sales_id ) as operations,
	FLOOR(SUM(s.quantity *p.price )) as income
from sales s
left join products p on s.product_id = p.product_id 
left join employees e on s.sales_person_id = e.employee_id 
group by seller 
order by income desc
LIMIT 10

/*Второй отчет  о продавцах, чья средняя выручка за сделку меньше средней выручки за сделку по всем продавцам
 *Таблица отсортирована по выручке по возрастанию.
 */
WITH AVG_ALL AS (
	select
		AVG(s.quantity *p.price ) as average_all
	from sales s
	left join products p on s.product_id = p.product_id 
)

select
	CONCAT(e.first_name , ' ', e.last_name) as seller,
	FLOOR(AVG(s.quantity *p.price )) as average_income
from sales s
left join products p on s.product_id = p.product_id 
left join employees e on s.sales_person_id = e.employee_id 
group by seller 
HAVING AVG(s.quantity *p.price ) < (SELECT average_all FROM AVG_ALL)
order by average_income ASC

/*Третий отчет  информацию о выручке по дням недели.
 *Каждая запись содержит имя и фамилию продавца, день недели и суммарную выручку.
 *Отсортируйте данные по порядковому номеру дня недели и seller
 */
select
	CONCAT(e.first_name , ' ', e.last_name) as seller,
	to_char(s.sale_date , 'fmday') as day_of_week,
	FLOOR(SUM(s.quantity *p.price )) as income
from sales s
left join products p on s.product_id = p.product_id 
left join employees e on s.sales_person_id = e.employee_id 
group by seller,day_of_week,EXTRACT(ISODOW FROM s.sale_date)
order by  EXTRACT(ISODOW FROM s.sale_date),seller  asc

-- 6 ШАГ И ТРИ ОТЧЕТА--
/*Первый отчет - количество покупателей в разных возрастных группах: 16-25, 26-40 и 40+.
 * Итоговая таблица должна быть отсортирована по возрастным группам
 */
select
    case
        when age between 16 and 25 then '16-25'
        when age between 26 and 40 then '26-40'
        else '40+'
    end as age_category,
    COUNT(distinct (c.customer_id )) as age_count
from customers c 
group by age_category
order by age_category

/*Во втором отчете предоставьте данные по количеству уникальных покупателей и выручке, которую они принесли.
 *  Сгруппируйте данные по дате, которая представлена в числовом виде ГОД-МЕСЯЦ.
 *  Итоговая таблица должна быть отсортирована по дате по возрастанию
 */
select
	to_char(s.sale_date,'YYYY-MM') as selling_month,
	count(distinct(s.customer_id) ) as total_customers,
	floor(sum(s.quantity*p.price )) as income
from sales s 
left join products p on s.product_id = p.product_id
group by selling_month

/*Третий отчет следует составить о покупателях, 
 * первая покупка которых была в ходе проведения акций (акционные товары отпускали со стоимостью равной 0).
 *  Итоговая таблица должна быть отсортирована по id покупателя.
 */
WITH First_Rows as (
select
	concat(c.first_name,' ',c.last_name) as customer,
	s.sale_date as sale_date,
	concat(e.first_name,' ',e.last_name) as seller,
	FIRST_VALUE(p.price * s.quantity)
        OVER (PARTITION BY c.customer_id  ORDER BY s.sale_date) as frst_value,
    FIRST_VALUE(s.sale_date)
        OVER (PARTITION BY c.customer_id  ORDER BY s.sale_date) as frst_date
from sales s 
left join employees e on s.sales_person_id = e.employee_id 
left join customers c on s.customer_id = c.customer_id
left join products p on s.product_id = p.product_id
order by c.customer_id
)

select
	customer,
    sale_date,
	seller
from First_Rows
where frst_value = 0 and sale_date = frst_date
group by customer,sale_date,seller
