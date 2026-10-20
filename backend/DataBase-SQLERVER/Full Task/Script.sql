/* =====================================================================
   SHOPSPHERE  -  Training database for SQL Server (2019 / 2022 / Azure SQL)
   ---------------------------------------------------------------------
   Domain : Multi-country e-commerce (catalog, inventory, sales, HR)
   Schemas: Geo, HR, Catalog, Inv, Sales
   Size   : 19 tables, ~ 5,000 customers, 300 products, 20,000 orders,
            ~ 60,000 order lines, ~ 17,000 payments, ~ 16,000 shipments,
            ~ 7,000 reviews, 120 employees.
   Data is generated DETERMINISTICALLY (no NEWID/RAND) so every learner
   gets exactly the same rows and the same query results.

   HOW TO RUN : execute the whole file once (takes a few seconds).
                It DROPS and re-creates the ShopSphere database every time.

   CONVENTIONS USED BY THE TASKS
   * "Today" for all reporting tasks is 2026-06-30  (data ends there).
   * Order total formula (used by payments and by the tasks):
        ItemsTotal = SUM(Quantity * UnitPrice * (1 - DiscountPercent/100.0))
        OrderTotal = ItemsTotal * (1 - CouponPercent/100.0) + ShippingFee
   * Revenue = payments with Status = 'Completed'.

   INTENTIONAL "REAL WORLD" QUIRKS (find them with queries!)
   * Customers 4701..5000 never placed an order.
   * Products 281..300 are "new arrivals" and were never ordered.
   * Some NULL phones / genders / supplier ratings / review comments.
   * Payments of orders whose OrderId % 400 = 0 were under-paid by 5%.
   * Some old orders are still in status 'Shipped' (stuck shipments).
   * A few customers are referred by other customers (self reference).
   * Employees form a 3-level hierarchy (heads -> managers -> staff).
   * Categories form a 3-level tree.
   * There are NO secondary indexes except those created below
     (so index / performance tasks are meaningful).
   ===================================================================== */
USE master;
GO
IF DB_ID(N'ShopSphere') IS NOT NULL
BEGIN
    ALTER DATABASE ShopSphere SET SINGLE_USER WITH ROLLBACK IMMEDIATE;
    DROP DATABASE ShopSphere;
END
GO
CREATE DATABASE ShopSphere;
GO
USE ShopSphere;
GO
SET NOCOUNT ON;
GO
CREATE SCHEMA Geo;
GO
CREATE SCHEMA HR;
GO
CREATE SCHEMA Catalog;
GO
CREATE SCHEMA Inv;
GO
CREATE SCHEMA Sales;
GO

/* ============================ TABLES (DDL) ============================ */

-- ---------- Geo ----------
CREATE TABLE Geo.Countries (
    CountryId   INT IDENTITY(1,1) CONSTRAINT PK_Countries PRIMARY KEY,
    CountryName NVARCHAR(60) NOT NULL CONSTRAINT UQ_Countries_Name UNIQUE,
    IsoCode     CHAR(2)      NOT NULL CONSTRAINT UQ_Countries_Iso  UNIQUE
);
CREATE TABLE Geo.Cities (
    CityId    INT IDENTITY(1,1) CONSTRAINT PK_Cities PRIMARY KEY,
    CountryId INT NOT NULL CONSTRAINT FK_Cities_Countries REFERENCES Geo.Countries(CountryId),
    CityName  NVARCHAR(60) NOT NULL,
    CONSTRAINT UQ_Cities UNIQUE (CountryId, CityName)
);

-- ---------- HR ----------
CREATE TABLE HR.Departments (
    DepartmentId   INT IDENTITY(1,1) CONSTRAINT PK_Departments PRIMARY KEY,
    DepartmentName NVARCHAR(50) NOT NULL CONSTRAINT UQ_Departments_Name UNIQUE,
    Budget         DECIMAL(12,2) NOT NULL CONSTRAINT CK_Departments_Budget CHECK (Budget >= 0)
);
CREATE TABLE HR.Employees (
    EmployeeId   INT IDENTITY(1,1) CONSTRAINT PK_Employees PRIMARY KEY,
    FirstName    NVARCHAR(50)  NOT NULL,
    LastName     NVARCHAR(50)  NOT NULL,
    Email        NVARCHAR(120) NOT NULL CONSTRAINT UQ_Employees_Email UNIQUE,
    HireDate     DATE          NOT NULL,
    Salary       DECIMAL(10,2) NOT NULL CONSTRAINT CK_Employees_Salary CHECK (Salary > 0),
    DepartmentId INT NOT NULL CONSTRAINT FK_Employees_Departments REFERENCES HR.Departments(DepartmentId),
    ManagerId    INT NULL     CONSTRAINT FK_Employees_Manager REFERENCES HR.Employees(EmployeeId),
    CityId       INT NOT NULL CONSTRAINT FK_Employees_Cities REFERENCES Geo.Cities(CityId),
    IsActive     BIT NOT NULL CONSTRAINT DF_Employees_IsActive DEFAULT 1
);

