-- ============================================================
-- CPSC 4576 Database Project
-- E-Commerce Online Store Database
-- Team: [Your Names Here]
-- Date: May 2026
-- ============================================================

USE master;
GO

IF EXISTS (SELECT name FROM sys.databases WHERE name = 'ECommerceDB')
    DROP DATABASE ECommerceDB;
GO

CREATE DATABASE ECommerceDB;
GO

USE ECommerceDB;
GO

-- ============================================================
-- SECTION 1: TABLE CREATION
-- ============================================================

-- Table 1: Customers
CREATE TABLE Customers (
    CustomerID   INT PRIMARY KEY IDENTITY(1,1),
    FirstName    NVARCHAR(50)  NOT NULL,
    LastName     NVARCHAR(50)  NOT NULL,
    Email        NVARCHAR(100) NOT NULL UNIQUE,
    Phone        NVARCHAR(20),
    Address      NVARCHAR(200),
    City         NVARCHAR(50),
    State        NVARCHAR(50),
    ZipCode      NVARCHAR(10),
    CreatedAt    DATETIME      DEFAULT GETDATE(),
    IsActive     BIT           DEFAULT 1,
    CONSTRAINT chk_email CHECK (Email LIKE '%@%.%')
);
GO

-- Table 2: Categories
CREATE TABLE Categories (
    CategoryID   INT PRIMARY KEY IDENTITY(1,1),
    CategoryName NVARCHAR(100) NOT NULL UNIQUE,
    Description  NVARCHAR(500),
    ParentCategoryID INT FOREIGN KEY REFERENCES Categories(CategoryID)
);
GO

-- Table 3: Products
CREATE TABLE Products (
    ProductID    INT PRIMARY KEY IDENTITY(1,1),
    ProductName  NVARCHAR(200) NOT NULL,
    CategoryID   INT           NOT NULL FOREIGN KEY REFERENCES Categories(CategoryID),
    Price        DECIMAL(10,2) NOT NULL,
    StockQty     INT           NOT NULL DEFAULT 0,
    SKU          NVARCHAR(50)  NOT NULL UNIQUE,
    Description  NVARCHAR(1000),
    IsActive     BIT           DEFAULT 1,
    CreatedAt    DATETIME      DEFAULT GETDATE(),
    CONSTRAINT chk_price    CHECK (Price >= 0),
    CONSTRAINT chk_stockqty CHECK (StockQty >= 0)
);
GO

-- Table 4: Orders
CREATE TABLE Orders (
    OrderID      INT PRIMARY KEY IDENTITY(1,1),
    CustomerID   INT           NOT NULL FOREIGN KEY REFERENCES Customers(CustomerID),
    OrderDate    DATETIME      DEFAULT GETDATE(),
    Status       NVARCHAR(20)  NOT NULL DEFAULT 'Pending',
    TotalAmount  DECIMAL(10,2) NOT NULL DEFAULT 0,
    ShipAddress  NVARCHAR(200),
    ShipCity     NVARCHAR(50),
    ShipState    NVARCHAR(50),
    ShipZip      NVARCHAR(10),
    Notes        NVARCHAR(500),
    CONSTRAINT chk_status CHECK (Status IN ('Pending','Processing','Shipped','Delivered','Cancelled')),
    CONSTRAINT chk_total  CHECK (TotalAmount >= 0)
);
GO

-- Table 5: OrderItems
CREATE TABLE OrderItems (
    OrderItemID  INT PRIMARY KEY IDENTITY(1,1),
    OrderID      INT            NOT NULL FOREIGN KEY REFERENCES Orders(OrderID),
    ProductID    INT            NOT NULL FOREIGN KEY REFERENCES Products(ProductID),
    Quantity     INT            NOT NULL,
    UnitPrice    DECIMAL(10,2)  NOT NULL,
    Discount     DECIMAL(5,2)   DEFAULT 0,
    CONSTRAINT chk_qty      CHECK (Quantity > 0),
    CONSTRAINT chk_unitprice CHECK (UnitPrice >= 0),
    CONSTRAINT chk_discount  CHECK (Discount >= 0 AND Discount <= 100)
);
GO

