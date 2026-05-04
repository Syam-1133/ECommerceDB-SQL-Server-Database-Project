# ECommerceDB — SQL Server Database Project

**Project:** E-Commerce Online Store Database  
**Platform:** Microsoft SQL Server (T-SQL / SSMS)  
**Date:** May 2026

---

## Overview

ECommerceDB is a fully functional relational database that simulates a real-world e-commerce platform. It covers the complete lifecycle of an online store — from browsing products and placing orders to tracking shipments and rewarding loyal customers.

The database is built entirely in T-SQL and demonstrates:
- Normalized table design with foreign key relationships
- Performance tuning with indexes
- Business logic encapsulated in stored procedures and functions
- Automation and data integrity enforced by triggers
- Reporting through views

---

## Database Schema

### Entity-Relationship Summary

```
Categories (self-referencing for subcategories)
    └── Products
            └── OrderItems ──┐
                             ├── Orders ── Customers
            └── Reviews ─────┘
```

---

### Tables

#### 1. `Customers`
Stores registered customer accounts.

| Column | Type | Notes |
|---|---|---|
| CustomerID | INT | Primary Key, auto-increment |
| FirstName | NVARCHAR(50) | Required |
| LastName | NVARCHAR(50) | Required |
| Email | NVARCHAR(100) | Required, Unique, must match `%@%.%` format |
| Phone | NVARCHAR(20) | Optional |
| Address / City / State / ZipCode | NVARCHAR | Shipping address fields |
| CreatedAt | DATETIME | Defaults to current timestamp |
| IsActive | BIT | 1 = active, 0 = deactivated |

---

#### 2. `Categories`
Supports a two-level hierarchy (parent → child categories).

| Column | Type | Notes |
|---|---|---|
| CategoryID | INT | Primary Key |
| CategoryName | NVARCHAR(100) | Unique |
| Description | NVARCHAR(500) | Optional |
| ParentCategoryID | INT | Self-referencing FK — NULL means top-level |

**Top-level categories:** Electronics, Clothing, Books, Home & Garden, Sports  
**Sub-categories:** Laptops, Smartphones (under Electronics), Men's Wear, Women's Wear (under Clothing)

---

#### 3. `Products`
The product catalog.

| Column | Type | Notes |
|---|---|---|
| ProductID | INT | Primary Key |
| ProductName | NVARCHAR(200) | Required |
| CategoryID | INT | FK → Categories |
| Price | DECIMAL(10,2) | Must be ≥ 0 |
| StockQty | INT | Must be ≥ 0, defaults to 0 |
| SKU | NVARCHAR(50) | Stock Keeping Unit, Unique |
| Description | NVARCHAR(1000) | Optional |
| IsActive | BIT | Soft delete flag |

---

#### 4. `Orders`
Tracks customer orders and their fulfillment status.

| Column | Type | Notes |
|---|---|---|
| OrderID | INT | Primary Key |
| CustomerID | INT | FK → Customers |
| OrderDate | DATETIME | Defaults to now |
| Status | NVARCHAR(20) | One of: `Pending`, `Processing`, `Shipped`, `Delivered`, `Cancelled` |
| TotalAmount | DECIMAL(10,2) | Auto-updated by trigger |
| ShipAddress / ShipCity / ShipState / ShipZip | NVARCHAR | Delivery address |
| Notes | NVARCHAR(500) | Optional order notes |

---

#### 5. `OrderItems`
Line items within each order (many-to-many bridge between Orders and Products).

| Column | Type | Notes |
|---|---|---|
| OrderItemID | INT | Primary Key |
| OrderID | INT | FK → Orders |
| ProductID | INT | FK → Products |
| Quantity | INT | Must be > 0 |
| UnitPrice | DECIMAL(10,2) | Price at time of purchase |
| Discount | DECIMAL(5,2) | Percentage discount (0–100), defaults to 0 |

---

#### 6. `Reviews`
Customer product reviews.

