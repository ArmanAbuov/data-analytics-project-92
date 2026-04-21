--  запрос, который считает общее количество покупателей из таблицы customers.
SELECT count(DISTINCT customer_id) AS customers_count
FROM customers;
-- 5 ШАГ И ТРИ ОТЧЕТА--
/*Первый отчет о десятке лучших продавцов.
 * Таблица состоит из трех колонок - данных о продавце,
 * суммарной выручке с проданных товаров и количестве проведенных сделок,
 */
SELECT
    e.first_name || ' ' || e.last_name AS seller,
    count(s.sales_id) AS operations,
    floor(sum(s.quantity * p.price)) AS income
FROM sales AS s
LEFT JOIN products AS p ON s.product_id = p.product_id
LEFT JOIN employees AS e ON s.sales_person_id = e.employee_id
GROUP BY seller
ORDER BY income DESC
LIMIT 10;
/*Второй отчет  о продавцах, чья средняя выручка за сделку
 * меньше средней выручки за сделку по всем продавцам
 */
SELECT
    seller,
    average_income
FROM (
    SELECT
        concat(e.first_name, ' ', e.last_name) AS seller,
        floor(avg(s.quantity * p.price)) AS average_income,
        -- Считаем среднее по всем продажам вообще (оконная функция)
        avg(avg(s.quantity * p.price)) OVER () AS global_avg_income
    FROM sales AS s
    INNER JOIN products AS p ON s.product_id = p.product_id
    INNER JOIN employees AS e ON s.sales_person_id = e.employee_id
    GROUP BY e.employee_id, e.first_name, e.last_name
) AS sub
WHERE average_income < global_avg_income
ORDER BY average_income ASC;
/*Третий отчет  информацию о выручке по дням недели.
 *Каждая запись содержит имя и фамилию продавца,день недели и суммарную выручку
 */
SELECT
    concat(e.first_name, ' ', e.last_name) AS seller,
    to_char(s.sale_date, 'fmday') AS day_of_week,
    floor(sum(s.quantity * p.price)) AS income
FROM sales AS s
LEFT JOIN products AS p ON s.product_id = p.product_id
LEFT JOIN employees AS e ON s.sales_person_id = e.employee_id
GROUP BY seller, day_of_week, extract(ISODOW FROM s.sale_date)
ORDER BY extract(ISODOW FROM s.sale_date), seller ASC;
-- 6 ШАГ И ТРИ ОТЧЕТА--
/*Первый отчет - количество покупателей в разных возрастных группах:
 *  16-25, 26-40 и 40+.отсортировать по возрастным группам
 */
SELECT
    CASE
        WHEN c.age BETWEEN 16 AND 25 THEN '16-25'
        WHEN c.age BETWEEN 26 AND 40 THEN '26-40'
        ELSE '40+'
    END AS age_category,
    count(DISTINCT c.customer_id) AS age_count
FROM customers AS c
GROUP BY age_category
ORDER BY age_category;
/*Во втором отчете предоставьте данные по количеству
 * уникальных покупателей и выручке,которую они принесли.
 *  Сгруппируйте данные по дате, которая представлена в числовом виде ГОД-МЕСЯЦ.
 */
SELECT
    to_char(s.sale_date, 'YYYY-MM') AS selling_month,
    count(DISTINCT s.customer_id) AS total_customers,
    floor(sum(s.quantity * p.price)) AS income
FROM sales AS s
LEFT JOIN products AS p ON s.product_id = p.product_id
GROUP BY selling_month;

/*Третий отчет следует составить о покупателях,
 * первая покупка которых была в ходе проведения акций
 * (акционные товары отпускали со стоимостью равной 0).
 *  Итоговая таблица должна быть отсортирована по id покупателя.
 */
WITH ranked_sales AS (
    SELECT
        s.sale_date,
        p.price,
        concat(c.first_name, ' ', c.last_name) AS customer,
        concat(e.first_name, ' ', e.last_name) AS seller,
        row_number()
            OVER (PARTITION BY s.customer_id ORDER BY s.sale_date) AS rn
    FROM sales AS s
    LEFT JOIN employees AS e ON s.sales_person_id = e.employee_id
    LEFT JOIN customers AS c ON s.customer_id = c.customer_id
    LEFT JOIN products AS p ON s.product_id = p.product_id
    ORDER BY c.customer_id
)

SELECT
    customer,
    sale_date,
    seller
FROM ranked_sales
WHERE rn = 1 AND price = 0;