-- Table 6: Reviews (bonus table for richer schema)
CREATE TABLE Reviews (
    ReviewID     INT PRIMARY KEY IDENTITY(1,1),
    ProductID    INT NOT NULL FOREIGN KEY REFERENCES Products(ProductID),
    CustomerID   INT NOT NULL FOREIGN KEY REFERENCES Customers(CustomerID),
    Rating       INT NOT NULL,
    ReviewText   NVARCHAR(1000),
    ReviewDate   DATETIME DEFAULT GETDATE(),
    CONSTRAINT chk_rating CHECK (Rating BETWEEN 1 AND 5)
);
GO

-- ============================================================
-- SECTION 2: INDEXES
-- ============================================================

CREATE INDEX idx_orders_customer   ON Orders(CustomerID);
CREATE INDEX idx_orderitems_order  ON OrderItems(OrderID);
CREATE INDEX idx_orderitems_product ON OrderItems(ProductID);
CREATE INDEX idx_products_category ON Products(CategoryID);
CREATE INDEX idx_customers_email   ON Customers(Email);
GO

-- ============================================================
-- SECTION 3: DATA INSERTION
-- ============================================================

-- Insert Categories
INSERT INTO Categories (CategoryName, Description, ParentCategoryID) VALUES
('Electronics',   'Electronic devices and accessories', NULL),
('Clothing',      'Apparel and fashion items',          NULL),
('Books',         'Physical and digital books',         NULL),
('Home & Garden', 'Home decor and garden tools',        NULL),
('Sports',        'Sports and outdoor equipment',       NULL);

INSERT INTO Categories (CategoryName, Description, ParentCategoryID) VALUES
('Laptops',       'Portable computers',    1),
('Smartphones',   'Mobile phones',         1),
('Men''s Wear',   'Clothing for men',      2),
('Women''s Wear', 'Clothing for women',    2);
GO

-- Insert Customers
INSERT INTO Customers (FirstName, LastName, Email, Phone, Address, City, State, ZipCode) VALUES
('James',   'Carter',   'james.carter@email.com',   '312-555-0101', '123 Oak St',    'Chicago',     'IL', '60601'),
('Sofia',   'Nguyen',   'sofia.nguyen@email.com',   '312-555-0102', '456 Maple Ave', 'Chicago',     'IL', '60602'),
('Marcus',  'Johnson',  'marcus.j@email.com',        '708-555-0103', '789 Pine Rd',   'Evanston',    'IL', '60201'),
('Priya',   'Patel',    'priya.patel@email.com',    '847-555-0104', '321 Elm Dr',    'Naperville',  'IL', '60540'),
('Tyler',   'Brooks',   'tyler.brooks@email.com',   '773-555-0105', '654 Cedar Ln',  'Oak Park',    'IL', '60301'),
('Amara',   'Williams', 'amara.w@email.com',         '312-555-0106', '987 Birch Blvd','Chicago',    'IL', '60605'),
('Liam',    'O''Brien',  'liam.obrien@email.com',   '630-555-0107', '111 Walnut St', 'Aurora',      'IL', '60505'),
('Hannah',  'Kim',      'hannah.kim@email.com',     '312-555-0108', '222 Spruce Ave','Chicago',     'IL', '60607');
GO

