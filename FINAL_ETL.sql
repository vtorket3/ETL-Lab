--select *
--from TechStore.dbo.OrderItems
--inner join TechStore.dbo.Orders on OrderItems.OrderID = Orders.OrderID
--inner join TechStore_DWH.dbo.DimCustomer on Orders.CustomerID = DimCustomer.CustomerID
--inner join TechStore_DWH.dbo.DimProduct on OrderItems.ProductID = DimProduct.ProductID
--inner join TechStore_DWH.dbo.DimDate on Orders.OrderDate = DimDate.FullDate
--insert into FactSales (OrderID, DateKey, CustomerKey, ProductKey, Quantity, Price, Amount)
--select 
--TechStore.dbo.OrderItems.OrderID,
--TechStore_DWH.dbo.DimDate.DateKey,
--TechStore_DWH.dbo.DimCustomer.CustomerKey,
--TechStore_DWH.dbo.DimProduct.ProductKey,
--TechStore.dbo.OrderItems.Quantity,
--TechStore.dbo.OrderItems.Price,
--(TechStore.dbo.OrderItems.Quantity * TechStore.dbo.OrderItems.Price) as Amount

--from TechStore.dbo.OrderItems
--inner join TechStore.dbo.Orders on OrderItems.OrderID = Orders.OrderID
--inner join TechStore_DWH.dbo.DimCustomer on Orders.CustomerID = DimCustomer.CustomerID
--inner join TechStore_DWH.dbo.DimProduct on OrderItems.ProductID = DimProduct.ProductID
--inner join TechStore_DWH.dbo.DimDate on Orders.OrderDate = DimDate.FullDate

select COUNT(*) as total_rows
from DimCustomer
select COUNT(*) as total_rows
from DimProduct
select COUNT(*) as total_rows
from DimDate
