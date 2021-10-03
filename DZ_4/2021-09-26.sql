/*
Домашнее задание по курсу MS SQL Server Developer в OTUS.

Занятие "03 - Подзапросы, CTE, временные таблицы".

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
-- Для всех заданий, где возможно, сделайте два варианта запросов:
--  1) через вложенный запрос
--  2) через WITH (для производных таблиц)
-- ---------------------------------------------------------------------------

USE WideWorldImporters

/*
1. Выберите сотрудников (Application.People), которые являются продажниками (IsSalesPerson), 
и не сделали ни одной продажи 04 июля 2015 года. 
Вывести ИД сотрудника и его полное имя. 
Продажи смотреть в таблице Sales.Invoices.
*/
-- 1 вариант
SELECT DISTINCT
  A.PersonID
 ,A.FullName
 
FROM Application.People AS A
LEFT JOIN Sales.Invoices AS B ON B.SalespersonPersonID = A.PersonID  AND B.InvoiceDate = '2015-07-04'
WHERE  B.SalespersonPersonID is NULL
AND A.IsSalesperson = 1

--2 вариант
SELECT DISTINCT
  A.PersonID
 ,A.FullName
FROM Application.People AS A
LEFT JOIN
(SELECT DISTINCT
B.SalespersonPersonID
FROM Sales.Invoices AS B
WHERE B.InvoiceDate = '2015-07-04') AS F
ON A.PersonID = F.SalespersonPersonID
WHERE A.IsSalesperson = 1 AND F.SalespersonPersonID is NULL


/*
2. Выберите товары с минимальной ценой (подзапросом). Сделайте два варианта подзапроса. 
Вывести: ИД товара, наименование товара, цена.
*/

SELECT 
  A.StockItemID -- ИД товара
 ,A.StockItemName -- наименование товара
 ,min(A.UnitPrice) AS minPrice -- цена товара

FROM [WideWorldImporters].[Warehouse].[StockItems] AS A
GROUP BY
 A.StockItemID 
,A.StockItemName 
ORDER BY A.StockItemID

SELECT
  A.StockItemID -- ИД товара
 ,A.StockItemName -- наименование товара
 ,A.UnitPrice
 ,(SELECT 
  min(UnitPrice) AS minPrice
FROM [WideWorldImporters].[Warehouse].[StockItems]) AS minPrice
FROM [WideWorldImporters].[Warehouse].[StockItems] AS A
ORDER BY A.StockItemID

/*
3. Выберите информацию по клиентам, которые перевели компании пять максимальных платежей 
из Sales.CustomerTransactions. 
Представьте несколько способов (в том числе с CTE). 
*/
SELECT 
 TOP(5)
 A.CustomerID
 ,max(A.TransactionAmount) AS MAX_TransactionAmount
FROM Sales.CustomerTransactions AS A
GROUP BY A.CustomerID
ORDER BY MAX_TransactionAmount DESC

WITH MAX_transaction AS (
SELECT 
 A.CustomerTransactionID
,max(A.TransactionAmount) as MAX
FROM Sales.CustomerTransactions AS A
GROUP BY A.CustomerTransactionID
)
SELECT TOP(5)
 A.CustomerID
,max(B.MAX) AS MAX
FROM Sales.CustomerTransactions AS A
JOIN MAX_transaction AS B ON A.CustomerTransactionID = B.CustomerTransactionID
GROUP BY A.CustomerID
ORDER BY MAX DESC

/*
4. Выберите города (ид и название), в которые были доставлены товары, 
входящие в тройку самых дорогих товаров, а также имя сотрудника, 
который осуществлял упаковку заказов (PackedByPersonID).
*/
SELECT DISTINCT 
 D.DeliveryCityID AS ID
