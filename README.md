# Logistics Inventory Management System

This is a database project I’m building in **MySQL** to simulate how products move through a simple logistics flow.

The idea is that we have 3 warehouses, each connected to a shop (front stock area). Products are stored in bulk in the warehouse, replenished into the shop, and then picked from the shop when an order comes in.

The goal of this project is to practice:

- Designing normalized relational tables  
- Writing stored procedures and triggers for stock movement  
- Managing a project with Git and version control  
- Building something that looks and feels like a real logistics system  

---

## System Design

- **Warehouse Layer**  
  Bulk storage for products. Each warehouse has multiple locations (zone, aisle, rack, shelf, bin).

- **Shop Layer**  
  Each warehouse has one shop linked to it. Products are replenished into shop locations.  
  Picking always happens here, not directly from the warehouse.

- **Ordering Layer**  
  Orders are tied to a shop. Each order has one or more products.

- **Picking Layer**  
  Pickers scan and collect products from shop bins into boxes.  
  Stock in the shop is reduced as items are picked.  
  One box belongs to only one order, but an order can span multiple boxes.  

---

## Folder Structure

logistics-inventory-management-system/

```
├── database/           # SQL scripts  
│   ├── 00_create_database.sql  
│   ├── 10_warehouse_schema.sql  
│   ├── 20_shop_schema.sql  
│   ├── 30_ordering_schema.sql  
│   ├── 40_picking_schema.sql  
│   ├── 90_procedures.sql  
│   ├── 95_triggers.sql  
│   ├── 99_seed_data.sql  
│   └── install_all.sql  
├── docs/               # ERD, diagrams  
├── README.md  
└── .gitignore  
```

---

## How to Run

1. Open **MySQL Workbench** (or MySQL CLI).  
2. Run `install_all.sql` — this will create the database, all tables, and load some demo data.  
3. After setup, you can open each file inside `database/` to see how the project is structured:  
   - `10_warehouse_schema.sql` → warehouse and product tables  
   - `20_shop_schema.sql` → shops and shop stock  
   - `30_ordering_schema.sql` → orders and order items  
   - `40_picking_schema.sql` → picking entities  
   - `90_procedures.sql` → stored procedures for workflows  

---

## 📜 Migration Log

- **Base Schema (v1.0):** 4-layer design (Warehouse, Shop, Ordering, Picking).  
- **Phase 1 (2025-09-12): Audit & Constraints**  
  - Added `created_at` + `updated_at` timestamps to: WarehouseLocations, ShopLocations, Pickers, Boxes, OrderItems  
  - Added `updated_at` to: ProductWarehouseStock, ProductShopStock  
  - Enforced data-quality: CHECK (qty_picked <= qty_ordered) on OrderItems  
  - Converted quantity fields to UNSIGNED (to avoid negatives)  

---

## Current Progress

- ✅ Base schema for warehouse, shop, ordering, picking  
- ✅ Seed data for 3 warehouses, 3 shops, and some products  
- ✅ Stored procedures implemented in `90_procedures.sql`:
  - `sp_replenish_shop_from_warehouse` – move stock from warehouse to shop  
  - `sp_create_order` – create a new order for a shop  
  - `sp_add_order_item` – add products to an order  
  - `sp_open_box_for_order` – assign a box to an order and picker  
  - `sp_scan_pick` – pick products into a box (updates stock + order items)  
  - `sp_close_box` – close a box once picking is complete  
- 🔜 Triggers for automated status updates (planned)  
- 🔜 Multi-order handling and advanced picking logic (planned)  
- ✅ ERD diagram and documentation  
