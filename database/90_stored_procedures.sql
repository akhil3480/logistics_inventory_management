
-- Logistics_inventory_management  - stored procedures/workflow
--   sp_replenish_shop_from_warehouse
--   sp_create_order
--   sp_add_order_item
--   sp_open_box_for_order
--   sp_scan_pick
--   sp_close_box
--------------------------------------------------------

DELIMITER //

-- ---------- Replenish Shop From Warehouse ----------
DROP PROCEDURE IF EXISTS sp_replenish_shop_from_warehouse//
CREATE PROCEDURE sp_replenish_shop_from_warehouse(
    IN p_src_wh_loc_id   INT,
    IN p_dst_shop_loc_id INT,
    IN p_product_id      INT,
    IN p_qty             INT
)
BEGIN
    DECLARE v_src_qty    INT;
    DECLARE v_dummy      INT;
    DECLARE v_not_found  TINYINT DEFAULT 0;

    DECLARE CONTINUE HANDLER FOR NOT FOUND SET v_not_found = 1;

    IF p_qty IS NULL OR p_qty <= 0 THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'INVALID_QTY: qty must be > 0';
    END IF;

    IF NOT EXISTS (SELECT 1 FROM WarehouseLocations WHERE wh_loc_id = p_src_wh_loc_id) THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'WH_LOC_NOT_FOUND';
    END IF;
    IF NOT EXISTS (SELECT 1 FROM ShopLocations WHERE shop_loc_id = p_dst_shop_loc_id) THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'SHOP_LOC_NOT_FOUND';
    END IF;
    IF NOT EXISTS (SELECT 1 FROM Products WHERE product_id = p_product_id AND is_active = 1) THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'PRODUCT_NOT_FOUND_OR_INACTIVE';
    END IF;

    START TRANSACTION;

      SET v_not_found = 0;
      SELECT qty_on_hand
        INTO v_src_qty
        FROM ProductWarehouseStock
       WHERE wh_loc_id  = p_src_wh_loc_id
         AND product_id = p_product_id
       FOR UPDATE;

      IF v_not_found = 1 THEN
        ROLLBACK;
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'SRC_STOCK_ROW_NOT_FOUND';
      END IF;

      IF v_src_qty < p_qty THEN
        ROLLBACK;
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'INSUFFICIENT_STOCK';
      END IF;

      UPDATE ProductWarehouseStock
         SET qty_on_hand = qty_on_hand - p_qty,
             updated_at  = CURRENT_TIMESTAMP
       WHERE wh_loc_id  = p_src_wh_loc_id
         AND product_id = p_product_id;

      SET v_not_found = 0;
      SELECT 1
        INTO v_dummy
        FROM ProductShopStock
       WHERE shop_loc_id = p_dst_shop_loc_id
         AND product_id  = p_product_id
       FOR UPDATE;

      IF v_not_found = 1 THEN
        INSERT INTO ProductShopStock (product_id, shop_loc_id, qty_on_hand, updated_at)
        VALUES (p_product_id, p_dst_shop_loc_id, 0, CURRENT_TIMESTAMP);
      END IF;

      UPDATE ProductShopStock
         SET qty_on_hand = qty_on_hand + p_qty,
             updated_at  = CURRENT_TIMESTAMP
       WHERE shop_loc_id = p_dst_shop_loc_id
         AND product_id  = p_product_id;

    COMMIT;
END//


-- ---------- Create Order ----------
DROP PROCEDURE IF EXISTS sp_create_order//
CREATE PROCEDURE sp_create_order(
    IN  p_shop_id         INT,
    IN  p_order_datetime  DATETIME
)
BEGIN
    DECLARE v_order_id BIGINT;

    IF NOT EXISTS (SELECT 1 FROM Shops WHERE shop_id = p_shop_id) THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'SHOP_NOT_FOUND';
    END IF;

    START TRANSACTION;

      INSERT INTO Orders (shop_id, order_datetime, status, created_at, updated_at)
      VALUES (p_shop_id,
              COALESCE(p_order_datetime, CURRENT_TIMESTAMP),
              'Pending',
              CURRENT_TIMESTAMP,
              CURRENT_TIMESTAMP);

      SET v_order_id = LAST_INSERT_ID();

    COMMIT;

    SELECT v_order_id AS order_id;
END//


-- ---------- Add Order Item (merge policy) ----------
DROP PROCEDURE IF EXISTS sp_add_order_item//
CREATE PROCEDURE sp_add_order_item(
    IN p_order_id     BIGINT,
    IN p_product_id   INT,
    IN p_qty_ordered  INT
)
BEGIN
    DECLARE v_not_found  TINYINT DEFAULT 0;
    DECLARE v_curr_qty_o INT;
    DECLARE v_curr_qty_p INT;

    DECLARE CONTINUE HANDLER FOR NOT FOUND SET v_not_found = 1;

    IF p_qty_ordered IS NULL OR p_qty_ordered <= 0 THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'INVALID_QTY_ORDERED: must be > 0';
    END IF;
    IF NOT EXISTS (SELECT 1 FROM Orders WHERE order_id = p_order_id) THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'ORDER_NOT_FOUND';
    END IF;
    IF NOT EXISTS (SELECT 1 FROM Products WHERE product_id = p_product_id AND is_active = 1) THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'PRODUCT_NOT_FOUND_OR_INACTIVE';
    END IF;

    START TRANSACTION;

      SET v_not_found = 0;
      SELECT qty_ordered, qty_picked
        INTO v_curr_qty_o, v_curr_qty_p
        FROM OrderItems
       WHERE order_id = p_order_id
         AND product_id = p_product_id
       FOR UPDATE;

      IF v_not_found = 1 THEN
         INSERT INTO OrderItems (order_id, product_id, qty_ordered, qty_picked, created_at, updated_at)
         VALUES (p_order_id, p_product_id, p_qty_ordered, 0, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP);
      ELSE
         UPDATE OrderItems
            SET qty_ordered = qty_ordered + p_qty_ordered,
                qty_picked  = LEAST(qty_picked, qty_ordered + p_qty_ordered),
                updated_at  = CURRENT_TIMESTAMP
          WHERE order_id = p_order_id
            AND product_id = p_product_id;
      END IF;

    COMMIT;
