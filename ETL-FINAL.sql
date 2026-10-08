USE TechStore_DWH;
GO
-- Чтобы почистить от возможных дубликатов!!
TRUNCATE TABLE dbo.FactSales;
DELETE FROM dbo.DimCustomer;
DELETE FROM dbo.DimProduct;
DELETE FROM dbo.DimDate;
GO


INSERT INTO dbo.DimCustomer (CustomerID, FirstName, LastName, City)
SELECT 
    CustomerID, 
    FirstName, 
    LastName, 
    City
FROM TechStore.dbo.Customers;
GO



INSERT INTO dbo.DimProduct (ProductID, ProductName, Category)
SELECT 
    ProductID,
    ProductName, 
    Category
FROM TechStore.dbo.Products;
GO


SET IDENTITY_INSERT dbo.DimDate ON; 
GO
INSERT INTO dbo.DimDate (DateKey, FullDate, [Day], [Month], MonthName, Quarter, [Year])
SELECT DISTINCT
    CAST(CONVERT(VARCHAR(8), OrderDate, 112) AS INT) AS DateKey,
    OrderDate AS FullDate,
    DATEPART(DAY, OrderDate) AS [Day],
    DATEPART(MONTH, OrderDate) AS [Month],
    CHOOSE(DATEPART(MONTH, OrderDate), 
        N'Январь', N'Февраль', N'Март', N'Апрель', N'Май', N'Июнь', 
        N'Июль', N'Август', N'Сентябрь', N'Октябрь', N'Ноябрь', N'Декабрь') AS MonthName,
    DATEPART(QUARTER, OrderDate) AS Quarter,
    DATEPART(YEAR, OrderDate) AS [Year]
FROM TechStore.dbo.Orders;
GO
SET IDENTITY_INSERT dbo.DimDate OFF; 
GO


-- Фактические продажи
-- ============================================================================
INSERT INTO dbo.FactSales (OrderID, DateKey, CustomerKey, ProductKey, Quantity, Price, Amount)
SELECT 
    o.OrderID,
    d.DateKey,
    c.CustomerKey,
    p.ProductKey,
    oi.Quantity,
    oi.Price,
    (oi.Quantity * oi.Price) AS Amount -- Рассчитываем сумму на лету
FROM TechStore.dbo.OrderItems oi
INNER JOIN TechStore.dbo.Orders o ON oi.OrderID = o.OrderID
INNER JOIN dbo.DimDate d ON o.OrderDate = d.FullDate
INNER JOIN dbo.DimCustomer c ON o.CustomerID = c.CustomerID
INNER JOIN dbo.DimProduct p ON oi.ProductID = p.ProductID;
GO
-- ============================================================================

--Проверка
-- ============================================================================
SELECT 'DimCustomer' AS TableName, COUNT(*) AS [RowCount] FROM dbo.DimCustomer
UNION ALL SELECT 'DimProduct', COUNT(*) FROM dbo.DimProduct
UNION ALL SELECT 'DimDate', COUNT(*) FROM dbo.DimDate
UNION ALL SELECT 'FactSales', COUNT(*) FROM dbo.FactSales;

SELECT 
    SUM(Quantity) AS TotalUnits, 
    SUM(Amount) AS TotalRevenue 
FROM dbo.FactSales;
GO

-- ============================================================================

-- Задание 1
SELECT 
    p.ProductName AS [Название товара],
    SUM(f.Quantity) AS [Продано единиц],
    SUM(f.Amount) AS [Суммарная выручка]
FROM dbo.FactSales f
INNER JOIN dbo.DimProduct p ON f.ProductKey = p.ProductKey
GROUP BY p.ProductName
ORDER BY [Суммарная выручка] DESC;
GO

-- Задание 2
SELECT 
    p.Category AS [Категория],
    SUM(f.Amount) AS [Общая выручка]
FROM dbo.FactSales f
INNER JOIN dbo.DimProduct p ON f.ProductKey = p.ProductKey
GROUP BY p.Category
ORDER BY [Общая выручка] DESC;
GO

--Задание 3
SELECT 
    c.FirstName AS [Имя],
    c.LastName AS [Фамилия],
    SUM(f.Amount) AS [Сумма покупок]
FROM dbo.FactSales f
INNER JOIN dbo.DimCustomer c ON f.CustomerKey = c.CustomerKey
GROUP BY c.CustomerKey, c.FirstName, c.LastName
ORDER BY [Сумма покупок] DESC;
GO

-- Задание 4
SELECT 
    d.[Year] AS [Год],
    d.[Month] AS [Номер месяца],
    d.MonthName AS [Месяц],
    SUM(f.Amount) AS [Выручка за месяц]
FROM dbo.FactSales f
INNER JOIN dbo.DimDate d ON f.DateKey = d.DateKey
GROUP BY d.[Year], d.[Month], d.MonthName
ORDER BY d.[Year] ASC, d.[Month] ASC;
GO