-- ---------- Catalog ----------
CREATE TABLE Catalog.Categories (
    CategoryId       INT IDENTITY(1,1) CONSTRAINT PK_Categories PRIMARY KEY,
    CategoryName     NVARCHAR(60) NOT NULL CONSTRAINT UQ_Categories_Name UNIQUE,
    ParentCategoryId INT NULL CONSTRAINT FK_Categories_Parent REFERENCES Catalog.Categories(CategoryId)
);
CREATE TABLE Catalog.Brands (
    BrandId   INT IDENTITY(1,1) CONSTRAINT PK_Brands PRIMARY KEY,
    BrandName NVARCHAR(60) NOT NULL CONSTRAINT UQ_Brands_Name UNIQUE,
    CountryId INT NOT NULL CONSTRAINT FK_Brands_Countries REFERENCES Geo.Countries(CountryId)
);
CREATE TABLE Catalog.Suppliers (
    SupplierId   INT IDENTITY(1,1) CONSTRAINT PK_Suppliers PRIMARY KEY,
    CompanyName  NVARCHAR(100) NOT NULL,
    ContactEmail NVARCHAR(120) NULL,
    CityId       INT NOT NULL CONSTRAINT FK_Suppliers_Cities REFERENCES Geo.Cities(CityId),
    Rating       TINYINT NULL CONSTRAINT CK_Suppliers_Rating CHECK (Rating BETWEEN 1 AND 5)
);
CREATE TABLE Catalog.Products (
    ProductId   INT IDENTITY(1,1) CONSTRAINT PK_Products PRIMARY KEY,
    ProductName NVARCHAR(150) NOT NULL,
    SKU         VARCHAR(20)   NOT NULL CONSTRAINT UQ_Products_SKU UNIQUE,
    CategoryId  INT NOT NULL CONSTRAINT FK_Products_Categories REFERENCES Catalog.Categories(CategoryId),
    BrandId     INT NOT NULL CONSTRAINT FK_Products_Brands     REFERENCES Catalog.Brands(BrandId),
    UnitPrice   DECIMAL(10,2) NOT NULL CONSTRAINT CK_Products_UnitPrice CHECK (UnitPrice > 0),
    CostPrice   DECIMAL(10,2) NOT NULL CONSTRAINT CK_Products_CostPrice CHECK (CostPrice >= 0),
    IsActive    BIT NOT NULL CONSTRAINT DF_Products_IsActive DEFAULT 1,
    CreatedAt   DATETIME2(0) NOT NULL CONSTRAINT DF_Products_CreatedAt DEFAULT SYSDATETIME()
);
CREATE TABLE Catalog.ProductSuppliers (          -- M:N with payload
    ProductId    INT NOT NULL CONSTRAINT FK_PS_Products  REFERENCES Catalog.Products(ProductId),
    SupplierId   INT NOT NULL CONSTRAINT FK_PS_Suppliers REFERENCES Catalog.Suppliers(SupplierId),
    SupplyPrice  DECIMAL(10,2) NOT NULL,
    LeadTimeDays INT NOT NULL,
    CONSTRAINT PK_ProductSuppliers PRIMARY KEY (ProductId, SupplierId)
);

-- ---------- Inventory ----------
CREATE TABLE Inv.Warehouses (
    WarehouseId   INT IDENTITY(1,1) CONSTRAINT PK_Warehouses PRIMARY KEY,
    WarehouseName NVARCHAR(80) NOT NULL CONSTRAINT UQ_Warehouses_Name UNIQUE,
    CityId        INT NOT NULL CONSTRAINT FK_Warehouses_Cities REFERENCES Geo.Cities(CityId),
    Capacity      INT NOT NULL CONSTRAINT CK_Warehouses_Capacity CHECK (Capacity > 0)
);
CREATE TABLE Inv.Stock (                         -- M:N with payload
    WarehouseId    INT NOT NULL CONSTRAINT FK_Stock_Warehouses REFERENCES Inv.Warehouses(WarehouseId),
    ProductId      INT NOT NULL CONSTRAINT FK_Stock_Products   REFERENCES Catalog.Products(ProductId),
    QuantityOnHand INT NOT NULL CONSTRAINT CK_Stock_Qty CHECK (QuantityOnHand >= 0),
    ReorderLevel   INT NOT NULL,
    CONSTRAINT PK_Stock PRIMARY KEY (WarehouseId, ProductId)
);

-- ---------- Sales ----------
CREATE TABLE Sales.Customers (
    CustomerId INT IDENTITY(1,1) CONSTRAINT PK_Customers PRIMARY KEY,
    FirstName  NVARCHAR(50)  NOT NULL,
    LastName   NVARCHAR(50)  NOT NULL,
    Email      NVARCHAR(120) NOT NULL CONSTRAINT UQ_Customers_Email UNIQUE,
    Phone      NVARCHAR(20)  NULL,
    BirthDate  DATE NULL,
    Gender     CHAR(1) NULL CONSTRAINT CK_Customers_Gender CHECK (Gender IN ('M','F')),
    CityId     INT NOT NULL CONSTRAINT FK_Customers_Cities REFERENCES Geo.Cities(CityId),
    RegisteredAt DATETIME2(0) NOT NULL CONSTRAINT DF_Customers_RegisteredAt DEFAULT SYSDATETIME(),
    IsActive   BIT NOT NULL CONSTRAINT DF_Customers_IsActive DEFAULT 1,
    ReferredByCustomerId INT NULL CONSTRAINT FK_Customers_ReferredBy REFERENCES Sales.Customers(CustomerId)
);
CREATE TABLE Sales.CustomerAddresses (
    AddressId  INT IDENTITY(1,1) CONSTRAINT PK_CustomerAddresses PRIMARY KEY,
    CustomerId INT NOT NULL CONSTRAINT FK_Addr_Customers REFERENCES Sales.Customers(CustomerId),
    Street     NVARCHAR(150) NOT NULL,
    CityId     INT NOT NULL CONSTRAINT FK_Addr_Cities REFERENCES Geo.Cities(CityId),
    IsDefault  BIT NOT NULL CONSTRAINT DF_Addr_IsDefault DEFAULT 0
);
-- only ONE default address per customer (filtered unique index)
CREATE UNIQUE NONCLUSTERED INDEX UX_Addr_OneDefault ON Sales.CustomerAddresses(CustomerId) WHERE IsDefault = 1;

