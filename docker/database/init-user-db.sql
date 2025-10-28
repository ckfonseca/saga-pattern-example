-- payment_db.users definition

CREATE TABLE `users` (
  `id` bigint NOT NULL AUTO_INCREMENT,
  `balance` decimal(38,2) DEFAULT NULL,
  `name` varchar(255) DEFAULT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

INSERT IGNORE INTO users (id, name, balance) VALUES (1, 'Cristiano Fonseca', 1000.00);
INSERT IGNORE INTO users (id, name, balance) VALUES (2, 'Rodrigo Brayner', 500.00);
