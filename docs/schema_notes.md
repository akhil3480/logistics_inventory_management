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

