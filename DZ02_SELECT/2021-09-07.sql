/*
Домашнее задание по курсу MS SQL Server Developer в OTUS.
Занятие "02 - Оператор SELECT и простые фильтры, GROUP BY, HAVING".

Задания выполняются с использованием базы данных WideWorldImporters.

Бэкап БД можно скачать отсюда:
https://github.com/Microsoft/sql-server-samples/releases/tag/wide-world-importers-v1.0
Нужен WideWorldImporters-Full.bak

Описание WideWorldImporters от Microsoft:
* https://docs.microsoft.com/ru-ru/sql/samples/wide-world-importers-what-is
* https://docs.microsoft.com/ru-ru/sql/samples/wide-world-importers-oltp-database-catalog
*/

-- ---------------------------------------------------------------------------
-- Задание - написать выборки для получения указанных ниже данных.
-- ---------------------------------------------------------------------------

USE WideWorldImporters

/*
1. Все товары, в названии которых есть "urgent" или название начинается с "Animal".
Вывести: ИД товара (StockItemID), наименование товара (StockItemName).
Таблицы: Warehouse.StockItems.
*/

SELECT 
  A.StockItemID,
  A.StockItemName
  
FROM WideWorldImporters.Warehouse.StockItems AS A
WHERE A.StockItemName like '%urgent%' OR LEFT(A.StockItemName, 6) = 'Animal'


/*
2. Поставщиков (Suppliers), у которых не было сделано ни одного заказа (PurchaseOrders).
Сделать через JOIN, с подзапросом задание принято не будет.
Вывести: ИД поставщика (SupplierID), наименование поставщика (SupplierName).
Таблицы: Purchasing.Suppliers, Purchasing.PurchaseOrders.
По каким колонкам делать JOIN подумайте самостоятельно.
*/

SELECT 
  A.SupplierID,
  A.SupplierName

FROM [WideWorldImporters].[Purchasing].[Suppliers] AS A
LEFT JOIN [WideWorldImporters].Purchasing.PurchaseOrders AS B
ON A.SupplierID = B.SupplierID
WHERE B.SupplierID is NULL

/*
3. Заказы (Orders) с ценой товара (UnitPrice) более 100$ 
либо количеством единиц (Quantity) товара более 20 штук
и присутствующей датой комплектации всего заказа (PickingCompletedWhen).
Вывести:
* OrderID
* дату заказа (OrderDate) в формате ДД.ММ.ГГГГ
* название месяца, в котором был сделан заказ
* номер квартала, в котором был сделан заказ
* треть года, к которой относится дата заказа (каждая треть по 4 месяца)
* имя заказчика (Customer)
Добавьте вариант этого запроса с постраничной выборкой,
пропустив первую 1000 и отобразив следующие 100 записей.

Сортировка должна быть по номеру квартала, трети года, дате заказа (везде по возрастанию).

Таблицы: Sales.Orders, Sales.OrderLines, Sales.Customers.
*/

SELECT
  A.OrderID,
  CONVERT(nvarchar(16), A.OrderDate, 104) AS Дата_заказа,
  DATENAME(month, A.OrderDate) AS Месяц_заказа,
  DATEPART(q, A.OrderDate) AS Номер_квартала,
    CASE 
	  WHEN DATEPART(m, A.OrderDate) <= 4 THEN 1
	  WHEN DATEPART(m, A.OrderDate) BETWEEN 5 AND 8 THEN 2
	  ELSE 3
    END AS Треть_года,
  B.CustomerName
FROM [WideWorldImporters].[Sales].[Orders] AS A
JOIN [WideWorldImporters].[Sales].[Customers] AS B
ON A.CustomerID = B.CustomerID
JOIN [WideWorldImporters].[Sales].[OrderLines] AS C
ON A.OrderID = C.OrderID

WHERE (C.UnitPrice > 100 OR C.Quantity > 20) AND C.PickingCompletedWhen is not NULL
ORDER BY Номер_квартала, Треть_года, Дата_заказа

