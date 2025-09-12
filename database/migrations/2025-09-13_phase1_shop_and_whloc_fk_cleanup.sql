-- 1) Drop the extra FK (if you haven’t already)
ALTER TABLE Shops DROP FOREIGN KEY fk_shop_warehouse;

-- 2) (Optional) Only add UNIQUE if you don't already have it
-- If it warns it's duplicate, you're fine; skip it next time.
ALTER TABLE Shops ADD UNIQUE KEY uq_shops_warehouse (warehouse_id);

-- 3) Recreate the kept FK with explicit actions — in TWO statements
ALTER TABLE Shops DROP FOREIGN KEY fk_shop_wh;
ALTER TABLE Shops
  ADD CONSTRAINT fk_shop_wh
  FOREIGN KEY (warehouse_id) REFERENCES Warehouses(warehouse_id)
  ON UPDATE CASCADE ON DELETE RESTRICT;

-- Drop the extra one (example name)
ALTER TABLE WarehouseLocations DROP FOREIGN KEY fk_whloc_warehouse;

-- Optional: reassert the kept FK with explicit actions
ALTER TABLE WarehouseLocations
  DROP FOREIGN KEY fk_whloc_wh;

ALTER TABLE WarehouseLocations
  ADD CONSTRAINT fk_whloc_wh
  FOREIGN KEY (warehouse_id) REFERENCES Warehouses(warehouse_id)
  ON UPDATE CASCADE ON DELETE RESTRICT;

-- Helper index for joins
CREATE INDEX ix_whloc_wh ON WarehouseLocations(warehouse_id);

-- Ensure each slot is unique within a warehouse
ALTER TABLE WarehouseLocations
  ADD CONSTRAINT uq_whloc_slot_per_wh
  UNIQUE (warehouse_id, zone, aisle, rack, shelf, bin);
