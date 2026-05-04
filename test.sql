USE ECommerceDB;
-- Trigger 3: reduce stock, check alert table
UPDATE Products SET StockQty = 3 WHERE ProductID = 10;
SELECT * FROM StockAlerts;