CREATE TABLE Sales.Coupons (
    CouponId        INT IDENTITY(1,1) CONSTRAINT PK_Coupons PRIMARY KEY,
    Code            VARCHAR(30) NOT NULL CONSTRAINT UQ_Coupons_Code UNIQUE,
    DiscountPercent TINYINT NOT NULL CONSTRAINT CK_Coupons_Pct CHECK (DiscountPercent BETWEEN 1 AND 90),
    ValidFrom       DATE NOT NULL,
    ValidTo         DATE NOT NULL,
    MaxUses         INT NULL,
    CONSTRAINT CK_Coupons_Dates CHECK (ValidTo >= ValidFrom)
);
CREATE TABLE Sales.Orders (
    OrderId           INT IDENTITY(1,1) CONSTRAINT PK_Orders PRIMARY KEY,
    CustomerId        INT NOT NULL CONSTRAINT FK_Orders_Customers REFERENCES Sales.Customers(CustomerId),
    EmployeeId        INT NULL     CONSTRAINT FK_Orders_Employees REFERENCES HR.Employees(EmployeeId),   -- sales rep (NULL = online order)
    OrderDate         DATETIME2(0) NOT NULL CONSTRAINT DF_Orders_OrderDate DEFAULT SYSDATETIME(),
    Status            VARCHAR(20)  NOT NULL CONSTRAINT DF_Orders_Status DEFAULT 'Pending'
                      CONSTRAINT CK_Orders_Status CHECK (Status IN ('Pending','Paid','Shipped','Delivered','Cancelled','Returned')),
    ShippingAddressId INT NOT NULL CONSTRAINT FK_Orders_Addresses REFERENCES Sales.CustomerAddresses(AddressId),
    CouponId          INT NULL     CONSTRAINT FK_Orders_Coupons REFERENCES Sales.Coupons(CouponId),
    ShippingFee       DECIMAL(8,2) NOT NULL CONSTRAINT DF_Orders_ShippingFee DEFAULT 0 CONSTRAINT CK_Orders_Fee CHECK (ShippingFee >= 0)
);
CREATE TABLE Sales.OrderItems (
    OrderItemId     INT IDENTITY(1,1) CONSTRAINT PK_OrderItems PRIMARY KEY,
    OrderId         INT NOT NULL CONSTRAINT FK_OI_Orders   REFERENCES Sales.Orders(OrderId),
    ProductId       INT NOT NULL CONSTRAINT FK_OI_Products REFERENCES Catalog.Products(ProductId),
    Quantity        INT NOT NULL CONSTRAINT CK_OI_Qty CHECK (Quantity > 0),
    UnitPrice       DECIMAL(10,2) NOT NULL CONSTRAINT CK_OI_Price CHECK (UnitPrice > 0),   -- price snapshot at order time
    DiscountPercent DECIMAL(5,2)  NOT NULL CONSTRAINT DF_OI_Disc DEFAULT 0 CONSTRAINT CK_OI_Disc CHECK (DiscountPercent BETWEEN 0 AND 100),
    CONSTRAINT UQ_OI_OrderProduct UNIQUE (OrderId, ProductId)
);
CREATE TABLE Sales.Payments (
    PaymentId   INT IDENTITY(1,1) CONSTRAINT PK_Payments PRIMARY KEY,
    OrderId     INT NOT NULL CONSTRAINT FK_Pay_Orders REFERENCES Sales.Orders(OrderId),
    PaymentDate DATETIME2(0) NOT NULL,
    Amount      DECIMAL(12,2) NOT NULL CONSTRAINT CK_Pay_Amount CHECK (Amount > 0),
    Method      VARCHAR(20) NOT NULL CONSTRAINT CK_Pay_Method CHECK (Method IN ('CreditCard','Cash','Wallet','BankTransfer')),
    Status      VARCHAR(20) NOT NULL CONSTRAINT CK_Pay_Status CHECK (Status IN ('Pending','Completed','Failed','Refunded'))
);
CREATE TABLE Sales.Shipments (                   -- 1:0..1 with Orders
    ShipmentId    INT IDENTITY(1,1) CONSTRAINT PK_Shipments PRIMARY KEY,
    OrderId       INT NOT NULL CONSTRAINT UQ_Shipments_Order UNIQUE
                  CONSTRAINT FK_Ship_Orders REFERENCES Sales.Orders(OrderId),
    WarehouseId   INT NOT NULL CONSTRAINT FK_Ship_Warehouses REFERENCES Inv.Warehouses(WarehouseId),
    ShippedDate   DATETIME2(0) NOT NULL,
    DeliveredDate DATETIME2(0) NULL,
    Carrier       VARCHAR(20)  NOT NULL,
    TrackingNo    VARCHAR(20)  NOT NULL
);
CREATE TABLE Sales.Reviews (                     -- M:N Customers <-> Products with payload
    ReviewId   INT IDENTITY(1,1) CONSTRAINT PK_Reviews PRIMARY KEY,
    ProductId  INT NOT NULL CONSTRAINT FK_Rev_Products  REFERENCES Catalog.Products(ProductId),
    CustomerId INT NOT NULL CONSTRAINT FK_Rev_Customers REFERENCES Sales.Customers(CustomerId),
    Rating     TINYINT NOT NULL CONSTRAINT CK_Rev_Rating CHECK (Rating BETWEEN 1 AND 5),
    Comment    NVARCHAR(400) NULL,
    ReviewDate DATETIME2(0) NOT NULL,
    CONSTRAINT UQ_Reviews_ProductCustomer UNIQUE (ProductId, CustomerId)
);
GO

