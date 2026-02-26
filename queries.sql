--  запрос, который считает общее количество покупателей из таблицы customers. Назовите колонку customers_count
select count (distinct customer_id ) as customers_count 
from customers c 

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
order by  EXTRACT(ISODOW FROM s.sale_date),seller  ASC
