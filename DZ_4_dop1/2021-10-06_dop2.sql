--3. ¬ыберите информацию по клиентам, которые перевели компании п€ть максимальных платежей 
--из Sales.CustomerTransactions. 
--ѕредставьте несколько способов (в том числе с CTE). 
-- доработано
WITH MAX_transaction_1 AS (
SELECT 
  A.CustomerTransactionID 
 ,B.CustomerName
FROM Sales.CustomerTransactions AS A
JOIN Sales.Customers AS B ON A.CustomerID = B.CustomerID
)
SELECT 
 TOP(5)
 A.CustomerID
 ,MAX_transaction_1.CustomerName
 ,max(A.TransactionAmount) AS MAX_TransactionAmount
FROM Sales.CustomerTransactions AS A
JOIN MAX_transaction_1 ON A.CustomerTransactionID = MAX_transaction_1.CustomerTransactionID
GROUP BY A.CustomerID, MAX_transaction_1.CustomerName
ORDER BY MAX_TransactionAmount DESC

/*
4. ¬ыберите города (ид и название), в которые были доставлены товары, 
вход€щие в тройку самых дорогих товаров, а также им€ сотрудника, 
который осуществл€л упаковку заказов (PackedByPersonID).
*/
-- доработано
WITH SITY AS
(SELECT DISTINCT 
 D.DeliveryCityID AS ID
,F.CityName
,B.StockItemID
--,J.FullName

FROM Purchasing.Suppliers AS D
JOIN
(SELECT TOP(3) 
 A.StockItemName, A.SupplierID, A.UnitPrice, A.StockItemID
FROM Warehouse.StockItems AS A
ORDER BY UnitPrice DESC) AS B
ON D.SupplierID = B.SupplierID
JOIN Application.Cities AS F
ON D.DeliveryCityID = F.CityID)

SELECT DISTINCT
SITY.ID, SITY.CityName, SITY.StockItemID, J.FullName
FROM SITY
JOIN Sales.InvoiceLines AS G
ON G.StockItemID = SITY.StockItemID
JOIN Sales.Invoices AS H
ON H.InvoiceID = G.InvoiceID
JOIN Application.People J
ON J.PersonID = H.PackedByPersonID
ORDER BY ID