-- inventory_db.inventories definition

CREATE TABLE IF NOT EXISTS `inventories` (
  `id` bigint NOT NULL AUTO_INCREMENT,
  `product_id` int DEFAULT NULL,
  `quantity` int DEFAULT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;


INSERT IGNORE INTO inventory_db.inventories (id, product_id, quantity) VALUES (1, 6, 10);
INSERT IGNORE INTO inventory_db.inventories (id, product_id, quantity) VALUES (2, 7, 5);
INSERT IGNORE INTO inventory_db.inventories (id, product_id, quantity) VALUES (3, 8, 50);
INSERT IGNORE INTO inventory_db.inventories (id, product_id, quantity) VALUES (4, 9, 30);
INSERT IGNORE INTO inventory_db.inventories (id, product_id, quantity) VALUES (5, 10, 20);