-- Insert Products
INSERT INTO Products (ProductName, CategoryID, Price, StockQty, SKU, Description) VALUES
('Dell Inspiron 15 Laptop',    6,  799.99, 25,  'DELL-INS-15',  '15.6-inch laptop, Intel i5, 8GB RAM, 256GB SSD'),
('Apple MacBook Air M2',       6, 1099.99, 15,  'APPLE-MBA-M2', '13-inch MacBook Air with M2 chip, 8GB, 256GB'),
('Samsung Galaxy S24',         7,  899.99, 40,  'SAM-S24',      'Android smartphone, 6.2-inch AMOLED, 128GB'),
('iPhone 15 Pro',              7, 1199.99, 20,  'APL-IP15P',    'Apple iPhone 15 Pro, 256GB, Titanium'),
('Men''s Running Shoes',       5,   89.99, 60,  'MRS-001',      'Lightweight running shoes, size 8-14'),
('Women''s Yoga Pants',        9,   49.99, 80,  'WYP-002',      'High-waist yoga pants, multiple colors'),
('Men''s Classic T-Shirt',     8,   24.99, 120, 'MCT-003',      '100% cotton crew neck tee, S-XXL'),
('Python Programming Book',    3,   44.99, 35,  'BOOK-PY3',     'Learn Python 3 from scratch, 2nd Edition'),
('The Art of SQL',             3,   39.99, 30,  'BOOK-SQL',     'Advanced SQL query optimization guide'),
('Ergonomic Office Chair',     4,  299.99, 10,  'CHAIR-ERG-1',  'Lumbar support, adjustable armrests'),
('Wireless Noise-Cancel Headphones', 1, 149.99, 50, 'WNC-HP01','Bluetooth 5.3, 30hr battery, ANC'),
('4K HDMI Cable 6ft',          1,   19.99, 200, 'HDMI-4K-6',    '4K@60Hz, braided, compatible with all devices');
GO

-- Insert Orders
INSERT INTO Orders (CustomerID, OrderDate, Status, TotalAmount, ShipAddress, ShipCity, ShipState, ShipZip) VALUES
(1, '2026-04-01', 'Delivered',   1699.98, '123 Oak St',    'Chicago',    'IL', '60601'),
(2, '2026-04-05', 'Delivered',    989.98, '456 Maple Ave', 'Chicago',    'IL', '60602'),
(3, '2026-04-10', 'Shipped',      364.97, '789 Pine Rd',   'Evanston',   'IL', '60201'),
(4, '2026-04-15', 'Processing',  1099.99, '321 Elm Dr',    'Naperville', 'IL', '60540'),
(5, '2026-04-20', 'Pending',       74.98, '654 Cedar Ln',  'Oak Park',   'IL', '60301'),
(6, '2026-04-22', 'Delivered',    449.97, '987 Birch Blvd','Chicago',    'IL', '60605'),
(1, '2026-04-28', 'Shipped',      299.99, '123 Oak St',    'Chicago',    'IL', '60601'),
(7, '2026-05-01', 'Pending',      899.99, '111 Walnut St', 'Aurora',     'IL', '60505');
GO

-- Insert OrderItems
INSERT INTO OrderItems (OrderID, ProductID, Quantity, UnitPrice, Discount) VALUES
(1, 1,  1, 799.99, 0),
(1, 11, 1, 899.99, 0),
(2, 3,  1, 899.99, 0),
(2, 7,  2,  24.99, 0),
(3, 8,  1,  44.99, 0),
(3, 9,  1,  39.99, 0),
(3, 12, 1,  19.99, 0),
(3, 7,  1,  24.99, 0),
(4, 2,  1,1099.99, 0),
(5, 5,  1,  49.99, 0),
(5, 6,  1,  24.99, 0),
(6, 10, 1, 299.99, 0),
(6, 11, 1, 149.99, 0),
(7, 10, 1, 299.99, 0),
(8, 3,  1, 899.99, 0);
GO

-- Insert Reviews
INSERT INTO Reviews (ProductID, CustomerID, Rating, ReviewText) VALUES
(1, 1, 5, 'Great laptop for the price. Fast and reliable.'),
(3, 2, 4, 'Excellent phone but battery could be better.'),
(8, 3, 5, 'Best Python book I have read. Very comprehensive.'),
(10,6, 4, 'Very comfortable chair. Easy to assemble.'),
(2, 4, 5, 'MacBook M2 is incredibly fast. Love it!'),
(11,1, 5, 'Outstanding noise cancellation. Worth every penny.'),
(9, 3, 4, 'Good SQL book, lots of practical examples.'),
(5, 5, 3, 'Good shoes but sizing runs small. Order a half size up.');
GO

-- ============================================================
-- SECTION 4: VIEWS
-- ============================================================