/* ============================ DATA (DML) ============================== */
SET NOCOUNT ON;

-- helper numbers table (1..100000) - dropped at the end of the script
SELECT TOP (100000) CAST(ROW_NUMBER() OVER (ORDER BY (SELECT NULL)) AS INT) AS n
INTO #Nums
FROM sys.all_objects a CROSS JOIN sys.all_objects b;
CREATE UNIQUE CLUSTERED INDEX IX_Nums ON #Nums(n);

-- helper name lists
SELECT ROW_NUMBER() OVER (ORDER BY v.name) AS id, v.name, v.gender
INTO #First
FROM (VALUES (N'Ahmed','M'),(N'Mohamed','M'),(N'Mahmoud','M'),(N'Omar','M'),(N'Youssef','M'),
             (N'Ali','M'),(N'Hassan','M'),(N'Khaled','M'),(N'Ibrahim','M'),(N'Mostafa','M'),
             (N'Sara','F'),(N'Fatma','F'),(N'Mariam','F'),(N'Nour','F'),(N'Salma','F'),
             (N'Aya','F'),(N'Hana','F'),(N'Laila','F'),(N'Rania','F'),(N'Dina','F'),
             (N'John','M'),(N'Emma','F'),(N'Liam','M'),(N'Olivia','F'),(N'Noah','M'),
             (N'Sophia','F'),(N'Lucas','M'),(N'Mia','F'),(N'Hans','M'),(N'Priya','F')) v(name, gender);

SELECT ROW_NUMBER() OVER (ORDER BY v.name) AS id, v.name
INTO #Last
FROM (VALUES (N'Hassan'),(N'Ibrahim'),(N'Mostafa'),(N'Salem'),(N'Farouk'),(N'Nasser'),(N'Aziz'),
             (N'Khalil'),(N'Saad'),(N'Mansour'),(N'Fahmy'),(N'Zaki'),(N'Abdallah'),(N'Shaker'),
             (N'Gamal'),(N'Smith'),(N'Johnson'),(N'Brown'),(N'Miller'),(N'Davis'),(N'Garcia'),
             (N'Martin'),(N'Schmidt'),(N'Dubois'),(N'Patel'),(N'Singh'),(N'Kumar'),(N'Wilson'),
             (N'Taylor'),(N'Clark')) v(name);

-- ---------- Countries & Cities ----------
INSERT Geo.Countries (CountryName, IsoCode) VALUES
 (N'Egypt','EG'),(N'Saudi Arabia','SA'),(N'United Arab Emirates','AE'),(N'Jordan','JO'),(N'Germany','DE'),
 (N'France','FR'),(N'United Kingdom','GB'),(N'United States','US'),(N'Canada','CA'),(N'India','IN');

INSERT Geo.Cities (CountryId, CityName)
SELECT c.CountryId, v.CityName
FROM (VALUES ('EG',N'Cairo'),('EG',N'Alexandria'),('EG',N'Giza'),('EG',N'Mansoura'),('EG',N'Aswan'),
             ('SA',N'Riyadh'),('SA',N'Jeddah'),('SA',N'Dammam'),
             ('AE',N'Dubai'),('AE',N'Abu Dhabi'),('AE',N'Sharjah'),
             ('JO',N'Amman'),('JO',N'Irbid'),
             ('DE',N'Berlin'),('DE',N'Munich'),('DE',N'Hamburg'),
             ('FR',N'Paris'),('FR',N'Lyon'),
             ('GB',N'London'),('GB',N'Manchester'),('GB',N'Birmingham'),
             ('US',N'New York'),('US',N'Los Angeles'),('US',N'Chicago'),('US',N'Houston'),
             ('CA',N'Toronto'),('CA',N'Vancouver'),
             ('IN',N'Mumbai'),('IN',N'Delhi'),('IN',N'Bangalore')) v(Iso, CityName)
JOIN Geo.Countries c ON c.IsoCode = v.Iso;

