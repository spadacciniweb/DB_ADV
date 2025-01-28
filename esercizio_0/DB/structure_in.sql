USE DB_ADV_0;

-- header
-- bank accounts -> "username","euro","datetime"
-- bank movements -> "username","type","euro","datetime.mil"

CREATE TABLE bank_account (
    `id` int unsigned NOT NULL AUTO_INCREMENT,
    `username` varchar(25) NOT NULL,
    `accounting_balance` decimal(10,2) default 0,
    `available_balance` decimal(10,2) default 0,
    `creazione` datetime DEFAULT current_timestamp(),
    `ts` timestamp NOT NULL DEFAULT current_timestamp() ON UPDATE current_timestamp(),
  PRIMARY KEY (`id`),
  UNIQUE KEY (`username`)
);

CREATE TABLE bank_movement (
    `id` int unsigned NOT NULL AUTO_INCREMENT,
    `user_id` int unsigned NOT NULL,
    `euro` decimal(10,2) default 0,
    `processed` bool default 0,
    `dt_src` char(23) NOT NULL,
    `ts` timestamp NOT NULL DEFAULT current_timestamp() ON UPDATE current_timestamp(),
  PRIMARY KEY (`id`),
  CONSTRAINT `bank_movement_idfk_1` FOREIGN KEY (`user_id`) REFERENCES `bank_account` (`id`)
);
