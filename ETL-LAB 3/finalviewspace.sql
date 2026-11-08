/*
ПРАКТИЧЕСКАЯ РАБОТА №3
TechStore — логическая витрина продаж.

Исходное состояние: корректно завершённая ЛР2.

Перед каждым CREATE VIEW в комментарии зафиксировать:
1) аналитический вопрос;
2) grain — что означает одна строка;
3) используемые measures;
4) используемые dimensions.
*/

USE TechStore_DWH;
GO

/* 
   Шаг 1. Схема mart
 */

-- Создать схему mart, если она отсутствует.

IF NOT EXISTS (SELECT * FROM sys.schemas WHERE name = 'mart')
BEGIN
    EXEC('CREATE SCHEMA mart;');
END
GO


/* 
   Шаг 2. mart.vw_SalesByMonthCategory
   Grain: одна строка = один год + месяц + категория.
 */

CREATE OR ALTER VIEW mart.vw_SalesByMonthCategory
AS
SELECT 
    d.[Year],
    d.Month,
    d.MonthName,
    p.Category,
    COUNT(DISTINCT f.OrderID) AS OrdersCount,
    SUM(f.Quantity) AS UnitsSold,
    SUM(f.Amount) AS Revenue,
    CASE 
        WHEN COUNT(DISTINCT f.OrderID) = 0 THEN 0 
        ELSE SUM(f.Amount) / COUNT(DISTINCT f.OrderID) 
    END AS AvgRevenuePerOrder
FROM dbo.FactSales f
INNER JOIN dbo.DimDate d ON f.DateKey = d.DateKey
INNER JOIN dbo.DimProduct p ON f.ProductKey = p.ProductKey
GROUP BY 
    d.[Year],
    d.Month,
    d.MonthName,
    p.Category;
GO


/* 
   Шаг 3. mart.vw_ProductPerformance
   Grain: одна строка = один товар.
 */

CREATE OR ALTER VIEW mart.vw_ProductPerformance
AS
SELECT 
    p.ProductID,
    p.ProductName,
    p.Category,
    COUNT(DISTINCT f.OrderID) AS OrdersCount,
    SUM(f.Quantity) AS UnitsSold,
    SUM(f.Amount) AS Revenue,
    CASE 
        WHEN SUM(f.Quantity) = 0 THEN 0 
        ELSE SUM(f.Amount) / SUM(f.Quantity) 
    END AS AvgHistoricalUnitPrice
FROM dbo.FactSales f
INNER JOIN dbo.DimProduct p ON f.ProductKey = p.ProductKey
GROUP BY 
    p.ProductID,
    p.ProductName,
    p.Category;
GO

/* 
   Шаг 4. mart.vw_CustomerValue
   Grain: одна строка = один клиент.
 */

CREATE OR ALTER VIEW mart.vw_CustomerValue
AS
SELECT 
    c.CustomerID,
    c.FirstName,
    c.LastName,
    c.City,
    COUNT(DISTINCT f.OrderID) AS OrdersCount,
    SUM(f.Quantity) AS UnitsPurchased,
    SUM(f.Amount) AS TotalSpent,
    CASE 
        WHEN COUNT(DISTINCT f.OrderID) = 0 THEN 0 
        ELSE SUM(f.Amount) / COUNT(DISTINCT f.OrderID) 
    END AS AvgOrderValue
FROM dbo.FactSales f
INNER JOIN dbo.DimCustomer c ON f.CustomerKey = c.CustomerKey
GROUP BY 
    c.CustomerID,
    c.FirstName,
    c.LastName,
    c.City;
GO
/* 
   Шаг 5. mart.vw_SalesByCity
   Grain: одна строка = один город клиента.
 */

CREATE OR ALTER VIEW mart.vw_SalesByCity
AS
SELECT 
    c.City,
    COUNT(DISTINCT f.CustomerKey) AS CustomersCount,
    COUNT(DISTINCT f.OrderID) AS OrdersCount,
    SUM(f.Quantity) AS UnitsSold,
    SUM(f.Amount) AS Revenue,
    CASE 
        WHEN COUNT(DISTINCT f.OrderID) = 0 THEN 0 
        ELSE SUM(f.Amount) / COUNT(DISTINCT f.OrderID) 
    END AS AvgOrderValue
FROM dbo.FactSales f
INNER JOIN dbo.DimCustomer c ON f.CustomerKey = c.CustomerKey
GROUP BY 
    c.City;
GO
/* 
   Шаг 6. Проверка через системный каталог
 */

-- Вывести четыре обязательных VIEW схемы mart через sys.views + sys.schemas.
SELECT 
    s.name AS SchemaName,
    v.name AS ViewName,
    v.create_date AS CreateDate
FROM sys.views v
INNER JOIN sys.schemas s ON v.schema_id = s.schema_id
WHERE s.name = 'mart';

-- Вывести столбцы и типы mart.vw_SalesByMonthCategory через sys.columns + sys.types.

SELECT 
    c.column_id AS ColumnPosition,
    c.name AS ColumnName,
    t.name AS DataType,
    c.max_length AS MaxLengthInBytes,
    c.precision AS [Precision],
    c.scale AS Scale
FROM sys.columns c
INNER JOIN sys.types t ON c.user_type_id = t.user_type_id
WHERE c.object_id = OBJECT_ID('mart.vw_SalesByMonthCategory')
ORDER BY c.column_id;

/* 
   Шаг 7. Аналитика только через mart.*
 */

-- 1. TOP 5 товаров по Revenue.

SELECT TOP 5 
    ProductID, 
    ProductName, 
    Category, 
    Revenue 
