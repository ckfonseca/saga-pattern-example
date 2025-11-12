-- inventory_db.inventories definition

CREATE TABLE IF NOT EXISTS `inventories` (
  `id` bigint NOT NULL AUTO_INCREMENT,
  `product_id` int DEFAULT NULL,
  `quantity` int DEFAULT NULL,
  `created_at` timestamp NOT NULL,
  `updated_at` timestamp,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;


INSERT IGNORE INTO inventory_db.inventories (id, product_id, quantity, created_at) VALUES (1, 6, 10, NOW());
INSERT IGNORE INTO inventory_db.inventories (id, product_id, quantity, created_at) VALUES (2, 7, 5, NOW());
INSERT IGNORE INTO inventory_db.inventories (id, product_id, quantity, created_at) VALUES (3, 8, 50, NOW());
INSERT IGNORE INTO inventory_db.inventories (id, product_id, quantity, created_at) VALUES (4, 9, 30, NOW());
INSERT IGNORE INTO inventory_db.inventories (id, product_id, quantity, created_at) VALUES (5, 10, 20, NOW());