-- ---------- HR ----------
INSERT HR.Departments (DepartmentName, Budget) VALUES
 (N'Sales',3500000),(N'Marketing',4200000),(N'IT',4000000),(N'HR',2800000),(N'Finance',3000000),(N'Logistics',5000000);

-- 120 employees: 1-6 department heads, 7-30 managers, 31-120 staff
INSERT HR.Employees (FirstName, LastName, Email, HireDate, Salary, DepartmentId, ManagerId, CityId, IsActive)
SELECT f.name, l.name,
       LOWER(CONCAT(f.name, N'.', l.name, nm.n, N'@shopsphere.com')),
       DATEADD(DAY, -(nm.n * 29 % 3000), CAST('2026-01-01' AS DATE)),
       CAST(CASE WHEN nm.n <= 6 THEN 40000 ELSE 9000 + (nm.n * 73 % 150) * 100 END AS DECIMAL(10,2)),
       1 + nm.n % 6,
       CASE WHEN nm.n <= 6  THEN NULL
            WHEN nm.n <= 30 THEN ((nm.n - 1) % 6) + 1
            ELSE 7 + (nm.n - 7) % 24 END,
       ((nm.n * 7) % 30) + 1,
       CASE WHEN nm.n % 17 = 0 THEN 0 ELSE 1 END
FROM #Nums nm
JOIN #First f ON f.id = nm.n % 30 + 1
JOIN #Last  l ON l.id = (nm.n / 30) % 30 + 1
WHERE nm.n <= 120
ORDER BY nm.n;

-- ---------- Catalog ----------
INSERT Catalog.Categories (CategoryName, ParentCategoryId) VALUES
 (N'Electronics',NULL),(N'Fashion',NULL),(N'Home & Kitchen',NULL),(N'Books',NULL),(N'Sports',NULL),(N'Beauty',NULL);

INSERT Catalog.Categories (CategoryName, ParentCategoryId)
SELECT v.Child, p.CategoryId
FROM (VALUES (N'Electronics',N'Phones'),(N'Electronics',N'Laptops'),(N'Electronics',N'Audio'),(N'Electronics',N'Cameras'),
             (N'Fashion',N'Men'),(N'Fashion',N'Women'),(N'Fashion',N'Shoes'),
             (N'Home & Kitchen',N'Furniture'),(N'Home & Kitchen',N'Appliances'),(N'Home & Kitchen',N'Cookware'),
             (N'Books',N'Fiction'),(N'Books',N'Technical'),(N'Books',N'Comics'),
             (N'Sports',N'Fitness'),(N'Sports',N'Outdoor'),
             (N'Beauty',N'Skincare'),(N'Beauty',N'Makeup')) v(Parent, Child)
JOIN Catalog.Categories p ON p.CategoryName = v.Parent;

INSERT Catalog.Categories (CategoryName, ParentCategoryId)
SELECT v.Child, p.CategoryId
FROM (VALUES (N'Phones',N'Smartphones'),(N'Phones',N'Phone Accessories'),
             (N'Laptops',N'Gaming Laptops'),(N'Laptops',N'Ultrabooks')) v(Parent, Child)
JOIN Catalog.Categories p ON p.CategoryName = v.Parent;

INSERT Catalog.Brands (BrandName, CountryId)
SELECT v.name, ((ROW_NUMBER() OVER (ORDER BY v.name) - 1) % 10) + 1
FROM (VALUES (N'NovaTech'),(N'Zenith'),(N'Aurora'),(N'PixelWorks'),(N'UrbanWear'),(N'HomeNest'),(N'BookHaven'),
             (N'FitPro'),(N'GlowLab'),(N'SoundWave'),(N'Voltix'),(N'Cairo Crafts'),(N'Nile Home'),(N'Alpine'),
             (N'Sakura'),(N'Titan'),(N'Everly'),(N'Orbit'),(N'Mosaic'),(N'Crescent')) v(name);

INSERT Catalog.Suppliers (CompanyName, ContactEmail, CityId, Rating)
SELECT CONCAT(CHOOSE(nm.n % 8 + 1, N'Delta',N'Prime',N'Global',N'Nile',N'Apex',N'Summit',N'Blue',N'Metro'), N' ',
              CHOOSE(nm.n % 4 + 1, N'Trading',N'Supplies',N'Distribution',N'Industries'), N' #', nm.n),
       CONCAT(N'contact', nm.n, N'@supplier', nm.n, N'.com'),
       ((nm.n * 3) % 30) + 1,
       CASE WHEN nm.n % 11 = 0 THEN NULL ELSE 1 + nm.n % 5 END
FROM #Nums nm WHERE nm.n <= 40 ORDER BY nm.n;

-- leaf categories (categories without children) receive the products
SELECT ROW_NUMBER() OVER (ORDER BY c.CategoryId) AS rn, c.CategoryId, c.CategoryName
INTO #Leaf
FROM Catalog.Categories c
WHERE NOT EXISTS (SELECT 1 FROM Catalog.Categories x WHERE x.ParentCategoryId = c.CategoryId);

