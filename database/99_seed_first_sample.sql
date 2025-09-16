
-- Creates: 2 warehouses, 2 shops, locations, 5 products,
--          initial warehouse/shop stock, 2 pickers,
--          1 order with 2 items (Pending)
-- ==============================================

START TRANSACTION;

-- 1) Warehouses
INSERT INTO Warehouses (warehouse_id, name, city, created_at, updated_at)
VALUES
  (1, 'Central DC', 'New York', NOW(), NOW()),
  (2, 'West Hub',   'Los Angeles', NOW(), NOW());

-- 2) WarehouseLocations
INSERT INTO WarehouseLocations (wh_loc_id, warehouse_id, zone, aisle, rack, shelf, bin, created_at, updated_at)
VALUES
  (101, 1, 'A', '01', 'R1', 'S1', 'B1', NOW(), NOW()),
  (102, 1, 'A', '01', 'R1', 'S1', 'B2', NOW(), NOW()),
  (201, 2, 'B', '03', 'R2', 'S2', 'B5', NOW(), NOW());

-- 3) Shops (one per warehouse)
INSERT INTO Shops (shop_id, warehouse_id, name, created_at, updated_at)
VALUES
  (10, 1, 'Manhattan Shop', NOW(), NOW()),
  (20, 2, 'Santa Monica Shop', NOW(), NOW());

-- 4) ShopLocations
INSERT INTO ShopLocations (shop_loc_id, shop_id, zone, aisle, shelf, bin, created_at, updated_at)
VALUES
  (1001, 10, 'F', '01', 'S1', 'B1', NOW(), NOW()),
  (1002, 10, 'F', '01', 'S1', 'B2', NOW(), NOW()),
  (2001, 20, 'G', '02', 'S3', 'B4', NOW(), NOW());

-- 5) Products
INSERT INTO Products (product_id, sku, name, barcode, unit_price, is_active, created_at, updated_at)
VALUES
  (100, 'SKU-100', 'Blue T-Shirt',   'BC100', 19.99, 1, NOW(), NOW()),
  (101, 'SKU-101', 'Red T-Shirt',    'BC101', 19.99, 1, NOW(), NOW()),
  (102, 'SKU-102', 'Sneakers',       'BC102', 79.50, 1, NOW(), NOW()),
  (103, 'SKU-103', 'Cap',            'BC103', 12.00, 1, NOW(), NOW()),
  (104, 'SKU-104', 'Water Bottle',   'BC104', 9.50,  1, NOW(), NOW());

-- 6) ProductWarehouseStock (by wh location)
INSERT INTO ProductWarehouseStock (product_id, wh_loc_id, qty_on_hand, updated_at)
VALUES
  (100, 101, 200, NOW()),
  (101, 101, 150, NOW()),
  (102, 102,  80, NOW()),
  (103, 201, 300, NOW()),
  (104, 201, 120, NOW());

-- 7) ProductShopStock (by shop location)
INSERT INTO ProductShopStock (product_id, shop_loc_id, qty_on_hand, updated_at)
VALUES
  (100, 1001, 40, NOW()),
  (101, 1001, 25, NOW()),
  (102, 1002, 15, NOW()),
  (103, 2001, 60, NOW()),
  (104, 2001, 30, NOW());

-- 8) Pickers
INSERT INTO Pickers (picker_id, name, is_active, created_at, updated_at)
VALUES
  (1, 'Akhil', 1, NOW(), NOW()),
  (2, 'Alok', 1, NOW(), NOW());

-- 9) Orders (one pending order for Shop 10)
INSERT INTO Orders (order_id, shop_id, order_datetime, status, created_at, updated_at)
VALUES
  (50001, 10, NOW(), 'Pending', NOW(), NOW());

-- 10) OrderItems (2 lines)
INSERT INTO OrderItems (order_item_id, order_id, product_id, qty_ordered, qty_picked, created_at, updated_at)
VALUES
  (60001, 50001, 100, 3, 0, NOW(), NOW()),  -- 3 x Blue T-Shirt
  (60002, 50001, 102, 2, 0, NOW(), NOW());  -- 2 x Sneakers

COMMIT;