SELECT
  A.OrderID,
  CONVERT(nvarchar(16), A.OrderDate, 104) AS Дата_заказа,
  DATENAME(month, A.OrderDate) AS Месяц_заказа,
  DATEPART(q, A.OrderDate) AS Номер_квартала,
    CASE 
	  WHEN DATEPART(m, A.OrderDate) <= 4 THEN 1
	  WHEN DATEPART(m, A.OrderDate) BETWEEN 5 AND 8 THEN 2
	  ELSE 3
    END AS Треть_года,
  B.CustomerName
FROM [WideWorldImporters].[Sales].[Orders] AS A
JOIN [WideWorldImporters].[Sales].[Customers] AS B
ON A.CustomerID = B.CustomerID
JOIN [WideWorldImporters].[Sales].[OrderLines] AS C
ON A.OrderID = C.OrderID

WHERE (C.UnitPrice > 100 OR C.Quantity > 20) AND C.PickingCompletedWhen is not NULL
ORDER BY Номер_квартала, Треть_года, Дата_заказа
OFFSET 1000 ROWS FETCH NEXT 100 ROWS ONLY;
GO
/*
4. Заказы поставщикам (Purchasing.Suppliers),
которые должны быть исполнены (ExpectedDeliveryDate) в январе 2013 года
с доставкой "Air Freight" или "Refrigerated Air Freight" (DeliveryMethodName)
и которые исполнены (IsOrderFinalized).
Вывести:
* способ доставки (DeliveryMethodName)
* дата доставки (ExpectedDeliveryDate)
* имя поставщика
* имя контактного лица принимавшего заказ (ContactPerson)

Таблицы: Purchasing.Suppliers, Purchasing.PurchaseOrders, Application.DeliveryMethods, Application.People.
*/
USE WideWorldImporters
SELECT 
  C.DeliveryMethodName,
  B.ExpectedDeliveryDate,
  A.SupplierName,
  D.FullName

FROM Purchasing.Suppliers AS A
JOIN Purchasing.PurchaseOrders AS B
ON A.SupplierID = B.SupplierID
JOIN Application.DeliveryMethods AS C
ON C.DeliveryMethodID = B.DeliveryMethodID
JOIN Application.People AS D
ON D.PersonID = B.ContactPersonID

WHERE B.ExpectedDeliveryDate BETWEEN '2013-01-01' AND '2013-01-31'
AND C.DeliveryMethodName in ('Air Freight', 'Refrigerated Air Freight')
AND B.IsOrderFinalized = 1

/*
5. Десять последних продаж (по дате продажи) с именем клиента и именем сотрудника,
который оформил заказ (SalespersonPerson).
Сделать без подзапросов.
*/

SELECT TOP(10)
B.CustomerName -- имя покупателя
,D.FullName -- Имя сотрудника, который оформил заказ
,A.TransactionDate
FROM [WideWorldImporters].[Sales].[CustomerTransactions] AS A
JOIN [WideWorldImporters].[Sales].[Customers] AS B
ON A.CustomerID = B.CustomerID
JOIN [WideWorldImporters].[Sales].[Orders] AS C
ON A.CustomerID = C.CustomerID
JOIN [WideWorldImporters].[Application].[People] AS D
ON D.PersonID = C.SalespersonPersonID
ORDER BY A.TransactionDate DESC

/*
6. Все ид и имена клиентов и их контактные телефоны,
которые покупали товар "Chocolate frogs 250g".
Имя товара смотреть в таблице Warehouse.StockItems.
*/

SELECT
 A.CustomerID
,A.CustomerName
,A.PhoneNumber
FROM [WideWorldImporters].[Sales].[Customers] AS A
JOIN [WideWorldImporters].[Warehouse].[StockItemTransactions] AS B
ON B.CustomerID = A.CustomerID
JOIN [WideWorldImporters].[Warehouse].[StockItems] AS C
ON C.StockItemID = B.StockItemID AND C.StockItemName = 'Chocolate frogs 250g'

