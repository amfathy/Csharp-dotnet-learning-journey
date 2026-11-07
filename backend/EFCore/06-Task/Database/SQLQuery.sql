
-- =============================================
-- 1. CREATE DATABASE
-- =============================================

CREATE DATABASE ShopDb;
GO

USE ShopDb;
GO

-- =============================================
-- 2. CREATE SCHEMAS
-- =============================================

CREATE SCHEMA Inventory;
GO

CREATE SCHEMA Sales;
GO

-- =============================================
-- 3. CREATE PRODUCTS TABLE
-- =============================================

CREATE TABLE Inventory.Products
(
    Id INT IDENTITY(1,1),
    pr
    Name NVARCHAR(100) NOT NULL,

    UnitPrice DECIMAL(18,2) NOT NULL,

    [Description] NVARCHAR(500)  null,

    CONSTRAINT Products_PK PRIMARY KEY (Id),

    CONSTRAINT Products_UnitPrice_CK
        CHECK (UnitPrice >= 0)
);
GO

-- =============================================
-- 4. CREATE ORDERS TABLE
-- =============================================

CREATE TABLE Sales.Orders
(
    Id INT IDENTITY(1,1),

    CustomerEmail NVARCHAR(150) NOT NULL,

    OrderDate DATETIME2 NOT NULL
        DEFAULT SYSDATETIME(),

    CONSTRAINT Orders_PK PRIMARY KEY (Id)
);
GO

-- =============================================
-- 5. CREATE ORDER DETAILS TABLE
-- =============================================

CREATE TABLE Sales.OrderDetails
(
    Id INT IDENTITY(1,1),

    OrderId INT NOT NULL,

    ProductId INT NOT NULL,

    UnitPrice DECIMAL(18,2) NOT NULL,

    Quantity INT NOT NULL,

    CONSTRAINT OrderDetails_PK PRIMARY KEY (Id),

    CONSTRAINT OrderDetails_Order_FK
        FOREIGN KEY (OrderId)
        REFERENCES Sales.Orders(Id),

    CONSTRAINT OrderDetails_Product_FK
        FOREIGN KEY (ProductId)
        REFERENCES Inventory.Products(Id),

    CONSTRAINT OrderDetails_UnitPrice_CK
        CHECK (UnitPrice >= 0),

    CONSTRAINT OrderDetails_Quantity_CK
        CHECK (Quantity > 0)
);
GO

-- =============================================
-- 6. INSERT PRODUCTS
-- =============================================

INSERT INTO Inventory.Products
    (Name, UnitPrice, [Description])
VALUES
    ('Laptop', 25000, 'Gaming laptop'),
    ('Mouse', 300, 'Wireless mouse'),
    ('Keyboard', 750, 'Mechanical keyboard'),
    ('Monitor', 6500, '27-inch IPS monitor'),
    ('Headset', 1200, 'Gaming headset');
GO

-- =============================================
-- 7. INSERT ORDERS
-- =============================================

INSERT INTO Sales.Orders
    (CustomerEmail, OrderDate)
VALUES
    ('mona@example.com', SYSDATETIME()),
    ('ahmed@example.com', SYSDATETIME()),
    ('sara@example.com', SYSDATETIME());
GO

-- =============================================
-- 8. INSERT ORDER DETAILS
-- =============================================

INSERT INTO Sales.OrderDetails
    (OrderId, ProductId, UnitPrice, Quantity)
VALUES
    -- Order 1
    (1, 1, 25000, 1),
    (1, 2, 300, 2),

    -- Order 2
    (2, 3, 750, 1),
    (2, 4, 6500, 2),

    -- Order 3
    (3, 1, 25000, 1),
    (3, 5, 1200, 1);
GO

-- =============================================
-- 9. VERIFY INSERTED DATA
-- =============================================

SELECT * FROM Inventory.Products;

SELECT * FROM Sales.Orders;

SELECT * FROM Sales.OrderDetails;
GO

-- =============================================
-- 10. JOIN: ORDER DETAILS WITH PRODUCT NAMES
-- =============================================
CREATE VIEW Sales.OrderDetailsView
as 
SELECT
    O.Id AS OrderId,
    O.CustomerEmail,
    P.Name AS ProductName,
    OD.UnitPrice,
    OD.Quantity,
    OD.UnitPrice * OD.Quantity AS LineTotal
FROM Sales.Orders O
INNER JOIN Sales.OrderDetails OD
    ON O.Id = OD.OrderId
INNER JOIN Inventory.Products P
    ON P.Id = OD.ProductId;
GO

-- =============================================
-- 11. ORDER TOTALS
-- =============================================
CREATE VIEW Sales.OrderBillsView
as
SELECT
    O.Id AS OrderId,
    O.CustomerEmail,
    SUM(OD.UnitPrice * OD.Quantity) AS TotalAmount
FROM Sales.Orders O
INNER JOIN Sales.OrderDetails OD
    ON O.Id = OD.OrderId
GROUP BY
    O.Id,
    O.CustomerEmail;
GO

