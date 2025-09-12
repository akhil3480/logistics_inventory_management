
### ---- Shop Layer: Shops, ShopLocations, Shop Stock ---- ###

CREATE TABLE IF NOT EXISTS Shops (
  shop_id INT AUTO_INCREMENT PRIMARY KEY,
  warehouse_id INT NOT NULL UNIQUE,
  name VARCHAR(100) NOT NULL,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  CONSTRAINT fk_shop_wh FOREIGN KEY (warehouse_id)
    REFERENCES Warehouses(warehouse_id)
    ON UPDATE CASCADE ON DELETE RESTRICT
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE IF NOT EXISTS ShopLocations (
  shop_loc_id INT AUTO_INCREMENT PRIMARY KEY,
  shop_id INT NOT NULL,
  zone VARCHAR(20), aisle VARCHAR(20), shelf VARCHAR(20), bin VARCHAR(20),
  UNIQUE KEY uq_shop_loc (shop_id, zone, aisle, shelf, bin),
  CONSTRAINT fk_shoploc_shop FOREIGN KEY (shop_id)
    REFERENCES Shops(shop_id)
    ON UPDATE CASCADE ON DELETE RESTRICT
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE IF NOT EXISTS ProductShopStock (
  product_id INT NOT NULL,
  shop_loc_id INT NOT NULL,
  qty_on_hand INT NOT NULL DEFAULT 0,
  PRIMARY KEY (product_id, shop_loc_id),
  CONSTRAINT fk_pss_prod FOREIGN KEY (product_id)
    REFERENCES Products(product_id)
    ON UPDATE CASCADE ON DELETE RESTRICT,
  CONSTRAINT fk_pss_loc FOREIGN KEY (shop_loc_id)
    REFERENCES ShopLocations(shop_loc_id)
    ON UPDATE CASCADE ON DELETE RESTRICT,
  CONSTRAINT chk_pss_qty CHECK (qty_on_hand >= 0)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE INDEX ix_pss_prod ON ProductShopStock(product_id);
CREATE INDEX ix_pss_loc  ON ProductShopStock(shop_loc_id);
