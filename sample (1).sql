-- Adminer 4.8.1 MySQL 8.0.36 dump

SET NAMES utf8;
SET time_zone = '+00:00';
SET foreign_key_checks = 0;
SET sql_mode = 'NO_AUTO_VALUE_ON_ZERO';

DELIMITER ;;

DROP PROCEDURE IF EXISTS `calculate_salary`;;
CREATE PROCEDURE `calculate_salary`(IN `performer_id` int, IN `month` date)
BEGIN
DECLARE salary_amount DECIMAL(10, 2);
SELECT time_rate, allowance_factor, hours_worked
FROM Performer
WHERE id = performer_id
INTO @time_rate, @allowance_factor, @hours_worked;
SET salary_amount = CONVERT(TIME_TO_SEC(@time_rate),double)/3600 * @allowance_factor *
@hours_worked;
INSERT INTO Salary (performer_id, month, salary_amount)
VALUES (performer_id, month, salary_amount);
END;;

DROP PROCEDURE IF EXISTS `everybody_calculate_salary`;;
CREATE PROCEDURE `everybody_calculate_salary`(IN `month` DATE)
BEGIN
DECLARE number INT;
SET number = 1;
SELECT COUNT(id) INTO @count FROM Performer;
WHILE number <= @count DO
CALL calculate_salary(number, month);
SET number = number + 1;
END WHILE;
END;;

DELIMITER ;

SET NAMES utf8mb4;