| Column | Type | Notes |
|---|---|---|
| ReviewID | INT | Primary Key |
| ProductID | INT | FK → Products |
| CustomerID | INT | FK → Customers |
| Rating | INT | 1 to 5 stars (enforced by CHECK constraint) |
| ReviewText | NVARCHAR(1000) | Optional written review |
| ReviewDate | DATETIME | Defaults to now |

---

#### 7. `StockAlerts` (auto-created by trigger)
Audit log of low stock events. Automatically populated when a product's stock drops below 5 units.

| Column | Type | Notes |
|---|---|---|
| AlertID | INT | Primary Key |
| ProductID | INT | Which product triggered the alert |
| ProductName | NVARCHAR(200) | Snapshot of product name |
| StockQty | INT | Stock level at alert time |
| AlertTime | DATETIME | When the alert was logged |

---

## Indexes

Five indexes are created to speed up common query patterns:

| Index Name | Table | Column | Purpose |
|---|---|---|---|
| idx_orders_customer | Orders | CustomerID | Look up all orders for a customer |
| idx_orderitems_order | OrderItems | OrderID | Fetch all items in an order |
| idx_orderitems_product | OrderItems | ProductID | Find all orders containing a product |
| idx_products_category | Products | CategoryID | Filter products by category |
| idx_customers_email | Customers | Email | Fast email lookup / login |

---

## Views

Pre-built reports that combine multiple tables into easy-to-query snapshots.

### `vw_CustomerOrderSummary`
Aggregates each customer's order activity.

**Columns returned:** CustomerID, CustomerName, Email, TotalOrders, TotalSpent, LastOrderDate

```sql
SELECT * FROM vw_CustomerOrderSummary ORDER BY TotalSpent DESC;
```

---

### `vw_ProductSalesPerformance`
Shows how well each product is selling, including average rating.

**Columns returned:** ProductID, ProductName, CategoryName, Price, StockQty, TotalUnitsSold, TotalRevenue, AvgRating

```sql
SELECT * FROM vw_ProductSalesPerformance ORDER BY TotalRevenue DESC;
```

---

### `vw_OrderDetailReport`
Full order details — customer info, product info, quantities, and calculated line totals with discounts applied.

**Columns returned:** OrderID, OrderDate, Status, CustomerName, Email, ProductName, Quantity, UnitPrice, Discount, LineTotal

```sql
SELECT * FROM vw_OrderDetailReport ORDER BY OrderDate DESC;
```

---

## Stored Procedures

Reusable business logic blocks that perform multi-step operations safely.

### `sp_PlaceOrder`
Places a single-product order for a customer. Validates stock availability and automatically deducts inventory.

**Parameters:**

| Parameter | Direction | Type | Description |
|---|---|---|---|
| @CustomerID | IN | INT | The customer placing the order |
| @ProductID | IN | INT | The product to order |
| @Quantity | IN | INT | How many units |
| @NewOrderID | OUT | INT | Returns the newly created OrderID |

**Usage:**
```sql
DECLARE @NewOrderID INT;
EXEC sp_PlaceOrder
    @CustomerID = 2,
    @ProductID  = 12,
    @Quantity   = 3,
    @NewOrderID = @NewOrderID OUTPUT;
SELECT @NewOrderID AS NewOrderID;
```

---

### `sp_GetCustomerOrders`
Retrieves full order history for a customer and returns summary stats.

**Parameters:**

| Parameter | Direction | Type | Description |
|---|---|---|---|
| @CustomerID | IN | INT | Customer to query |
| @OrderCount | OUT | INT | Total number of orders placed |
| @TotalSpent | OUT | DECIMAL | Total amount spent across all orders |

**Usage:**
```sql
DECLARE @Count INT, @Spent DECIMAL(10,2);
EXEC sp_GetCustomerOrders
    @CustomerID = 1,
    @OrderCount = @Count OUTPUT,
    @TotalSpent = @Spent OUTPUT;
SELECT @Count AS TotalOrders, @Spent AS TotalSpent;
```

---