INSERT Catalog.Products (ProductName, SKU, CategoryId, BrandId, UnitPrice, CostPrice, IsActive, CreatedAt)
SELECT CONCAT(b.BrandName, N' ', l.CategoryName, N' ', CHOOSE(nm.n % 6 + 1, N'Pro',N'Lite',N'Max',N'Plus',N'Mini',N'Classic'), N' ', nm.n),
       CONCAT('SKU-', RIGHT(CONCAT('00000', nm.n), 5)),
       l.CategoryId,
       x.BrandId,
       x.Price,
       CAST(x.Price * 0.62 AS DECIMAL(10,2)),
       CASE WHEN nm.n % 23 = 0 THEN 0 ELSE 1 END,
       DATEADD(DAY, -(nm.n * 3 % 900), CAST('2026-06-30' AS DATETIME2(0)))
FROM #Nums nm
JOIN #Leaf l ON l.rn = (nm.n % (SELECT COUNT(*) FROM #Leaf)) + 1
CROSS APPLY (SELECT ((nm.n * 7) % 20) + 1 AS BrandId,
                    CAST(9.99 + (nm.n * 137 % 1990) AS DECIMAL(10,2)) AS Price) x
JOIN Catalog.Brands b ON b.BrandId = x.BrandId
WHERE nm.n <= 300
ORDER BY nm.n;

-- every product has 1 supplier, even ids have 2, ids divisible by 5 have 3
INSERT Catalog.ProductSuppliers
(
    ProductId,
    SupplierId,
    SupplyPrice,
    LeadTimeDays
)
SELECT
    p.ProductId,
    ((p.ProductId + s.offset_value) % 40) + 1,
    CAST(
        p.CostPrice * (0.90 + s.k * 0.05)
        AS DECIMAL(10,2)
    ),
    2 + (p.ProductId % 14)
FROM Catalog.Products p
JOIN
(
    VALUES
        (0, 0, 1),
        (1, 13, 2),
        (2, 27, 5)
) s(k, offset_value, m)
    ON p.ProductId % s.m = 0;
-- ---------- Inventory ----------
INSERT Inv.Warehouses (WarehouseName, CityId, Capacity)
SELECT v.wname, c.CityId, v.cap
FROM (VALUES (N'Cairo Main Hub',N'Cairo',50000),(N'Alexandria DC',N'Alexandria',20000),
             (N'Riyadh Central',N'Riyadh',40000),(N'Dubai Free Zone',N'Dubai',45000),
             (N'Berlin Logistics',N'Berlin',30000),(N'London Docks',N'London',35000),
             (N'New York East',N'New York',60000),(N'Mumbai Depot',N'Mumbai',25000)) v(wname, cname, cap)
JOIN Geo.Cities c ON c.CityName = v.cname;

INSERT Inv.Stock (WarehouseId, ProductId, QuantityOnHand, ReorderLevel)
SELECT w.WarehouseId, p.ProductId,
       (p.ProductId * w.WarehouseId * 13) % 500,
       20 + (p.ProductId % 5) * 10
FROM Inv.Warehouses w CROSS JOIN Catalog.Products p
WHERE (p.ProductId + w.WarehouseId) % 3 <> 0;

-- ---------- Sales ----------
INSERT Sales.Customers (FirstName, LastName, Email, Phone, BirthDate, Gender, CityId, RegisteredAt, IsActive, ReferredByCustomerId)
SELECT f.name, l.name,
       LOWER(CONCAT(f.name, N'.', l.name, nm.n, N'@mail.com')),
       CASE WHEN nm.n % 9 = 0 THEN NULL ELSE CONCAT(N'+2010', RIGHT(CONCAT('00000000', (nm.n * 7919) % 100000000), 8)) END,
       DATEADD(DAY, -(7000 + nm.n * 97 % 18000), CAST('2026-01-01' AS DATE)),
       CASE WHEN nm.n % 50 = 0 THEN NULL ELSE f.gender END,
       ((nm.n * 11) % 30) + 1,
       DATEADD(HOUR, -((nm.n * 53) % 20000), CAST('2026-06-30T12:00:00' AS DATETIME2(0))),
       CASE WHEN nm.n % 25 = 0 THEN 0 ELSE 1 END,
       CASE WHEN nm.n > 100 AND nm.n % 5 = 0 THEN (nm.n * 3) % 100 + 1 END
FROM #Nums nm
JOIN #First f ON f.id = nm.n % 30 + 1
JOIN #Last  l ON l.id = (nm.n / 30) % 30 + 1
WHERE nm.n <= 5000
ORDER BY nm.n;

-- default address for everybody, a second address for every 3rd customer
INSERT Sales.CustomerAddresses (CustomerId, Street, CityId, IsDefault)
SELECT c.CustomerId,
       CONCAT(c.CustomerId % 200 + 1, N' ', CHOOSE(c.CustomerId % 6 + 1, N'Nile St',N'Garden Ave',N'Palm Rd',N'Station Sq',N'Market St',N'Park Lane')),
       c.CityId, 1
FROM Sales.Customers c ORDER BY c.CustomerId;

INSERT Sales.CustomerAddresses (CustomerId, Street, CityId, IsDefault)
SELECT c.CustomerId,
       CONCAT(c.CustomerId % 90 + 1, N' ', CHOOSE(c.CustomerId % 4 + 1, N'Business Park',N'Corniche Rd',N'Old Town Sq',N'Harbor St')),
       ((c.CustomerId * 5) % 30) + 1, 0