END//


-- ---------- Open Box For Order ----------
DROP PROCEDURE IF EXISTS sp_open_box_for_order//
CREATE PROCEDURE sp_open_box_for_order(
    IN p_order_id  BIGINT,
    IN p_picker_id INT
)
BEGIN
    DECLARE v_box_id BIGINT;

    IF NOT EXISTS (SELECT 1 FROM Orders WHERE order_id = p_order_id) THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'ORDER_NOT_FOUND';
    END IF;
    IF NOT EXISTS (SELECT 1 FROM Pickers WHERE picker_id = p_picker_id AND is_active = 1) THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'PICKER_NOT_FOUND_OR_INACTIVE';
    END IF;

    START TRANSACTION;

      INSERT INTO Boxes (order_id, picker_id, status, created_at, updated_at)
      VALUES (p_order_id, p_picker_id, 'OPEN', CURRENT_TIMESTAMP, CURRENT_TIMESTAMP);

      SET v_box_id = LAST_INSERT_ID();

    COMMIT;

    SELECT v_box_id AS box_id;
END//


-- ---------- Scan Pick ----------
DROP PROCEDURE IF EXISTS sp_scan_pick//
CREATE PROCEDURE sp_scan_pick(
    IN p_box_id      BIGINT,
    IN p_product_id  INT,
    IN p_qty         INT,
    IN p_shop_loc_id INT
)
BEGIN
    DECLARE v_order_id   BIGINT;
    DECLARE v_box_status VARCHAR(32);
    DECLARE v_pss_qty    INT;
    DECLARE v_remain_qty INT;
    DECLARE v_not_found  TINYINT DEFAULT 0;

    DECLARE CONTINUE HANDLER FOR NOT FOUND SET v_not_found = 1;

    IF p_qty IS NULL OR p_qty <= 0 THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'INVALID_QTY: qty must be > 0';
    END IF;
    IF NOT EXISTS (SELECT 1 FROM ShopLocations WHERE shop_loc_id = p_shop_loc_id) THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'SHOP_LOC_NOT_FOUND';
    END IF;
    IF NOT EXISTS (SELECT 1 FROM Products WHERE product_id = p_product_id AND is_active = 1) THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'PRODUCT_NOT_FOUND_OR_INACTIVE';
    END IF;

    START TRANSACTION;

      SET v_not_found = 0;
      SELECT order_id, status INTO v_order_id, v_box_status
        FROM Boxes
       WHERE box_id = p_box_id
       FOR UPDATE;

      IF v_not_found = 1 THEN
          ROLLBACK; SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'BOX_NOT_FOUND';
      END IF;
      IF v_box_status <> 'OPEN' THEN
          ROLLBACK; SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'BOX_NOT_OPEN';
      END IF;

      SET v_not_found = 0;
      SELECT (qty_ordered - qty_picked) AS remain
        INTO v_remain_qty
        FROM OrderItems
       WHERE order_id  = v_order_id
         AND product_id = p_product_id
       FOR UPDATE;

      IF v_not_found = 1 THEN
          ROLLBACK; SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'ORDER_ITEM_NOT_FOUND_FOR_PRODUCT';
      END IF;
      IF v_remain_qty <= 0 THEN
          ROLLBACK; SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'ITEM_ALREADY_FULLY_PICKED';
      END IF;
      IF p_qty > v_remain_qty THEN
          ROLLBACK; SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'PICK_QTY_EXCEEDS_REMAINING';
      END IF;

      SET v_not_found = 0;
      SELECT qty_on_hand INTO v_pss_qty
        FROM ProductShopStock
       WHERE shop_loc_id = p_shop_loc_id
         AND product_id  = p_product_id
       FOR UPDATE;

      IF v_not_found = 1 THEN
          ROLLBACK; SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'SHOP_STOCK_ROW_NOT_FOUND';
      END IF;
      IF v_pss_qty < p_qty THEN
          ROLLBACK; SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'INSUFFICIENT_SHOP_STOCK';
      END IF;

      UPDATE ProductShopStock
         SET qty_on_hand = qty_on_hand - p_qty,
             updated_at  = CURRENT_TIMESTAMP
       WHERE shop_loc_id = p_shop_loc_id
         AND product_id  = p_product_id;

      INSERT INTO PickedItems (box_id, product_id, shop_loc_id, qty_picked, picked_at, updated_at)
      VALUES (p_box_id, p_product_id, p_shop_loc_id, p_qty, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP);

      UPDATE OrderItems
         SET qty_picked = qty_picked + p_qty,
             updated_at = CURRENT_TIMESTAMP
       WHERE order_id  = v_order_id
         AND product_id = p_product_id;

    COMMIT;
END//


-- ---------- Close Box ----------
DROP PROCEDURE IF EXISTS sp_close_box//
CREATE PROCEDURE sp_close_box(
    IN p_box_id BIGINT
)
BEGIN
    IF NOT EXISTS (SELECT 1 FROM Boxes WHERE box_id = p_box_id) THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'BOX_NOT_FOUND';
    END IF;

    START TRANSACTION;
      UPDATE Boxes
         SET status = 'CLOSED',
             updated_at = CURRENT_TIMESTAMP
       WHERE box_id = p_box_id;
    COMMIT;
END//

DELIMITER ;
