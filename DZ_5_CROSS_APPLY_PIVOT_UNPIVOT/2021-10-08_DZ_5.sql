/*
Домашнее задание по курсу MS SQL Server Developer в OTUS.

Занятие "05 - Операторы CROSS APPLY, PIVOT, UNPIVOT".

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
1. Требуется написать запрос, который в результате своего выполнения 
формирует сводку по количеству покупок в разрезе клиентов и месяцев.
В строках должны быть месяцы (дата начала месяца), в столбцах - клиенты.

Клиентов взять с ID 2-6, это все подразделение Tailspin Toys.
Имя клиента нужно поменять так чтобы осталось только уточнение.
Например, исходное значение "Tailspin Toys (Gasport, NY)" - вы выводите только "Gasport, NY".
Дата должна иметь формат dd.mm.yyyy, например, 25.12.2019.

Пример, как должны выглядеть результаты:
-------------+--------------------+--------------------+-------------+--------------+------------
InvoiceMonth | Peeples Valley, AZ | Medicine Lodge, KS | Gasport, NY | Sylvanite, MT | Jessie, ND
-------------+--------------------+--------------------+-------------+--------------+------------
01.01.2013   |      3             |        1           |      4      |      2        |     2
01.02.2013   |      7             |        3           |      4      |      2        |     1
-------------+--------------------+--------------------+-------------+--------------+------------
*/
SELECT PVT.Date AS InvoiceMonth,
       PVT.[Tailspin Toys (Peeples Valley, AZ)] AS [Peeples Valley, AZ],
       PVT.[Tailspin Toys (Medicine Lodge, KS)] AS [Medicine Lodge, KS],
	   PVT.[Tailspin Toys (Gasport, NY)] AS [Gasport, NY],
	   PVT.[Tailspin Toys (Sylvanite, MT)] AS [Sylvanite, MT],
	   PVT.[Tailspin Toys (Jessie, ND)] AS [Jessie, ND]
FROM
(SELECT A.CustomerName,
	    CONVERT(nvarchar, datefromparts(year(B.InvoiceDate), month(B.InvoiceDate), 1), 104) AS Date,
		B.InvoiceID
FROM Sales.Customers AS A
JOIN Sales.Invoices AS B ON A.CustomerID = B.CustomerID
WHERE A.CustomerID BETWEEN 2 AND 6) AS C
PIVOT(COUNT(C.InvoiceID)
FOR CustomerName in ([Tailspin Toys (Sylvanite, MT)], [Tailspin Toys (Peeples Valley, AZ)], [Tailspin Toys (Medicine Lodge, KS)], 
[Tailspin Toys (Gasport, NY)], [Tailspin Toys (Jessie, ND)])) AS PVT

/*
2. Для всех клиентов с именем, в котором есть "Tailspin Toys"
вывести все адреса, которые есть в таблице, в одной колонке.

Пример результата:
----------------------------+--------------------
CustomerName                | AddressLine
----------------------------+--------------------
Tailspin Toys (Head Office) | Shop 38
Tailspin Toys (Head Office) | 1877 Mittal Road
Tailspin Toys (Head Office) | PO Box 8975
Tailspin Toys (Head Office) | Ribeiroville
----------------------------+--------------------
*/

SELECT unpvt.CustomerName,
       unpvt.AddressLine
FROM
(SELECT A.CustomerName,
       A.DeliveryAddressLine1,
       A.DeliveryAddressLine2,
	   A.PostalAddressLine1,
	   A.PostalAddressLine2

FROM Sales.Customers AS A
WHERE A.CustomerName like 'Tailspin Toys%') AS adres
UNPIVOT (AddressLine
FOR ADDRESS in (DeliveryAddressLine1, DeliveryAddressLine2, PostalAddressLine1, PostalAddressLine2)) AS unpvt;

/*
3. В таблице стран (Application.Countries) есть поля с цифровым кодом страны и с буквенным.
Сделайте выборку ИД страны, названия и ее кода так, 
чтобы в поле с кодом был либо цифровой либо буквенный код.

Пример результата:
--------------------------------
CountryId | CountryName | Code
----------+-------------+-------
1         | Afghanistan | AFG
1         | Afghanistan | 4
3         | Albania     | ALB
3         | Albania     | 8
----------+-------------+-------
*/

SELECT unpvt1.CountryID, unpvt1.CountryName, unpvt1.Code
FROM
(SELECT A.CountryID, A.CountryName, CAST(A.IsoAlpha3Code AS nvarchar) AS IsoAlpha3Code, CAST(A.IsoNumericCode AS nvarchar) AS IsoNumericCode
FROM Application.Countries AS A) AS Code
UNPIVOT (Code
FOR code_1 in (IsoAlpha3Code, IsoNumericCode)) AS unpvt1

/*
4. Выберите по каждому клиенту два самых дорогих товара, которые он покупал.
В результатах должно быть ид клиета, его название, ид товара, цена, дата покупки.
*/

SELECT F.CustomerID, F.CustomerName, G.OrderID, G.UnitPrice, G.OrderDate
FROM Sales.Customers AS F
CROSS AppLy
(SELECT TOP(2)
B.OrderID, C.UnitPrice, B.OrderDate
FROM Sales.Orders AS B
JOIN Sales.OrderLines AS C
ON C.OrderID = B.OrderID
WHERE B.CustomerID = F.CustomerID
ORDER BY C.UnitPrice DESC) AS G
ORDER BY F.CustomerName