,F.CityName
,G.PackedByPersonID
FROM [WideWorldImporters].[Purchasing].[Suppliers] AS D
JOIN
(SELECT TOP(3) 
 A.StockItemName, A.SupplierID, A.UnitPrice
FROM [WideWorldImporters].[Warehouse].[StockItems] AS A
ORDER BY UnitPrice DESC) AS B
ON D.SupplierID = B.SupplierID
JOIN [WideWorldImporters].[Application].[Cities] AS F
ON D.DeliveryCityID = F.CityID
LEFT JOIN [WideWorldImporters].[Sales].[Invoices] AS G
ON D.PrimaryContactPersonID = G.ContactPersonID

-- ---------------------------------------------------------------------------
-- Опциональное задание
-- ---------------------------------------------------------------------------
-- Можно двигаться как в сторону улучшения читабельности запроса, 
-- так и в сторону упрощения плана\ускорения. 
-- Сравнить производительность запросов можно через SET STATISTICS IO, TIME ON. 
-- Если знакомы с планами запросов, то используйте их (тогда к решению также приложите планы). 
-- Напишите ваши рассуждения по поводу оптимизации. 

-- 5. Объясните, что делает и оптимизируйте запрос

SELECT 
	Invoices.InvoiceID, 
	Invoices.InvoiceDate,
	(SELECT People.FullName
		FROM Application.People
		WHERE People.PersonID = Invoices.SalespersonPersonID
	) AS SalesPersonName,
	SalesTotals.TotalSumm AS TotalSummByInvoice, 
	(SELECT SUM(OrderLines.PickedQuantity*OrderLines.UnitPrice)
		FROM Sales.OrderLines
		WHERE OrderLines.OrderId = (SELECT Orders.OrderId 
			FROM Sales.Orders
			WHERE Orders.PickingCompletedWhen IS NOT NULL	
				AND Orders.OrderId = Invoices.OrderId)	
	) AS TotalSummForPickedItems
FROM Sales.Invoices 
	JOIN
	(SELECT InvoiceId, SUM(Quantity*UnitPrice) AS TotalSumm
	FROM Sales.InvoiceLines
	GROUP BY InvoiceId
	HAVING SUM(Quantity*UnitPrice) > 27000) AS SalesTotals
		ON Invoices.InvoiceID = SalesTotals.InvoiceID
ORDER BY TotalSumm DESC

-- --
-- Запрос выбирает ID продажи; дату продаж; ФИО сотрудника, продавшего товары; общую сумму продаж по сотруднику; 
-- общую сумму проданных товаров по сотруднику. В запросе выводятся суммы > 27000 руб. (кол-во проданных товаров, умноженных на цену)
-- Весь запрос построен на вложенных запросах.
WITH SalesTotals AS (
(SELECT InvoiceId, SUM(Quantity*UnitPrice) AS TotalSumm
	FROM Sales.InvoiceLines
	GROUP BY InvoiceId
	HAVING SUM(Quantity*UnitPrice) > 27000)
),
    TotalSummForPickedItems AS (
SELECT Orders.OrderID, SUM(OrderLines.PickedQuantity*OrderLines.UnitPrice) AS SUM
		FROM Sales.OrderLines
		JOIN Sales.Orders ON Orders.OrderID = OrderLines.OrderID
		WHERE Orders.PickingCompletedWhen IS NOT NULL
		GROUP BY Orders.OrderID			
)

SELECT 
	A.InvoiceID, 
	A.InvoiceDate,
	B.FullName AS SalesPersonName,
	SalesTotals.TotalSumm AS TotalSummByInvoice,
	TotalSummForPickedItems.SUM AS TotalSummForPickedItems
	
FROM
	Sales.Invoices AS A
JOIN Application.People AS B
ON A.SalespersonPersonID = B.PersonID
JOIN SalesTotals ON SalesTotals.InvoiceID = A.InvoiceID
JOIN TotalSummForPickedItems ON TotalSummForPickedItems.OrderID = A.OrderID
ORDER BY TotalSummByInvoice DESC
-- мой запрос отработал немного дольше, но считаю, читабельность запроса выросла (скрин планов выполнения приложен)
