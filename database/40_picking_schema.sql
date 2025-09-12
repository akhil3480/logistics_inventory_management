
### --- Picking Layer: Pickers, Boxes, PickedItems --- ###


CREATE TABLE IF NOT EXISTS Pickers (
  picker_id INT AUTO_INCREMENT PRIMARY KEY,
  name VARCHAR(100) NOT NULL,
  is_active TINYINT(1) NOT NULL DEFAULT 1
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE IF NOT EXISTS Boxes (
  box_id BIGINT AUTO_INCREMENT PRIMARY KEY,
  order_id BIGINT NOT NULL,
  picker_id INT,
  status ENUM('Open','Packed','Closed') NOT NULL DEFAULT 'Open',
  CONSTRAINT fk_box_order FOREIGN KEY (order_id)
    REFERENCES Orders(order_id)
    ON UPDATE CASCADE ON DELETE CASCADE,
  CONSTRAINT fk_box_picker FOREIGN KEY (picker_id)
    REFERENCES Pickers(picker_id)
    ON UPDATE CASCADE ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE IF NOT EXISTS PickedItems (
  picked_id BIGINT AUTO_INCREMENT PRIMARY KEY,
  box_id BIGINT NOT NULL,
  product_id INT NOT NULL,
  shop_loc_id INT NOT NULL,
  qty_picked INT NOT NULL,
  picked_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  CONSTRAINT fk_pi_box FOREIGN KEY (box_id)
    REFERENCES Boxes(box_id)
    ON UPDATE CASCADE ON DELETE CASCADE,
  CONSTRAINT fk_pi_prod FOREIGN KEY (product_id)
    REFERENCES Products(product_id)
    ON UPDATE CASCADE ON DELETE RESTRICT,
  CONSTRAINT fk_pi_loc FOREIGN KEY (shop_loc_id)
    REFERENCES ShopLocations(shop_loc_id)
    ON UPDATE CASCADE ON DELETE RESTRICT,
  CONSTRAINT chk_pi_qty CHECK (qty_picked > 0)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE INDEX ix_pi_box  ON PickedItems(box_id);
CREATE INDEX ix_pi_prod ON PickedItems(product_id);
CREATE INDEX ix_pi_loc  ON PickedItems(shop_loc_id);
