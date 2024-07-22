SELECT table_name
FROM information_schema.tables
WHERE table_schema = 'task1ad_cs';

select * from person_person;
select * from humanresources_employee;

-- Información sobre las columnas en la tabla humanresources_employee
DESCRIBE humanresources_employee;

-- Información sobre las columnas en la tabla person_person
DESCRIBE person_person;

SHOW TABLES;

SELECT * FROM purchasing_shipmethod;

SELECT * FROM sales_salesorderheader
LIMIT 10;

SELECT * FROM sales_customer
LIMIT 10;

SELECT * FROM person_address
LIMIT 10;

SELECT * FROM purchasing_shipmethod
WHERE Name LIKE '%Speedy Express%';


select * from person_address;




