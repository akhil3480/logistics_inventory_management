
### ---- Warehouse Layer: Warehouses, Products, WarehouseLocations, WH Stock ---- ###


CREATE TABLE IF NOT EXISTS Warehouses (
  warehouse_id INT AUTO_INCREMENT PRIMARY KEY,
  name VARCHAR(100) NOT NULL UNIQUE,
  city VARCHAR(80),
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE IF NOT EXISTS Products (
  product_id INT AUTO_INCREMENT PRIMARY KEY,
  sku VARCHAR(64) NOT NULL UNIQUE,
  name VARCHAR(150) NOT NULL,
  barcode VARCHAR(64) UNIQUE,
  unit_price DECIMAL(10,2) DEFAULT 0,
  is_active TINYINT(1) NOT NULL DEFAULT 1,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE IF NOT EXISTS WarehouseLocations (
  wh_loc_id INT AUTO_INCREMENT PRIMARY KEY,
  warehouse_id INT NOT NULL,
  zone VARCHAR(20), aisle VARCHAR(20), rack VARCHAR(20), shelf VARCHAR(20), bin VARCHAR(20),
  UNIQUE KEY uq_wh_loc (warehouse_id, zone, aisle, rack, shelf, bin),
  CONSTRAINT fk_whloc_wh FOREIGN KEY (warehouse_id)
    REFERENCES Warehouses(warehouse_id)
    ON UPDATE CASCADE ON DELETE RESTRICT
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE IF NOT EXISTS ProductWarehouseStock (
  product_id INT NOT NULL,
  wh_loc_id INT NOT NULL,
  qty_on_hand INT NOT NULL DEFAULT 0,
  PRIMARY KEY (product_id, wh_loc_id),
  CONSTRAINT fk_pws_prod FOREIGN KEY (product_id)
    REFERENCES Products(product_id)
    ON UPDATE CASCADE ON DELETE RESTRICT,
  CONSTRAINT fk_pws_loc FOREIGN KEY (wh_loc_id)
    REFERENCES WarehouseLocations(wh_loc_id)
    ON UPDATE CASCADE ON DELETE RESTRICT,
  CONSTRAINT chk_pws_qty CHECK (qty_on_hand >= 0)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE INDEX ix_pws_prod ON ProductWarehouseStock(product_id);
CREATE INDEX ix_pws_loc  ON ProductWarehouseStock(wh_loc_id);
