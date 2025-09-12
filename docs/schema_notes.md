# Schema Notes \& Migrations

## Base Schema (v1.0)

* Initial 4-layer design (Warehouse, Shop, Ordering, Picking)
* Includes Warehouses, Shops, Products, Orders, Boxes, Pickers, Stock tables, and relationships
* Basic created\_at timestamps in: Warehouses, Products, Shops, PickedItems

## Phase 1 (2025-09-12): Audit \& Constraints

* Added created\_at + updated\_at to:

  * WarehouseLocations
  * ShopLocations
  * Pickers
  * Boxes
  * OrderItems

* Added updated\_at to:

  * ProductWarehouseStock
  * ProductShopStock

* Enforced data-quality:

  * CHECK (qty\_picked <= qty\_ordered) on OrderItems

* Converted quantity columns to UNSIGNED:

  * OrderItems.qty\_ordered, OrderItems.qty\_picked
  * ProductWarehouseStock.qty\_on\_hand
  * ProductShopStock.qty\_on\_hand

##

## Phase 1.1 (2025-09-13): FK Cleanup & Cardinality Enforcement

**Goal:** Remove duplicate foreign keys, enforce intended relationships, and add slot-level uniqueness.

### Changes
- **Shops ↔ Warehouses (one-to-one)**
  - Removed duplicate FK on `Shops.warehouse_id` (kept `fk_shop_wh`).
  - Enforced 1↔1 by making `Shops.warehouse_id` **NOT NULL + UNIQUE** (`uq_shops_warehouse`).
  - Reasserted FK with actions: `ON UPDATE CASCADE ON DELETE RESTRICT`.

- **WarehouseLocations ↔ Warehouses (one-to-many)**
  - Removed any duplicate FK on `WarehouseLocations.warehouse_id` (kept `fk_whloc_wh`).
  - Ensured non-unique index on `warehouse_id` for joins (`ix_whloc_wh`).
  - Added composite **UNIQUE** so each physical slot is unique within a warehouse:  
    `UNIQUE (warehouse_id, zone, aisle, rack, shelf, bin)` (`uq_whloc_slot_per_wh`).

### Verification Queries
```sql
-- Shops: single FK + unique
SELECT CONSTRAINT_NAME
FROM information_schema.TABLE_CONSTRAINTS
WHERE TABLE_SCHEMA = DATABASE()
  AND TABLE_NAME = 'Shops'
  AND CONSTRAINT_TYPE = 'FOREIGN KEY';

SHOW INDEX FROM Shops WHERE Key_name = 'uq_shops_warehouse';

-- WarehouseLocations: single FK + slot uniqueness
SELECT CONSTRAINT_NAME
FROM information_schema.TABLE_CONSTRAINTS
WHERE TABLE_SCHEMA = DATABASE()
  AND TABLE_NAME = 'WarehouseLocations'
  AND CONSTRAINT_TYPE = 'FOREIGN KEY';

SHOW INDEX FROM WarehouseLocations WHERE Key_name = 'uq_whloc_slot_per_wh';
```

### Notes
- No data clean-up was required (schema adjusted before seeding).
- ERD updated recommendation: show **Warehouse 1 ↔ 1 Shop**, **Warehouse 1 → N WarehouseLocations**.

