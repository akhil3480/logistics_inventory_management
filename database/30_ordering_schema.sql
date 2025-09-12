
### -- Ordering Layer: Orders, OrderItems --- ###


CREATE TABLE IF NOT EXISTS Orders (
  order_id BIGINT AUTO_INCREMENT PRIMARY KEY,
  shop_id INT NOT NULL,
  order_datetime DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  status ENUM('Pending','In_Picking','Picked','Packed','Shipped','Cancelled') NOT NULL DEFAULT 'Pending',
  CONSTRAINT fk_order_shop FOREIGN KEY (shop_id)
    REFERENCES Shops(shop_id)
    ON UPDATE CASCADE ON DELETE RESTRICT
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE IF NOT EXISTS OrderItems (
  order_item_id BIGINT AUTO_INCREMENT PRIMARY KEY,
  order_id BIGINT NOT NULL,
  product_id INT NOT NULL,
  qty_ordered INT NOT NULL,
  qty_picked INT NOT NULL DEFAULT 0,
  CONSTRAINT fk_oi_order FOREIGN KEY (order_id)
    REFERENCES Orders(order_id)
    ON UPDATE CASCADE ON DELETE CASCADE,
  CONSTRAINT fk_oi_prod FOREIGN KEY (product_id)
    REFERENCES Products(product_id)
    ON UPDATE CASCADE ON DELETE RESTRICT,
  CONSTRAINT chk_qty_ordered CHECK (qty_ordered > 0),
  CONSTRAINT chk_qty_picked CHECK (qty_picked >= 0)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE INDEX ix_oi_order ON OrderItems(order_id);
CREATE INDEX ix_oi_prod  ON OrderItems(product_id);
