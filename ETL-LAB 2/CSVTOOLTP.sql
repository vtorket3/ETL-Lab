
--œŒƒ√Œ“Œ¬ ¿ TRANSFORM

SELECT 
    CAST(CustomerID AS INT) AS CustomerID,
    LTRIM(RTRIM(FirstName)) AS FirstName,
    LTRIM(RTRIM(LastName)) AS LastName,
    NULLIF(LTRIM(RTRIM(Email)), '') AS Email,
    LTRIM(RTRIM(City)) AS City
FROM [stg].[CustomersImportRaw];

SELECT 
    CAST(ProductID AS INT) AS ProductID,
    LTRIM(RTRIM(ProductName)) AS ProductName,
    LTRIM(RTRIM(Category)) AS Category,
    TRY_CONVERT(
        DECIMAL(12, 2),
        REPLACE(
            REPLACE(
                REPLACE(
                    REPLACE(
                        REPLACE(
                            Price COLLATE Cyrillic_General_BIN,
                            NCHAR(8381), N'' 
                        ),
                        NCHAR(160), N''  
                    ),
                    NCHAR(8239), N'' 
                ),
                N' ', N''        
            ),
            N',', N'.'           
        )
    ) AS Price
FROM [stg].[ProductsImportRaw];


SELECT 
    CAST(OrderID AS INT) AS OrderID,
    CAST(CustomerID AS INT) AS CustomerID,
    CAST(OrderDate AS DATE) AS OrderDate
FROM [stg].[OrdersImportRaw];



SELECT 
    CAST(OrderItemID AS INT) AS OrderItemID,
    CAST(OrderID AS INT) AS OrderID,
    CAST(ProductID AS INT) AS ProductID,
    CAST(Quantity AS INT) AS Quantity,
    TRY_CONVERT(
        DECIMAL(12, 2),
        REPLACE(
            REPLACE(
                REPLACE(
                    REPLACE(
                        REPLACE(
                            Price COLLATE Cyrillic_General_BIN,
                            NCHAR(8381), N''
                        ),
                        NCHAR(160), N''
                    ),
                    NCHAR(8239), N''
                ),
                N' ', N''
            ),
            N',', N'.'
        )
    ) AS Price
FROM [stg].[OrderItemsImportRaw];


-- œ–Œ¬≈– ¿ Õ¿ NULL »À» œ”—“€≈ —“–Œ »

SELECT * FROM [stg].[CustomersImportRaw]
WHERE CustomerID IS NULL 
   OR FirstName IS NULL OR LTRIM(RTRIM(FirstName)) = ''
   OR LastName IS NULL OR LTRIM(RTRIM(LastName)) = ''
   OR City IS NULL OR LTRIM(RTRIM(City)) = '';


SELECT *,
    TRY_CONVERT(DECIMAL(12, 2), REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(Price COLLATE Cyrillic_General_BIN, NCHAR(8381), N''), NCHAR(160), N''), NCHAR(8239), N''), N' ', N''), N',', N'.')) AS CleanPrice
FROM [stg].[ProductsImportRaw]
WHERE ProductID IS NULL 
   OR ProductName IS NULL OR LTRIM(RTRIM(ProductName)) = ''
   OR Category IS NULL OR LTRIM(RTRIM(Category)) = ''
   OR TRY_CONVERT(DECIMAL(12, 2), REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(Price COLLATE Cyrillic_General_BIN, NCHAR(8381), N''), NCHAR(160), N''), NCHAR(8239), N''), N' ', N''), N',', N'.')) IS NULL
   OR TRY_CONVERT(DECIMAL(12, 2), REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(Price COLLATE Cyrillic_General_BIN, NCHAR(8381), N''), NCHAR(160), N''), NCHAR(8239), N''), N' ', N''), N',', N'.')) < 0;


SELECT * FROM [stg].[OrdersImportRaw]
WHERE OrderID IS NULL 
   OR CustomerID IS NULL
   OR TRY_CONVERT(DATE, OrderDate) IS NULL;

SELECT *,
    TRY_CONVERT(DECIMAL(12, 2), REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(Price COLLATE Cyrillic_General_BIN, NCHAR(8381), N''), NCHAR(160), N''), NCHAR(8239), N''), N' ', N''), N',', N'.')) AS CleanPrice
FROM [stg].[OrderItemsImportRaw]
WHERE OrderItemID IS NULL 
   OR OrderID IS NULL 
   OR ProductID IS NULL
   OR Quantity IS NULL OR Quantity <= 0
   OR TRY_CONVERT(DECIMAL(12, 2), REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(Price COLLATE Cyrillic_General_BIN, NCHAR(8381), N''), NCHAR(160), N''), NCHAR(8239), N''), N' ', N''), N',', N'.')) IS NULL
   OR TRY_CONVERT(DECIMAL(12, 2), REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(Price COLLATE Cyrillic_General_BIN, NCHAR(8381), N''), NCHAR(160), N''), NCHAR(8239), N''), N' ', N''), N',', N'.')) < 0;

   -- «¿√–”« ¿ ƒ¿ÕÕ€’

   USE [TechStore];
GO