DROP TABLE IF EXISTS `account`;
CREATE TABLE `account` (
  `id` int NOT NULL AUTO_INCREMENT,
  `id_agreement` int NOT NULL,
  `sum` int NOT NULL,
  `status_of_payment` varchar(16) NOT NULL,
  `UCR` varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci NOT NULL,
  `DCR` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `ULC` varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci NOT NULL,
  `DLC` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  KEY `id_agreement` (`id_agreement`),
  CONSTRAINT `account_ibfk_1` FOREIGN KEY (`id_agreement`) REFERENCES `Agreement` (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=9 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

INSERT INTO `account` (`id`, `id_agreement`, `sum`, `status_of_payment`, `UCR`, `DCR`, `ULC`, `DLC`) VALUES
(1,	1,	1000,	'paid',	'',	'2024-04-11 14:48:10',	'',	'2024-04-11 14:48:10'),
(2,	2,	500,	'unpaid',	'',	'2024-04-11 14:48:10',	'',	'2024-04-11 14:48:10'),
(3,	3,	2000,	'paid',	'',	'2024-04-11 14:48:10',	'',	'2024-04-11 14:48:10'),
(4,	2,	4500,	'Category B',	'',	'2024-04-11 14:48:10',	'',	'2024-04-11 14:48:10'),
(5,	2,	4500,	'Category B',	'',	'2024-04-11 14:48:10',	'',	'2024-04-11 14:48:10');

DELIMITER ;;

CREATE TRIGGER `account_before_insert` BEFORE INSERT ON `account` FOR EACH ROW
SET NEW.UCR = USER(),
NEW.DCR = NOW(),
NEW.ULC = USER(),
NEW.DLC = NOW();;

CREATE TRIGGER `account_insert` BEFORE INSERT ON `account` FOR EACH ROW
BEGIN
   DECLARE max_id BIGINT;
    SELECT MAX(id) INTO max_id FROM account;
    IF NEW.id != max_id+1 THEN 
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Invalid id value';
    END IF;
END;;

CREATE TRIGGER `account_before_update` BEFORE UPDATE ON `account` FOR EACH ROW
SET NEW.ULC = USER(),
NEW.DLC = NOW();;

DELIMITER ;

DROP TABLE IF EXISTS `Agreement`;
CREATE TABLE `Agreement` (
  `id` int NOT NULL AUTO_INCREMENT,
  `name` varchar(16) NOT NULL,
  `customer` int NOT NULL,
  `contract_category` varchar(16) NOT NULL,
  `date` date NOT NULL,
  `payment` int NOT NULL,
  `UCR` varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci NOT NULL,
  `DCR` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `ULC` varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci NOT NULL,
  `DLC` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  KEY `index_name` (`id`),
  KEY `customer` (`customer`),
  CONSTRAINT `agreement_ibfk_2` FOREIGN KEY (`customer`) REFERENCES `Customer` (`id`),
  CONSTRAINT `agreement_ibfk_3` FOREIGN KEY (`customer`) REFERENCES `Customer` (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=7 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

INSERT INTO `Agreement` (`id`, `name`, `customer`, `contract_category`, `date`, `payment`, `UCR`, `DCR`, `ULC`, `DLC`) VALUES
(1,	'Agreement 1',	1,	'Category A',	'2024-03-11',	1000,	'',	'2024-04-11 14:48:10',	'root@172.18.0.2',	'2024-04-11 15:28:29'),
(2,	'Agreement 2',	2,	'Category B',	'2023-10-11',	4500,	'',	'2024-04-11 14:48:10',	'root@172.18.0.2',	'2024-04-11 15:28:18'),
(3,	'Agreement 3',	3,	'Category C',	'2024-04-11',	3000,	'',	'2024-04-11 14:48:10',	'',	'2024-04-11 14:48:10');

DELIMITER ;;

CREATE TRIGGER `agreement_before_insert` BEFORE INSERT ON `Agreement` FOR EACH ROW
SET NEW.UCR = USER(),
NEW.DCR = NOW(),
NEW.ULC = USER(),
NEW.DLC = NOW();;

CREATE TRIGGER `prevent_new_project` BEFORE INSERT ON `Agreement` FOR EACH ROW
BEGIN
DECLARE unpaid_projects_count INT;
DECLARE last_unpaid_project_date DATE;
SET unpaid_projects_count = (
SELECT COUNT(*) FROM `Agreement`
JOIN `account` ON `Agreement`.`id` = `account`.`id_agreement`
WHERE `customer` = NEW.customer AND `status_of_payment` = 'unpaid'
);
IF unpaid_projects_count > 0 THEN
SET last_unpaid_project_date = (
SELECT MIN(`date`) FROM `Agreement`
JOIN `account` ON `Agreement`.`id` = `account`.`id_agreement`
WHERE `customer` = NEW.customer AND `status_of_payment` = 'unpaid'
);
IF DATE_ADD(last_unpaid_project_date, INTERVAL 3 MONTH) < CURDATE()
THEN
SIGNAL SQLSTATE '45000'
SET MESSAGE_TEXT = 'The customer has unpaid projects created more than 3
months ago';
END IF;
END IF;
END;;

CREATE TRIGGER `agreement_before_update` BEFORE UPDATE ON `Agreement` FOR EACH ROW
SET NEW.ULC = USER(),
NEW.DLC = NOW();;

DELIMITER ;

DROP TABLE IF EXISTS `Customer`;
CREATE TABLE `Customer` (
  `id` int NOT NULL AUTO_INCREMENT,
  `name` varchar(16) NOT NULL,
  `adress` varchar(16) NOT NULL,
  `contact_person` varchar(16) NOT NULL,
  `phone` varchar(16) NOT NULL,
  `UCR` varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci NOT NULL,
  `DCR` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `ULC` varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci NOT NULL,
  `DLC` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=4 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

INSERT INTO `Customer` (`id`, `name`, `adress`, `contact_person`, `phone`, `UCR`, `DCR`, `ULC`, `DLC`) VALUES
(1,	'John Smith',	'123 Main St',	'Jane Doe',	'555-1234',	'',	'2024-04-11 14:48:10',	'',	'2024-04-11 14:48:10'),
(2,	'Sarah Johnson',	'456 Elm St',	'Mike Smith',	'555-5678',	'',	'2024-04-11 14:48:10',	'',	'2024-04-11 14:48:10'),
(3,	'David Lee',	'789 Oak St',	'Emily Green',	'555-9012',	'',	'2024-04-11 14:48:10',	'',	'2024-04-11 14:48:10');

DELIMITER ;;

CREATE TRIGGER `customer_before_insert` BEFORE INSERT ON `Customer` FOR EACH ROW
SET NEW.UCR = USER(),
NEW.DCR = NOW(),
NEW.ULC = USER(),
NEW.DLC = NOW();;

CREATE TRIGGER `customer_before_update` BEFORE UPDATE ON `Customer` FOR EACH ROW
SET NEW.ULC = USER(),
NEW.DLC = NOW();;

DELIMITER ;

DROP TABLE IF EXISTS `Performer`;
CREATE TABLE `Performer` (
  `id` int NOT NULL AUTO_INCREMENT,
  `name` varchar(16) NOT NULL,
  `post` varchar(16) NOT NULL,
  `qualification` varchar(16) NOT NULL,
  `time_rate` time NOT NULL,
  `allowance_factor` int NOT NULL,
  `hours_worked` int NOT NULL,
  `UCR` varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci NOT NULL,
  `DCR` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `ULC` varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci NOT NULL,
  `DLC` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=5 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

INSERT INTO `Performer` (`id`, `name`, `post`, `qualification`, `time_rate`, `allowance_factor`, `hours_worked`, `UCR`, `DCR`, `ULC`, `DLC`) VALUES
(1,	'John Smith',	'Developer',	'Senior',	'08:00:00',	1,	170,	'',	'2024-04-11 14:48:10',	'',	'2024-04-11 14:48:10'),
(2,	'BILAN VERONIKA',	'Designer',	'Junior',	'06:30:00',	1,	128,	'',	'2024-04-11 14:48:10',	'',	'2024-04-11 14:48:10'),
(3,	'Alik Express',	'QA',	'Senior',	'08:00:00',	1,	144,	'',	'2024-04-11 14:48:10',	'',	'2024-04-11 14:48:10'),
(4,	'Yulia Moyseyiv',	'Project Manager',	'Senior',	'08:00:00',	1,	160,	'',	'2024-04-11 14:48:10',	'',	'2024-04-11 14:48:10');

DELIMITER ;;

CREATE TRIGGER `performer_before_insert` BEFORE INSERT ON `Performer` FOR EACH ROW
SET NEW.UCR = USER(),
NEW.DCR = NOW(),
NEW.ULC = USER(),
NEW.DLC = NOW();;

CREATE TRIGGER `performer_before_update` BEFORE UPDATE ON `Performer` FOR EACH ROW
SET NEW.ULC = USER(),
NEW.DLC = NOW();;

DELIMITER ;

DROP TABLE IF EXISTS `Performers_Projects`;
CREATE TABLE `Performers_Projects` (
  `performer_id` int NOT NULL,
  `project_id` int NOT NULL,
  `UCR` varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci NOT NULL,
  `DCR` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `ULC` varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci NOT NULL,
  `DLC` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`performer_id`,`project_id`),
  KEY `project_id` (`project_id`),
  CONSTRAINT `performers_projects_ibfk_1` FOREIGN KEY (`performer_id`) REFERENCES `Performer` (`id`),
  CONSTRAINT `performers_projects_ibfk_2` FOREIGN KEY (`project_id`) REFERENCES `Project` (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

INSERT INTO `Performers_Projects` (`performer_id`, `project_id`, `UCR`, `DCR`, `ULC`, `DLC`) VALUES
(1,	1,	'',	'2024-04-11 14:48:10',	'',	'2024-04-11 14:48:10'),
(2,	1,	'',	'2024-04-11 14:48:10',	'',	'2024-04-11 14:48:10'),
(3,	2,	'',	'2024-04-11 14:48:10',	'',	'2024-04-11 14:48:10'),
(4,	3,	'',	'2024-04-11 14:48:10',	'',	'2024-04-11 14:48:10');

DELIMITER ;;

CREATE TRIGGER `Performers_Projects_before_insert` BEFORE INSERT ON `Performers_Projects` FOR EACH ROW
SET NEW.UCR = USER(),
NEW.DCR = NOW(),
NEW.ULC = USER(),
NEW.DLC = NOW();;

CREATE TRIGGER `Performers_Projects_before_update` BEFORE UPDATE ON `Performers_Projects` FOR EACH ROW
SET NEW.ULC = USER(),
NEW.DLC = NOW();;

DELIMITER ;

DROP TABLE IF EXISTS `Project`;
CREATE TABLE `Project` (
  `id` int NOT NULL AUTO_INCREMENT,
  `name` varchar(16) NOT NULL,
  `сustomer` int NOT NULL,
  `project_manager` varchar(16) NOT NULL,
  `planned_duration` int NOT NULL,
  `difficulty_category` varchar(16) NOT NULL,
  `start_date` date NOT NULL,
  `UCR` varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci NOT NULL,
  `DCR` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `ULC` varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci NOT NULL,
  `DLC` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  KEY `сustomer` (`сustomer`),
  CONSTRAINT `project_ibfk_2` FOREIGN KEY (`сustomer`) REFERENCES `Customer` (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=5 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

INSERT INTO `Project` (`id`, `name`, `сustomer`, `project_manager`, `planned_duration`, `difficulty_category`, `start_date`, `UCR`, `DCR`, `ULC`, `DLC`) VALUES
(1,	'Project 1',	1,	'Tom Johnson',	30,	'Easy',	'2022-01-01',	'',	'2024-04-11 14:48:10',	'',	'2024-04-11 14:48:10'),
(2,	'Project 2',	2,	'Lisa Brown',	60,	'Medium',	'2022-02-01',	'',	'2024-04-11 14:48:10',	'',	'2024-04-11 14:48:10'),
(3,	'Project 3',	3,	'Michael Davis',	90,	'Hard',	'2022-03-01',	'',	'2024-04-11 14:48:10',	'',	'2024-04-11 14:48:10'),
(4,	'Project 1',	1,	'Tamara Johnson',	30,	'Easy',	'2022-01-01',	'project_manager@172.18.0.2',	'2024-04-24 15:29:37',	'project_manager@172.18.0.2',	'2024-04-24 15:29:37');

DELIMITER ;;

CREATE TRIGGER `Project_before_insert` BEFORE INSERT ON `Project` FOR EACH ROW
SET NEW.UCR = USER(),
NEW.DCR = NOW(),
NEW.ULC = USER(),
NEW.DLC = NOW();;

CREATE TRIGGER `Project_before_update` BEFORE UPDATE ON `Project` FOR EACH ROW
SET NEW.ULC = USER(),
NEW.DLC = NOW();;

DELIMITER ;

DROP TABLE IF EXISTS `Reports`;
CREATE TABLE `Reports` (
  `id` int NOT NULL AUTO_INCREMENT,
  `id_performer` int NOT NULL,
  `id_project` int NOT NULL,
  `date` date NOT NULL,
  `description` varchar(256) NOT NULL,
  `hours_worked` int NOT NULL,
  `UCR` varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci NOT NULL,
  `DCR` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `ULC` varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci NOT NULL,
  `DLC` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  KEY `id_performer` (`id_performer`),
  KEY `id_project` (`id_project`),
  CONSTRAINT `reports_ibfk_1` FOREIGN KEY (`id_project`) REFERENCES `Project` (`id`),
  CONSTRAINT `reports_ibfk_2` FOREIGN KEY (`id_performer`) REFERENCES `Performer` (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=21 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

INSERT INTO `Reports` (`id`, `id_performer`, `id_project`, `date`, `description`, `hours_worked`, `UCR`, `DCR`, `ULC`, `DLC`) VALUES
(10,	1,	1,	'2022-01-02',	'Worked on task 1',	8,	'',	'2024-04-11 14:48:10',	'',	'2024-04-11 14:48:10'),
(11,	2,	1,	'2022-01-02',	'Worked on task 2',	4,	'',	'2024-04-11 14:48:10',	'',	'2024-04-11 14:48:10'),
(12,	3,	1,	'2022-01-03',	'Worked on task 3',	6,	'',	'2024-04-11 14:48:10',	'',	'2024-04-11 14:48:10'),
(13,	1,	2,	'2022-02-02',	'Worked on task 4',	10,	'',	'2024-04-11 14:48:10',	'',	'2024-04-11 14:48:10'),
(14,	2,	2,	'2022-02-03',	'Worked on task 5',	8,	'',	'2024-04-11 14:48:10',	'',	'2024-04-11 14:48:10'),
(15,	3,	2,	'2022-02-03',	'Worked on task 6',	6,	'',	'2024-04-11 14:48:10',	'',	'2024-04-11 14:48:10'),
(16,	1,	3,	'2022-03-04',	'Worked on task 7',	12,	'',	'2024-04-11 14:48:10',	'',	'2024-04-11 14:48:10'),
(17,	2,	3,	'2022-03-05',	'Worked on task 8',	10,	'',	'2024-04-11 14:48:10',	'',	'2024-04-11 14:48:10'),
(18,	3,	3,	'2022-03-05',	'Worked on task 9',	8,	'',	'2024-04-11 14:48:10',	'',	'2024-04-11 14:48:10'),
(19,	3,	3,	'2023-02-05',	'Worked on task 10',	9,	'',	'2024-04-11 14:48:10',	'',	'2024-04-11 14:48:10'),
(20,	3,	3,	'2023-02-05',	'Worked on task 10',	9,	'',	'2024-04-11 14:48:10',	'',	'2024-04-11 14:48:10');

DELIMITER ;;

CREATE TRIGGER `Reports_before_insert` BEFORE INSERT ON `Reports` FOR EACH ROW
SET NEW.UCR = USER(),
NEW.DCR = NOW(),
NEW.ULC = USER(),
NEW.DLC = NOW();;

CREATE TRIGGER `check_hours_worked` BEFORE INSERT ON `Reports` FOR EACH ROW
BEGIN
DECLARE total_hours INT;
SELECT SUM(hours_worked) INTO total_hours FROM Reports WHERE id_performer=
NEW.id_performer AND date = NEW.date;
IF (total_hours + NEW.hours_worked) > 10 THEN
SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Exceeded maximum number of
working hours for the day';
END IF;
IF (NEW.hours_worked) > 10 THEN
SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Exceeded maximum number of
working hours for the day';
END IF;
END;;

CREATE TRIGGER `Reports_before_update` BEFORE UPDATE ON `Reports` FOR EACH ROW
SET NEW.ULC = USER(),
NEW.DLC = NOW();;

DELIMITER ;

DROP TABLE IF EXISTS `Salary`;
CREATE TABLE `Salary` (
  `id` int NOT NULL AUTO_INCREMENT,
  `performer_id` int NOT NULL,
  `month` date NOT NULL,
  `salary_amount` decimal(10,2) NOT NULL,
  `UCR` varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci NOT NULL,
  `DCR` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `ULC` varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci NOT NULL,
  `DLC` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  KEY `Salary_performer_fk` (`performer_id`),
  CONSTRAINT `Salary_performer_fk` FOREIGN KEY (`performer_id`) REFERENCES `Performer` (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=6 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

INSERT INTO `Salary` (`id`, `performer_id`, `month`, `salary_amount`, `UCR`, `DCR`, `ULC`, `DLC`) VALUES
(1,	1,	'2023-03-01',	1360.00,	'',	'2024-04-11 14:48:10',	'',	'2024-04-11 14:48:10'),
(2,	1,	'2023-05-02',	1360.00,	'',	'2024-04-11 14:48:10',	'',	'2024-04-11 14:48:10'),
(3,	2,	'2023-05-02',	832.00,	'',	'2024-04-11 14:48:10',	'',	'2024-04-11 14:48:10'),
(4,	3,	'2023-05-02',	1152.00,	'',	'2024-04-11 14:48:10',	'',	'2024-04-11 14:48:10'),
(5,	4,	'2023-05-02',	1280.00,	'',	'2024-04-11 14:48:10',	'',	'2024-04-11 14:48:10');

DELIMITER ;;

CREATE TRIGGER `Salary_before_insert` BEFORE INSERT ON `Salary` FOR EACH ROW
SET NEW.UCR = USER(),
NEW.DCR = NOW(),
NEW.ULC = USER(),
NEW.DLC = NOW();;

CREATE TRIGGER `Salary_before_update` BEFORE UPDATE ON `Salary` FOR EACH ROW
SET NEW.ULC = USER(),
NEW.DLC = NOW();;

DELIMITER ;

-- 2024-04-24 16:08:08