-- View 1: Customer Order Summary
CREATE VIEW vw_CustomerOrderSummary AS
    SELECT
        c.CustomerID,
        c.FirstName + ' ' + c.LastName AS CustomerName,
        c.Email,
        COUNT(o.OrderID)               AS TotalOrders,
        SUM(o.TotalAmount)             AS TotalSpent,
        MAX(o.OrderDate)               AS LastOrderDate
    FROM Customers c
    LEFT JOIN Orders o ON c.CustomerID = o.CustomerID
    GROUP BY c.CustomerID, c.FirstName, c.LastName, c.Email;
GO

-- View 2: Product Sales Performance
CREATE VIEW vw_ProductSalesPerformance AS
    SELECT
        p.ProductID,
        p.ProductName,
        cat.CategoryName,
        p.Price,
        p.StockQty,
        COALESCE(SUM(oi.Quantity), 0)               AS TotalUnitsSold,
        COALESCE(SUM(oi.Quantity * oi.UnitPrice), 0) AS TotalRevenue,
        COALESCE(AVG(CAST(r.Rating AS FLOAT)), 0)    AS AvgRating
    FROM Products p
    JOIN Categories cat  ON p.CategoryID = cat.CategoryID
    LEFT JOIN OrderItems oi ON p.ProductID = oi.ProductID
    LEFT JOIN Reviews r     ON p.ProductID = r.ProductID
    GROUP BY p.ProductID, p.ProductName, cat.CategoryName, p.Price, p.StockQty;
GO

-- View 3: Order Detail Report
CREATE VIEW vw_OrderDetailReport AS
    SELECT
        o.OrderID,
        o.OrderDate,
        o.Status,
        c.FirstName + ' ' + c.LastName AS CustomerName,
        c.Email,
        p.ProductName,
        oi.Quantity,
        oi.UnitPrice,
        oi.Discount,
        (oi.Quantity * oi.UnitPrice * (1 - oi.Discount/100)) AS LineTotal
    FROM Orders o
    JOIN Customers   c  ON o.CustomerID  = c.CustomerID
    JOIN OrderItems  oi ON o.OrderID     = oi.OrderID
    JOIN Products    p  ON oi.ProductID  = p.ProductID;
GO

-- ============================================================
-- SECTION 5: STORED PROCEDURES
-- ============================================================

-- Stored Procedure 1: Place a new order
CREATE PROCEDURE sp_PlaceOrder
    @CustomerID  INT,
    @ProductID   INT,
    @Quantity    INT,
    @NewOrderID  INT OUTPUT
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @Price    DECIMAL(10,2);
    DECLARE @Stock    INT;
    DECLARE @Total    DECIMAL(10,2);

    -- Get product price and stock
    SELECT @Price = Price, @Stock = StockQty
    FROM Products
    WHERE ProductID = @ProductID AND IsActive = 1;

    IF @Price IS NULL
    BEGIN
        RAISERROR('Product not found or inactive.', 16, 1);
        RETURN;
    END

    IF @Stock < @Quantity
    BEGIN
        RAISERROR('Insufficient stock.', 16, 1);
        RETURN;
    END

    SET @Total = @Price * @Quantity;

    -- Create order
    INSERT INTO Orders (CustomerID, Status, TotalAmount)
    VALUES (@CustomerID, 'Pending', @Total);

    SET @NewOrderID = SCOPE_IDENTITY();

    -- Insert order item
    INSERT INTO OrderItems (OrderID, ProductID, Quantity, UnitPrice)
    VALUES (@NewOrderID, @ProductID, @Quantity, @Price);

    -- Reduce stock
    UPDATE Products
    SET StockQty = StockQty - @Quantity
    WHERE ProductID = @ProductID;
END;
GO

-- Stored Procedure 2: Get customer order history
CREATE PROCEDURE sp_GetCustomerOrders
    @CustomerID    INT,
    @OrderCount    INT OUTPUT,
    @TotalSpent    DECIMAL(10,2) OUTPUT