BEGIN TRANSACTION;
BEGIN TRY
    SET IDENTITY_INSERT [dbo].[Customers] ON;
    
    INSERT INTO [dbo].[Customers] ([CustomerID], [FirstName], [LastName], [Email], [City])
    SELECT 
        CAST(src.CustomerID AS INT),
        LTRIM(RTRIM(src.FirstName)),
        LTRIM(RTRIM(src.LastName)),
        NULLIF(LTRIM(RTRIM(src.Email)), ''),
        LTRIM(RTRIM(src.City))
    FROM [stg].[CustomersImportRaw] src
    WHERE NOT EXISTS (
        SELECT 1 FROM [dbo].[Customers] tgt WHERE tgt.[CustomerID] = src.CustomerID
    );
    
    SET IDENTITY_INSERT [dbo].[Customers] OFF;



    SET IDENTITY_INSERT [dbo].[Products] ON;
    
    INSERT INTO [dbo].[Products] ([ProductID], [ProductName], [Category], [Price])
    SELECT 
        CAST(src.ProductID AS INT),
        LTRIM(RTRIM(src.ProductName)),
        LTRIM(RTRIM(src.Category)),
        TRY_CONVERT(DECIMAL(12, 2), REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(src.Price COLLATE Cyrillic_General_BIN, NCHAR(8381), N''), NCHAR(160), N''), NCHAR(8239), N''), N' ', N''), N',', N'.'))
    FROM [stg].[ProductsImportRaw] src
    WHERE NOT EXISTS (
        SELECT 1 FROM [dbo].[Products] tgt WHERE tgt.[ProductID] = src.ProductID
    );
    
    SET IDENTITY_INSERT [dbo].[Products] OFF;



    SET IDENTITY_INSERT [dbo].[Orders] ON;
    
    INSERT INTO [dbo].[Orders] ([OrderID], [CustomerID], [OrderDate])
    SELECT 
        CAST(src.OrderID AS INT),
        CAST(src.CustomerID AS INT),
        TRY_CONVERT(DATE, src.OrderDate)
    FROM [stg].[OrdersImportRaw] src
    WHERE NOT EXISTS (
        SELECT 1 FROM [dbo].[Orders] tgt WHERE tgt.[OrderID] = src.OrderID
    );
    
    SET IDENTITY_INSERT [dbo].[Orders] OFF;



    SET IDENTITY_INSERT [dbo].[OrderItems] ON;
    
    INSERT INTO [dbo].[OrderItems] ([OrderItemID], [OrderID], [ProductID], [Quantity], [Price])
    SELECT 
        CAST(src.OrderItemID AS INT),
        CAST(src.OrderID AS INT),
        CAST(src.ProductID AS INT),
        CAST(src.Quantity AS INT),
        TRY_CONVERT(DECIMAL(12, 2), REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(src.Price COLLATE Cyrillic_General_BIN, NCHAR(8381), N''), NCHAR(160), N''), NCHAR(8239), N''), N' ', N''), N',', N'.'))
    FROM [stg].[OrderItemsImportRaw] src
    WHERE NOT EXISTS (
        SELECT 1 FROM [dbo].[OrderItems] tgt WHERE tgt.[OrderItemID] = src.OrderItemID
    );
    
    SET IDENTITY_INSERT [dbo].[OrderItems] OFF;


    COMMIT TRANSACTION;
    PRINT 'ƒ‡ÌÌ˚Â ÛÒÔÂ¯ÌÓ Á‡„ÛÊÂÌ˚ ‚ OLTP!';

END TRY
BEGIN CATCH

    ROLLBACK TRANSACTION;
    

    IF OBJECTPROPERTY(OBJECT_ID('[dbo].[Customers]'), 'TableHasIdentity') = 1 SET IDENTITY_INSERT [dbo].[Customers] OFF;
    IF OBJECTPROPERTY(OBJECT_ID('[dbo].[Products]'), 'TableHasIdentity') = 1 SET IDENTITY_INSERT [dbo].[Products] OFF;
    IF OBJECTPROPERTY(OBJECT_ID('[dbo].[Orders]'), 'TableHasIdentity') = 1 SET IDENTITY_INSERT [dbo].[Orders] OFF;
    IF OBJECTPROPERTY(OBJECT_ID('[dbo].[OrderItems]'), 'TableHasIdentity') = 1 SET IDENTITY_INSERT [dbo].[OrderItems] OFF;

    
    SELECT 
        ERROR_NUMBER() AS ErrorNumber,
        ERROR_MESSAGE() AS ErrorMessage;
END CATCH;
GO

-- œ–Œ¬≈– ¿ ÕŒ¬€’ ƒ¿ÕÕ€’

USE [TechStore];
GO

SELECT 'Customers' AS [œÓÍ‡Á‡ÚÂÎ¸], COUNT(*) AS [ŒÊË‰‡ÂÚÒˇ] FROM [dbo].[Customers]
UNION ALL
SELECT 'Products', COUNT(*) FROM [dbo].[Products]
UNION ALL
SELECT 'Orders', COUNT(*) FROM [dbo].[Orders]
UNION ALL
SELECT 'OrderItems', COUNT(*) FROM [dbo].[OrderItems]
UNION ALL
SELECT 'TotalUnits', SUM(Quantity) FROM [dbo].[OrderItems]
UNION ALL
SELECT 'TotalRevenue', SUM(Quantity * Price) FROM [dbo].[OrderItems];
GO