/*
7. Посчитать среднюю цену товара, общую сумму продажи по месяцам
Вывести:
* Год продажи (например, 2015)
* Месяц продажи (например, 4)
* Средняя цена за месяц по всем товарам
* Общая сумма продаж за месяц

Продажи смотреть в таблице Sales.Invoices и связанных таблицах.
*/
--1 вариант:
-- средняя цена за месяц
SELECT 
YEAR(B.TransactionDate) AS YEAR
,MONTH(B.TransactionDate) AS MONTH
,AVG(A.UnitPrice) AS AVG_UnitPrice
FROM [WideWorldImporters].[Sales].[InvoiceLines] AS A
JOIN [WideWorldImporters].[Sales].[CustomerTransactions] AS B
ON A.InvoiceID = B.InvoiceID
WHERE B.InvoiceID is not NULL
GROUP BY ROLLUP(year(B.TransactionDate), month(B.TransactionDate))
ORDER BY year(B.TransactionDate), month(B.TransactionDate)
-- общая сумма продаж
SELECT 
YEAR(TransactionDate) AS YEAR
,MONTH(TransactionDate) AS MONTH
,SUM(TransactionAmount) AS SUM_TransactionAmount
FROM [WideWorldImporters].[Sales].[CustomerTransactions] 
GROUP BY ROLLUP(year(TransactionDate), month(TransactionDate))

-- 2 вариант
SELECT 
YEAR(B.TransactionDate) AS YEAR
,MONTH(B.TransactionDate) AS MONTH
,AVG(A.UnitPrice) AS AVG_UnitPrice
,SUM(TransactionAmount) AS SUM_TransactionAmount
FROM [WideWorldImporters].[Sales].[InvoiceLines] AS A
JOIN [WideWorldImporters].[Sales].[CustomerTransactions] AS B
ON A.InvoiceID = B.InvoiceID
WHERE B.InvoiceID is not NULL
GROUP BY ROLLUP(year(B.TransactionDate), month(B.TransactionDate))
ORDER BY year(B.TransactionDate), month(B.TransactionDate)
/*
8. Отобразить все месяцы, где общая сумма продаж превысила 10 000

Вывести:
* Год продажи (например, 2015)
* Месяц продажи (например, 4)
* Общая сумма продаж

Продажи смотреть в таблице Sales.Invoices и связанных таблицах.
*/

SELECT 
YEAR(TransactionDate) AS YEAR
,MONTH(TransactionDate) AS MONTH
,SUM(TransactionAmount) AS SUM_TransactionAmount
FROM [WideWorldImporters].[Sales].[CustomerTransactions]
GROUP BY ROLLUP(year(TransactionDate), month(TransactionDate))
Having SUM(TransactionAmount) > 10000

/*
9. Вывести сумму продаж, дату первой продажи
и количество проданного по месяцам, по товарам,
продажи которых менее 50 ед в месяц.
Группировка должна быть по году,  месяцу, товару.

Вывести:
* Год продажи
* Месяц продажи
* Наименование товара
* Сумма продаж
* Дата первой продажи
* Количество проданного

Продажи смотреть в таблице Sales.Invoices и связанных таблицах.
*/

SELECT 
YEAR(B.TransactionDate) AS YEAR
,MONTH(B.TransactionDate) AS MONTH
,A.Description
,SUM(B.TransactionAmount) AS SUM_TransactionAmount
,MIN(B.TransactionDate) AS MIN_TransactionDate
,SUM(A.Quantity) AS Quantity_количество

FROM [WideWorldImporters].[Sales].[InvoiceLines] AS A
JOIN [WideWorldImporters].[Sales].[CustomerTransactions] AS B
ON A.InvoiceID = B.InvoiceID
WHERE B.InvoiceID is not NULL
GROUP BY ROLLUP(YEAR(B.TransactionDate),MONTH(B.TransactionDate),A.Description)
having SUM(A.Quantity) < 50


-- ---------------------------------------------------------------------------
-- Опционально
-- ---------------------------------------------------------------------------
/*
Написать запросы 8-9 так, чтобы если в каком-то месяце не было продаж,
то этот месяц также отображался бы в результатах, но там были нули.
*/