FROM Sales.Customers c WHERE c.CustomerId % 3 = 0 ORDER BY c.CustomerId;

INSERT Sales.Coupons (Code, DiscountPercent, ValidFrom, ValidTo, MaxUses) VALUES
 ('WELCOME10',10,'2025-01-01','2026-12-31',NULL),
 ('RAMADAN20',20,'2025-03-01','2025-04-15',5000),
 ('SUMMER15',15,'2025-06-01','2025-08-31',3000),
 ('BLACKFRI30',30,'2025-11-20','2025-11-30',2000),
 ('VIP25',25,'2025-01-01','2027-01-01',NULL),
 ('FREESHIP5',5,'2025-01-01','2026-12-31',NULL),
 ('EID18',18,'2025-06-05','2025-06-15',1500),
 ('BACK2SCHOOL12',12,'2025-08-15','2025-09-30',2500),
 ('NEWYEAR10',10,'2025-12-25','2026-01-05',4000),
 ('FLASH35',35,'2026-02-14','2026-02-15',500),
 ('LOYAL8',8,'2025-01-01','2026-12-31',NULL),
 ('SPRING10',10,'2026-03-01','2026-05-31',3500);

-- 20,000 orders spread over the 2 years before 2026-06-30
INSERT Sales.Orders (CustomerId, EmployeeId, OrderDate, Status, ShippingAddressId, CouponId, ShippingFee)
SELECT x.CustomerId,
       CASE WHEN nm.n % 4 = 0 THEN NULL ELSE 6 * (nm.n % 20 + 1) END,       -- sales reps = employees 6,12,...,120
       d.OrderDate,
       s.Status,
       a.AddressId,
       CASE WHEN nm.n % 6 = 0 THEN ((nm.n / 6) % 12) + 1 END,
       CAST(CASE WHEN nm.n % 4 = 0 THEN 0 ELSE 5 + (nm.n % 4) * 2.5 END AS DECIMAL(8,2))
FROM #Nums nm
CROSS APPLY (SELECT CASE WHEN nm.n % 10 = 0 THEN (nm.n / 10) % 50 + 1        -- 50 "VIP" customers order more
                         ELSE (nm.n * 37) % 4700 + 1 END AS CustomerId) x
CROSS APPLY (SELECT DATEADD(MINUTE, -((nm.n * 53) % 1051200), CAST('2026-06-30T18:00:00' AS DATETIME2(0))) AS OrderDate) d
CROSS APPLY (SELECT CASE WHEN d.OrderDate > '2026-06-20'
                         THEN CHOOSE(nm.n % 3 + 1, 'Pending','Paid','Shipped')
                         ELSE CHOOSE(nm.n % 10 + 1, 'Delivered','Delivered','Delivered','Delivered','Delivered',
                                                    'Delivered','Delivered','Cancelled','Returned','Shipped') END AS Status) s
JOIN Sales.CustomerAddresses a ON a.CustomerId = x.CustomerId AND a.IsDefault = 1
WHERE nm.n <= 20000
ORDER BY nm.n;

-- customers cannot order before they registered
UPDATE c SET RegisteredAt = DATEADD(DAY, -(c.CustomerId % 10), m.FirstOrder)
FROM Sales.Customers c
JOIN (SELECT CustomerId, MIN(OrderDate) AS FirstOrder FROM Sales.Orders GROUP BY CustomerId) m ON m.CustomerId = c.CustomerId
WHERE c.RegisteredAt > m.FirstOrder;

-- 1..5 lines per order (products 281..300 are never ordered)
INSERT Sales.OrderItems (OrderId, ProductId, Quantity, UnitPrice, DiscountPercent)
SELECT o.OrderId, p.ProductId,
       1 + (o.OrderId + k.n * 3) % 4,
       CAST(p.UnitPrice * CASE WHEN o.OrderId % 7 = 0 THEN 0.90 ELSE 1 END AS DECIMAL(10,2)),
       CAST(CASE WHEN (o.OrderId + k.n) % 9 = 0 THEN 10 WHEN (o.OrderId + k.n) % 13 = 0 THEN 15 ELSE 0 END AS DECIMAL(5,2))