FROM mart.vw_ProductPerformance
ORDER BY Revenue DESC;

-- 2. TOP 3 клиентов по TotalSpent.

SELECT TOP 3 
    CustomerID, 
    FirstName, 
    LastName, 
    TotalSpent 
FROM mart.vw_CustomerValue
ORDER BY TotalSpent DESC;

-- 3. Город-лидер по Revenue.

SELECT TOP 1 
    City, 
    Revenue 
FROM mart.vw_SalesByCity
ORDER BY Revenue DESC;


-- 4. Комбинация год + месяц + категория с максимальной Revenue.
SELECT TOP 1 
    [Year], 
    Month, 
    MonthName, 
    Category, 
    Revenue 
FROM mart.vw_SalesByMonthCategory
ORDER BY Revenue DESC;

/* 
   Шаг 8. Итоговые проверки
 */

-- После завершения выполнить 90_final_checks_lab03.sql.

USE TechStore_DWH;
GO

-- 1. Обязательные VIEW.
SELECT
    s.name AS SchemaName,
    v.name AS ViewName
FROM sys.views AS v
JOIN sys.schemas AS s
    ON s.schema_id = v.schema_id
WHERE s.name = N'mart'
  AND v.name IN (
      N'vw_SalesByMonthCategory',
      N'vw_ProductPerformance',
      N'vw_CustomerValue',
      N'vw_SalesByCity'
  )
ORDER BY v.name;
GO

-- 2. Row count и сверка аддитивных итогов.
SELECT
    N'mart.vw_SalesByMonthCategory' AS ObjectName,
    COUNT(*) AS RowCounts,
    SUM(UnitsSold) AS TotalUnits,
    CAST(SUM(Revenue) AS DECIMAL(18,2)) AS TotalRevenue
FROM mart.vw_SalesByMonthCategory
UNION ALL
SELECT
    N'mart.vw_ProductPerformance',
    COUNT(*),
    SUM(UnitsSold),
    CAST(SUM(Revenue) AS DECIMAL(18,2))
FROM mart.vw_ProductPerformance
UNION ALL
SELECT
    N'mart.vw_CustomerValue',
    COUNT(*),
    SUM(UnitsPurchased),
    CAST(SUM(TotalSpent) AS DECIMAL(18,2))
FROM mart.vw_CustomerValue
UNION ALL
SELECT
    N'mart.vw_SalesByCity',
    COUNT(*),
    SUM(UnitsSold),
    CAST(SUM(Revenue) AS DECIMAL(18,2))
FROM mart.vw_SalesByCity;
GO

-- 3. Контрольные лидеры.
WITH BestMonthCategory AS (
    SELECT TOP (1)
        CONCAT([Year], N'-', RIGHT(N'0' + CAST(Month AS NVARCHAR(2)), 2),
               N' / ', Category) AS Leader,
        UnitsSold AS UnitsValue,
        Revenue
    FROM mart.vw_SalesByMonthCategory
    ORDER BY Revenue DESC, [Year], Month, Category
),
BestProduct AS (
    SELECT TOP (1)
        ProductName AS Leader,
        UnitsSold AS UnitsValue,
        Revenue
    FROM mart.vw_ProductPerformance
    ORDER BY Revenue DESC, ProductName
),
BestCustomer AS (
    SELECT TOP (1)
        CONCAT(FirstName, N' ', LastName) AS Leader,
        OrdersCount AS UnitsValue,
        TotalSpent AS Revenue
    FROM mart.vw_CustomerValue
    ORDER BY TotalSpent DESC, LastName, FirstName
),
BestCity AS (
    SELECT TOP (1)
        City AS Leader,
        OrdersCount AS UnitsValue,
        Revenue
    FROM mart.vw_SalesByCity
    ORDER BY Revenue DESC, City
)
SELECT N'MonthCategory' AS CheckName, Leader, UnitsValue, CAST(Revenue AS DECIMAL(18,2)) AS Revenue
FROM BestMonthCategory
UNION ALL
SELECT N'Product', Leader, UnitsValue, CAST(Revenue AS DECIMAL(18,2))
FROM BestProduct
UNION ALL
SELECT N'Customer', Leader, UnitsValue, CAST(Revenue AS DECIMAL(18,2))
FROM BestCustomer
UNION ALL
SELECT N'City', Leader, UnitsValue, CAST(Revenue AS DECIMAL(18,2))
FROM BestCity;
GO

-- 4. Структура одного VIEW через системные представления.
SELECT
    c.column_id AS ColumnId,
    c.name AS ColumnName,
    t.name AS DataType,
    c.max_length AS MaxLength,
    c.precision AS [Precision],
    c.scale AS Scale
FROM sys.columns AS c
JOIN sys.types AS t
    ON t.user_type_id = c.user_type_id
WHERE c.object_id = OBJECT_ID(N'mart.vw_SalesByMonthCategory')
ORDER BY c.column_id;
GO

-- Ожидаемые ключевые значения:
-- VIEW = 4
-- vw_SalesByMonthCategory: 40 строк, 62 units, 2279410.00 revenue
-- vw_ProductPerformance:    20 строк, 62 units, 2279410.00 revenue
-- vw_CustomerValue:         15 строк, 62 units, 2279410.00 total spent
-- vw_SalesByCity:           10 строк, 62 units, 2279410.00 revenue
--
-- Лидеры:
-- MonthCategory: 2026-03 / Ноутбуки, 3 units, 300000.00
-- Product: Ноутбук Pro 14, 6 units, 720000.00
-- Customer: Иван Иванов, 3 orders, 368000.00
-- City: Москва, 7 orders, 775000.00