### `sp_UpdateOrderStatus`
Updates an order's status after validating it is one of the allowed values.

**Parameters:**

| Parameter | Direction | Type | Description |
|---|---|---|---|
| @OrderID | IN | INT | The order to update |
| @NewStatus | IN | NVARCHAR(20) | New status value |
| @Success | OUT | BIT | 1 if updated, 0 if not found |

**Allowed status values:** `Pending`, `Processing`, `Shipped`, `Delivered`, `Cancelled`

**Usage:**
```sql
DECLARE @OK BIT;
EXEC sp_UpdateOrderStatus
    @OrderID   = 5,
    @NewStatus = 'Processing',
    @Success   = @OK OUTPUT;
SELECT @OK AS UpdateSuccess;
```

---

## Functions

Scalar-valued functions that return a single computed value for use in queries.

### `fn_GetDiscountedPrice(ProductID, DiscountPct)`
Returns a product's price after applying a percentage discount.

```sql
-- Get Dell Inspiron price with 10% off
SELECT dbo.fn_GetDiscountedPrice(1, 10) AS DiscountedPrice;
-- Returns: 719.99
```

---

### `fn_GetCategoryRevenue(CategoryID)`
Returns the total revenue earned from all non-cancelled orders for a category.

```sql
-- Total revenue from Electronics (CategoryID = 1)
SELECT dbo.fn_GetCategoryRevenue(1) AS ElectronicsRevenue;
```

---

### `fn_GetCustomerTier(CustomerID)`
Returns a customer's loyalty tier based on total spend.

| Tier | Minimum Spend |
|---|---|
| Bronze | $0 |
| Silver | $500 |
| Gold | $1,000 |
| Platinum | $2,000 |

```sql
SELECT dbo.fn_GetCustomerTier(1) AS LoyaltyTier;
-- Returns: 'Gold' or 'Platinum' etc.
```

---

## Triggers

Automated actions that fire in response to data changes.

### `trg_OrderItems_AfterInsert`
**Fires:** After an insert into `OrderItems`  
**Action:** Recalculates and updates `Orders.TotalAmount` to reflect the correct total (including any discounts) across all line items in that order.

---

### `trg_Customers_PreventDelete`
**Fires:** Instead of a DELETE on `Customers`  
**Action:** Blocks the deletion if the customer has any existing orders and raises an error:  
> *"Cannot delete customer with existing orders. Deactivate instead."*  
Customers should be deactivated (`IsActive = 0`) rather than deleted.

---

### `trg_Products_LowStock`
**Fires:** After an UPDATE on `Products`  
**Action:** If a product's `StockQty` drops below 5, automatically logs an alert record into the `StockAlerts` table for review.

---

## Sample Data

| Table | Records |
|---|---|
| Categories | 9 (5 top-level, 4 sub-categories) |
| Customers | 8 (Illinois-based customers) |
| Products | 12 (across Electronics, Books, Clothing, Sports, Home) |
| Orders | 8 (April–May 2026) |
| OrderItems | 15 line items |
| Reviews | 8 product reviews |

---

## How to Run

1. Open **SQL Server Management Studio (SSMS)**
2. Connect to your SQL Server instance
3. Open the file `ecommerce_db.sql`
4. Press **F5** (or click Execute) to run the entire script

> The script will automatically drop and recreate the `ECommerceDB` database, so it is safe to run multiple times.

---

## Project Structure

```
ecommerce_db.sql
│
├── Section 1  — Table Creation (7 tables with constraints)
├── Section 2  — Indexes (5 performance indexes)
├── Section 3  — Data Insertion (sample data)
├── Section 4  — Views (3 reporting views)
├── Section 5  — Stored Procedures (3 procedures)
├── Section 6  — Functions (3 scalar functions)
├── Section 7  — Triggers (3 automated triggers)
└── Section 8  — Testing (test calls for all components)
```

---

## Requirements

- Microsoft SQL Server 2016 or later
- SQL Server Management Studio (SSMS) 18+
- No external dependencies — the script is fully self-contained
