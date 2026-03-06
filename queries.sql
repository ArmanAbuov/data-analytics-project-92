--  запрос, который считает общее количество покупателей из таблицы customers.
-- Назовите колонку customers_count
SELECT count(DISTINCT customer_id) AS customers_count
FROM customers
-- 5 ШАГ И ТРИ ОТЧЕТА--
/*Первый отчет о десятке лучших продавцов.
 * Таблица состоит из трех колонок - данных о продавце,
 * суммарной выручке с проданных товаров и количестве проведенных сделок,
 * и отсортирована по убыванию выручки
 */
-- в consts определяем переменную top - нужно 10 лучших
WITH consts AS (
SELECT 10 AS top
)

SELECT
    CONCAT(e.first_name, ' ', e.last_name) AS seller,
    COUNT(s.sales_id) AS operations,
    FLOOR(SUM(s.quantity * p.price)) AS income
FROM sales AS s
LEFT JOIN products AS p ON s.product_id = p.product_id
LEFT JOIN employees AS e ON s.sales_person_id = e.employee_id
GROUP BY seller
ORDER BY income DESC
LIMIT (SELECT top FROM consts)

/*Второй отчет  о продавцах, чья средняя выручка за сделку 
 * меньше средней выручки за сделку по всем продавцам
 *Таблица отсортирована по выручке по возрастанию.
 */
WITH AVG_ALL AS (
    SELECT AVG(S.QUANTITY * P.PRICE) AS AVERAGE_ALL
    FROM SALES AS S
    LEFT JOIN PRODUCTS AS P ON S.PRODUCT_ID = P.PRODUCT_ID
)

SELECT
    CONCAT(E.FIRST_NAME, ' ', E.LAST_NAME) AS SELLER,
    FLOOR(AVG(S.QUANTITY * P.PRICE)) AS AVERAGE_INCOME
FROM SALES AS S
LEFT JOIN PRODUCTS AS P ON S.PRODUCT_ID = P.PRODUCT_ID
LEFT JOIN EMPLOYEES AS E ON S.SALES_PERSON_ID = E.EMPLOYEE_ID
GROUP BY SELLER
HAVING AVG(S.QUANTITY * P.PRICE) < (SELECT AVERAGE_ALL FROM AVG_ALL)
ORDER BY AVERAGE_INCOME ASC

/*Третий отчет  информацию о выручке по дням недели.
 *Каждая запись содержит имя и фамилию продавца, день недели и суммарную выручку.
 *Отсортируйте данные по порядковому номеру дня недели и seller
 */
SELECT
	CONCAT(e.first_name , ' ', e.last_name) AS seller,
	to_char(s.sale_date , 'fmday') AS day_of_week,
	FLOOR(SUM(s.quantity *p.price )) AS income
FROM sales s
LEFT JOIN products p ON s.product_id = p.product_id 
LEFT JOIN employees e ON s.sales_person_id = e.employee_id 
GROUP BY seller,day_of_week,EXTRACT(ISODOW FROM s.sale_date)
ORDER BY  EXTRACT(ISODOW FROM s.sale_date),seller  ASC

-- 6 ШАГ И ТРИ ОТЧЕТА--
/*Первый отчет - количество покупателей в разных возрастных группах:
 *  16-25, 26-40 и 40+.
 * Итоговая таблица должна быть отсортирована по возрастным группам
 */
SELECT
    CASE
        WHEN c.age BETWEEN 16 AND 25 THEN '16-25'
        WHEN c.age BETWEEN 26 AND 40 THEN '26-40'
        ELSE '40+'
    END AS age_category,
    COUNT(DISTINCT c.customer_id) AS age_count
FROM customers AS c
GROUP BY age_category
ORDER BY age_category

/*Во втором отчете предоставьте данные по количеству 
 * уникальных покупателей и выручке,которую они принесли.
 *  Сгруппируйте данные по дате, которая представлена в числовом виде ГОД-МЕСЯЦ.
 *  Итоговая таблица должна быть отсортирована по дате по возрастанию
 */
SELECT
    to_char(s.sale_date, 'YYYY-MM') AS selling_month,
    count(DISTINCT s.customer_id) AS total_customers,
    floor(sum(s.quantity * p.price)) AS income
FROM sales AS s
LEFT JOIN products AS p ON s.product_id = p.product_id
GROUP BY selling_month

/*Третий отчет следует составить о покупателях, 
 * первая покупка которых была в ходе проведения акций 
 * (акционные товары отпускали со стоимостью равной 0).
 *  Итоговая таблица должна быть отсортирована по id покупателя.
 */
WITH FIRST_ROWS AS (
    SELECT
        S.SALE_DATE,
        concat(C.FIRST_NAME, ' ', C.LAST_NAME) AS CUSTOMER,
        concat(E.FIRST_NAME, ' ', E.LAST_NAME) AS SELLER,
        first_value(P.PRICE * S.QUANTITY)
            OVER (PARTITION BY C.CUSTOMER_ID ORDER BY S.SALE_DATE)
            AS FRST_VALUE,
        first_value(S.SALE_DATE)
            OVER (PARTITION BY C.CUSTOMER_ID ORDER BY S.SALE_DATE) AS FRST_DATE
    FROM SALES AS S
    LEFT JOIN EMPLOYEES AS E ON S.SALES_PERSON_ID = E.EMPLOYEE_ID
    LEFT JOIN CUSTOMERS AS C ON S.CUSTOMER_ID = C.CUSTOMER_ID
    LEFT JOIN PRODUCTS AS P ON S.PRODUCT_ID = P.PRODUCT_ID
    ORDER BY C.CUSTOMER_ID
)

SELECT
    CUSTOMER,
    SALE_DATE,
    SELLER
FROM FIRST_ROWS
WHERE FRST_VALUE = 0 AND SALE_DATE = FRST_DATE
GROUP BY CUSTOMER, SALE_DATE, SELLER