FROM Sales.Orders o
JOIN (SELECT n FROM #Nums WHERE n <= 5) k ON k.n <= 1 + o.OrderId % 5
JOIN Catalog.Products p ON p.ProductId = ((o.OrderId * 13 + k.n * 59) % 280) + 1
ORDER BY o.OrderId, k.n;

-- one payment per non-pending order (cancelled: only half of them tried & failed)
INSERT Sales.Payments (OrderId, PaymentDate, Amount, Method, Status)
SELECT o.OrderId,
       DATEADD(MINUTE, 5 + o.OrderId % 120, o.OrderDate),
       CAST(t.ItemsTotal * (1 - ISNULL(cp.DiscountPercent, 0) / 100.0) + o.ShippingFee AS DECIMAL(12,2)),
       CHOOSE(o.OrderId % 4 + 1, 'CreditCard','Cash','Wallet','BankTransfer'),
       CASE o.Status WHEN 'Returned' THEN 'Refunded' WHEN 'Cancelled' THEN 'Failed' ELSE 'Completed' END
FROM Sales.Orders o
LEFT JOIN Sales.Coupons cp ON cp.CouponId = o.CouponId
CROSS APPLY (SELECT SUM(oi.Quantity * oi.UnitPrice * (1 - oi.DiscountPercent / 100.0)) AS ItemsTotal
             FROM Sales.OrderItems oi WHERE oi.OrderId = o.OrderId) t
WHERE o.Status <> 'Pending' AND (o.Status <> 'Cancelled' OR o.OrderId % 2 = 0);

-- data-quality quirk: some payments are 5% short
UPDATE Sales.Payments SET Amount = CAST(Amount * 0.95 AS DECIMAL(12,2))
WHERE OrderId % 400 = 0 AND Status = 'Completed';

-- shipments for shipped / delivered / returned orders
INSERT Sales.Shipments (OrderId, WarehouseId, ShippedDate, DeliveredDate, Carrier, TrackingNo)
SELECT o.OrderId,
       o.OrderId % 8 + 1,
       sd.ShippedDate,
       CASE WHEN o.Status = 'Shipped' THEN NULL ELSE DATEADD(DAY, 1 + o.OrderId % 6, sd.ShippedDate) END,
       CHOOSE(o.OrderId % 4 + 1, 'Aramex','DHL','FedEx','UPS'),
       CONCAT('TRK', RIGHT(CONCAT('0000000000', o.OrderId), 10))
FROM Sales.Orders o
CROSS APPLY (SELECT DATEADD(HOUR, 12 + o.OrderId % 48, o.OrderDate) AS ShippedDate) sd
WHERE o.Status IN ('Shipped','Delivered','Returned');

-- reviews: only for delivered orders, one per (product, customer)
;WITH r AS (
    SELECT oi.ProductId, o.CustomerId, oi.OrderItemId, o.OrderDate,
           ROW_NUMBER() OVER (PARTITION BY oi.ProductId, o.CustomerId ORDER BY oi.OrderItemId) AS rn
    FROM Sales.OrderItems oi
    JOIN Sales.Orders o ON o.OrderId = oi.OrderId
    WHERE o.Status = 'Delivered' AND oi.OrderItemId % 6 = 0 AND o.OrderDate < '2026-06-01'
)
INSERT Sales.Reviews (ProductId, CustomerId, Rating, Comment, ReviewDate)
SELECT r.ProductId, r.CustomerId, x.Rating,
       CASE WHEN r.OrderItemId % 4 = 0 THEN NULL
            WHEN x.Rating >= 4 THEN N'Great quality, arrived on time.'
            WHEN x.Rating = 3  THEN N'Okay for the price.'
            ELSE N'Not as described, disappointed.' END,
       DATEADD(DAY, 3 + r.OrderItemId % 20, r.OrderDate)
FROM r
CROSS APPLY (SELECT CHOOSE(r.OrderItemId % 10 + 1, 5,4,5,3,4,5,2,4,1,5) AS Rating) x
WHERE r.rn = 1;

-- cleanup helpers
DROP TABLE #Nums;
DROP TABLE #First;
DROP TABLE #Last;
DROP TABLE #Leaf;
GO

/* ============================ SANITY CHECK ============================ */
SELECT 'Geo.Countries' AS TableName, COUNT(*) AS Rows FROM Geo.Countries UNION ALL
SELECT 'Geo.Cities',            COUNT(*) FROM Geo.Cities            UNION ALL
SELECT 'HR.Departments',        COUNT(*) FROM HR.Departments        UNION ALL
SELECT 'HR.Employees',          COUNT(*) FROM HR.Employees          UNION ALL
SELECT 'Catalog.Categories',    COUNT(*) FROM Catalog.Categories    UNION ALL
SELECT 'Catalog.Brands',        COUNT(*) FROM Catalog.Brands        UNION ALL
SELECT 'Catalog.Suppliers',     COUNT(*) FROM Catalog.Suppliers     UNION ALL
SELECT 'Catalog.Products',      COUNT(*) FROM Catalog.Products      UNION ALL
SELECT 'Catalog.ProductSuppliers', COUNT(*) FROM Catalog.ProductSuppliers UNION ALL
SELECT 'Inv.Warehouses',        COUNT(*) FROM Inv.Warehouses        UNION ALL
SELECT 'Inv.Stock',             COUNT(*) FROM Inv.Stock             UNION ALL
SELECT 'Sales.Customers',       COUNT(*) FROM Sales.Customers       UNION ALL
SELECT 'Sales.CustomerAddresses', COUNT(*) FROM Sales.CustomerAddresses UNION ALL
SELECT 'Sales.Coupons',         COUNT(*) FROM Sales.Coupons         UNION ALL
SELECT 'Sales.Orders',          COUNT(*) FROM Sales.Orders          UNION ALL
SELECT 'Sales.OrderItems',      COUNT(*) FROM Sales.OrderItems      UNION ALL
SELECT 'Sales.Payments',        COUNT(*) FROM Sales.Payments        UNION ALL
SELECT 'Sales.Shipments',       COUNT(*) FROM Sales.Shipments       UNION ALL
SELECT 'Sales.Reviews',         COUNT(*) FROM Sales.Reviews;
GO