AS
BEGIN
    SET NOCOUNT ON;

    SELECT
        o.OrderID,
        o.OrderDate,
        o.Status,
        o.TotalAmount,
        p.ProductName,
        oi.Quantity,
        oi.UnitPrice
    FROM Orders o
    JOIN OrderItems oi ON o.OrderID  = oi.OrderID
    JOIN Products   p  ON oi.ProductID = p.ProductID
    WHERE o.CustomerID = @CustomerID
    ORDER BY o.OrderDate DESC;

    SELECT @OrderCount = COUNT(*),
           @TotalSpent = COALESCE(SUM(TotalAmount), 0)
    FROM Orders
    WHERE CustomerID = @CustomerID;
END;
GO

-- Stored Procedure 3: Update order status
CREATE PROCEDURE sp_UpdateOrderStatus
    @OrderID    INT,
    @NewStatus  NVARCHAR(20),
    @Success    BIT OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    SET @Success = 0;

    IF @NewStatus NOT IN ('Pending','Processing','Shipped','Delivered','Cancelled')
    BEGIN
        RAISERROR('Invalid status value.', 16, 1);
        RETURN;
    END

    UPDATE Orders
    SET Status = @NewStatus
    WHERE OrderID = @OrderID;

    IF @@ROWCOUNT > 0
        SET @Success = 1;
END;
GO

-- ============================================================
-- SECTION 6: FUNCTIONS
-- ============================================================

-- Function 1: Calculate discounted price
CREATE FUNCTION fn_GetDiscountedPrice
(
    @ProductID   INT,
    @DiscountPct DECIMAL(5,2)
)
RETURNS DECIMAL(10,2)
AS
BEGIN
    DECLARE @Price DECIMAL(10,2);

    SELECT @Price = Price
    FROM Products
    WHERE ProductID = @ProductID;

    IF @Price IS NULL
        RETURN NULL;

    RETURN ROUND(@Price * (1 - @DiscountPct / 100), 2);
END;
GO

-- Function 2: Get total revenue for a category
CREATE FUNCTION fn_GetCategoryRevenue
(
    @CategoryID INT
)
RETURNS DECIMAL(12,2)
AS
BEGIN
    DECLARE @Revenue DECIMAL(12,2);

    SELECT @Revenue = SUM(oi.Quantity * oi.UnitPrice)
    FROM OrderItems oi
    JOIN Products   p  ON oi.ProductID  = p.ProductID
    JOIN Orders     o  ON oi.OrderID    = o.OrderID
    WHERE p.CategoryID = @CategoryID
      AND o.Status <> 'Cancelled';

    RETURN COALESCE(@Revenue, 0);
END;
GO

-- Function 3: Get customer loyalty tier
CREATE FUNCTION fn_GetCustomerTier
(
    @CustomerID INT
)
RETURNS NVARCHAR(20)
AS
BEGIN
    DECLARE @TotalSpent DECIMAL(10,2);
    DECLARE @Tier NVARCHAR(20);

    SELECT @TotalSpent = COALESCE(SUM(TotalAmount), 0)
    FROM Orders
    WHERE CustomerID = @CustomerID
      AND Status <> 'Cancelled';

    SET @Tier =
        CASE
            WHEN @TotalSpent >= 2000 THEN 'Platinum'
            WHEN @TotalSpent >= 1000 THEN 'Gold'
            WHEN @TotalSpent >= 500  THEN 'Silver'
            ELSE                          'Bronze'
        END;

    RETURN @Tier;
END;
GO

-- ============================================================
-- SECTION 7: TRIGGERS
-- ============================================================

-- Trigger 1: Recalculate order total when an item is inserted
CREATE TRIGGER trg_OrderItems_AfterInsert
ON OrderItems
AFTER INSERT
AS
BEGIN
    SET NOCOUNT ON;

    UPDATE Orders
    SET TotalAmount = (
        SELECT COALESCE(SUM(Quantity * UnitPrice * (1 - Discount/100)), 0)
        FROM OrderItems
        WHERE OrderID = inserted.OrderID
    )
    FROM Orders
    INNER JOIN inserted ON Orders.OrderID = inserted.OrderID;
END;
GO

-- Trigger 2: Prevent deleting a customer who has orders
CREATE TRIGGER trg_Customers_PreventDelete
ON Customers
INSTEAD OF DELETE
AS
BEGIN
    SET NOCOUNT ON;

    IF EXISTS (
        SELECT 1 FROM Orders o
        INNER JOIN deleted d ON o.CustomerID = d.CustomerID
    )
    BEGIN
        RAISERROR('Cannot delete customer with existing orders. Deactivate instead.', 16, 1);
        ROLLBACK TRANSACTION;
        RETURN;
    END

    DELETE FROM Customers
    WHERE CustomerID IN (SELECT CustomerID FROM deleted);
END;
GO

-- Trigger 3: Log low stock warning after product update
CREATE TABLE StockAlerts (
    AlertID    INT PRIMARY KEY IDENTITY(1,1),
    ProductID  INT,
    ProductName NVARCHAR(200),
    StockQty   INT,
    AlertTime  DATETIME DEFAULT GETDATE()
);
GO

CREATE TRIGGER trg_Products_LowStock
ON Products
AFTER UPDATE
AS
BEGIN
    SET NOCOUNT ON;

    INSERT INTO StockAlerts (ProductID, ProductName, StockQty)
    SELECT i.ProductID, i.ProductName, i.StockQty
    FROM inserted i
    WHERE i.StockQty < 5;
END;
GO

-- ============================================================
-- SECTION 8: TESTING
-- ============================================================

-- 8.1 Test Stored Procedures

-- Test sp_PlaceOrder
DECLARE @NewOrderID INT;
EXEC sp_PlaceOrder
    @CustomerID = 2,
    @ProductID  = 12,
    @Quantity   = 3,
    @NewOrderID = @NewOrderID OUTPUT;
SELECT @NewOrderID AS NewOrderID;
GO

-- Test sp_GetCustomerOrders
DECLARE @Count INT, @Spent DECIMAL(10,2);
EXEC sp_GetCustomerOrders
    @CustomerID = 1,
    @OrderCount = @Count OUTPUT,
    @TotalSpent = @Spent OUTPUT;
SELECT @Count AS TotalOrders, @Spent AS TotalSpent;
GO

-- Test sp_UpdateOrderStatus
DECLARE @OK BIT;
EXEC sp_UpdateOrderStatus
    @OrderID   = 5,
    @NewStatus = 'Processing',
    @Success   = @OK OUTPUT;
SELECT @OK AS UpdateSuccess;
GO

-- 8.2 Test Functions

-- fn_GetDiscountedPrice: 10% discount on product 1
SELECT dbo.fn_GetDiscountedPrice(1, 10) AS DiscountedPrice;
GO

-- fn_GetCategoryRevenue: Revenue for Electronics (CategoryID = 1)
SELECT dbo.fn_GetCategoryRevenue(1) AS ElectronicsRevenue;
GO

-- fn_GetCustomerTier: Tier for Customer 1
SELECT dbo.fn_GetCustomerTier(1) AS LoyaltyTier;
GO

-- 8.3 Test Triggers

-- Trigger 1: Insert an order item and verify order total updates
INSERT INTO OrderItems (OrderID, ProductID, Quantity, UnitPrice)
VALUES (5, 7, 2, 24.99);
SELECT OrderID, TotalAmount FROM Orders WHERE OrderID = 5;
GO

-- Trigger 2: Attempt to delete a customer with orders (should raise error)
BEGIN TRY
    DELETE FROM Customers WHERE CustomerID = 1;
END TRY
BEGIN CATCH
    PRINT ERROR_MESSAGE();
END CATCH;
GO

-- Trigger 3: Reduce stock below 5 to fire low stock alert
UPDATE Products SET StockQty = 3 WHERE ProductID = 10;
SELECT * FROM StockAlerts;
GO

-- ============================================================
-- VERIFY VIEWS
-- ============================================================

SELECT * FROM vw_CustomerOrderSummary      ORDER BY TotalSpent DESC;
SELECT * FROM vw_ProductSalesPerformance   ORDER BY TotalRevenue DESC;
SELECT * FROM vw_OrderDetailReport         ORDER BY OrderDate DESC;
GO
