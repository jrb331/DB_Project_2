-- create temporary customer table

CREATE TABLE TEMP_CUSTOMER (
customer_first_name VARCHAR(15) ,
customer_last_name VARCHAR(15) ,
customer_id VARCHAR(50) ,
customer_email VARCHAR(40) ,
customer_street_address VARCHAR(40) ,
customer_city_address VARCHAR(20) ,
customer_state_address VARCHAR(20));

-- load data into temp_customer

\copy temp_customer(customer_first_name, customer_last_name, customer_id, customer_email, customer_street_address, customer_city_address, customer_state_address) FROM '/home/jrb331/DB_Project_2/users.csv' WITH DELIMITER ',';

--create temporary service file

CREATE TABLE TEMP_SERVICE (item_id VARCHAR(10), item_name VARCHAR(400),
item_brand VARCHAR(100), item_category VARCHAR(100));

--load data into temporary service

\copy temp_service(item_id, item_name, item_brand, item_category) FROM '/home/jrb331/DB_Project_2/services.csv' WITH DELIMITER ',' CSV QUOTE '"';

--create temporary product table

CREATE TABLE TEMP_PRODUCT (item_id VARCHAR(10), item_name VARCHAR(400),
item_brand VARCHAR(100), item_category VARCHAR(100));

-- create extra temporary product file to load unsplit data

CREATE TABLE VERY_TEMP_PRODUCT ( all_data VARCHAR(400));

-- load data into single column

\copy very_temp_product(all_data) FROM '/home/jrb331/DB_Project_2/products.csv';


-- split data by '|' and insert into temp_product
INSERT INTO temp_product
SELECT split_part(all_data, '|', 1)
product_id, split_part(all_data, '|', 2)
product_name, split_part(all_data, '|', 3)
product_brand, split_part(all_data, '|', 4)
product_category
FROM  very_temp_product;

--clean customer file for consistent capitalization
UPDATE temp_customer
SET customer_email = UPPER(customer_email);

UPDATE temp_customer
SET customer_first_name = UPPER(customer_first_name);

UPDATE temp_customer
SET customer_last_name = UPPER(customer_last_name);

UPDATE temp_customer
SET customer_street_address = UPPER(customer_street_address);

UPDATE temp_customer
SET customer_city_address = UPPER(customer_city_address);

UPDATE temp_customer
SET customer_state_address = UPPER(customer_state_address);

-- remove emails without '@' sign
DELETE FROM temp_customer WHERE customer_email NOT LIKE '%@%';

-- remove emails without standard TLD
DELETE FROM temp_customer WHERE customer_email NOT LIKE '%.COM'
AND customer_email NOT LIKE '%.GOV'
AND customer_email NOT LIKE '%.ORG'
AND customer_email NOT LIKE '%.EDU'
AND customer_email NOT LIKE '%.NET'
AND customer_email NOT LIKE '%.TECH'
AND customer_email NOT LIKE '%.IO'
AND customer_email NOT LIKE '%.UK'
AND customer_email NOT LIKE '%.CO'
AND customer_email NOT LIKE '%.US';

--create customer table
CREATE TABLE CUSTOMER
(customer_id VARCHAR(50) NOT NULL,
customer_email VARCHAR(40) NOT NULL,
customer_password VARCHAR(20) ,
customer_first_name VARCHAR(15) NOT NULL,
customer_last_name VARCHAR(15) NOT NULL,
customer_street_address VARCHAR(40) NOT NULL,
customer_city_address VARCHAR(20) NOT NULL,
customer_state_address VARCHAR(20) NOT NULL,
customer_zip_code VARCHAR(10) ,
PRIMARY KEY (customer_id));

--insert into customer from temp_customer removing duplicates
INSERT INTO customer (
  customer_id, customer_email, customer_first_name, customer_last_name,
  customer_street_address, customer_city_address, customer_state_address)
  (SELECT DISTINCT customer_id, customer_email, customer_first_name,
    customer_last_name, customer_street_address, customer_city_address,
    customer_state_address
    FROM temp_customer);

--add a column for type
ALTER TABLE temp_service ADD COLUMN service_category VARCHAR(7)
DEFAULT 'SERVICE';

--add a column for type
ALTER TABLE temp_product ADD COLUMN service_category VARCHAR(7)
DEFAULT 'PRODUCT';

--clean product and service files for consistent capitalization

UPDATE temp_product
SET item_name = UPPER(item_name);
UPDATE temp_product
SET item_brand = UPPER(item_brand);
UPDATE temp_product
SET item_category = UPPER(item_category);

UPDATE temp_service
SET item_name = UPPER(item_name);
UPDATE temp_service
SET item_brand = UPPER(item_brand);
UPDATE temp_service
SET item_category = UPPER(item_category);

--remove tuples with no primary key
DELETE FROM temp_service WHERE item_id = '';
DELETE FROM temp_service WHERE item_id IS NULL;

DELETE FROM temp_product WHERE item_id = '';
DELETE FROM temp_product WHERE item_id IS NULL;

--create final item table
CREATE TABLE ITEM (
item_id VARCHAR(10) NOT NULL,
item_type VARCHAR(7) NOT NULL CHECK(item_type = 'PRODUCT'
  OR item_type = 'SERVICE'),
item_name VARCHAR(400) NOT NULL,
item_description VARCHAR(100) ,
item_price NUMERIC	(9,2) ,
item_picture BYTEA ,
PRIMARY KEY(item_id));

--insert services into item table, removing duplicates
INSERT INTO item (item_id, item_type, item_name, item_description)
(SELECT DISTINCT item_id, service_category, item_name, item_category
  FROM temp_service);

--insert products into item table, removing duplicates
INSERT INTO item (item_id, item_type, item_name, item_description)
(SELECT DISTINCT item_id, service_category, item_name, item_category
  FROM temp_product);

--create a temporary company table and generate IDs for keys
CREATE TABLE temp_company (company_name VARCHAR(50));


--insert companies from product file removing duplicates
INSERT INTO temp_company (company_name) (SELECT DISTINCT item_brand FROM temp_product);

--insert companies from service file removing duplicates
INSERT INTO temp_company (company_name) (SELECT DISTINCT item_brand FROM temp_service);

CREATE TABLE FINAL_COMPANY (company_name VARCHAR(50));

ALTER TABLE FINAL_COMPANY ADD COLUMN ID SERIAL PRIMARY KEY;


INSERT INTO FINAL_COMPANY (company_name) (SELECT DISTINCT company_name from temp_company);


--create company table with restraints
CREATE TABLE COMPANY (
company_id VARCHAR(10) NOT NULL,
company_name VARCHAR(50) ,
company_contact VARCHAR(30),
company_contact_phone_nbr INTEGER ,
company_contact_email VARCHAR(40) ,
url VARCHAR(50) UNIQUE,
PRIMARY KEY (company_id));

--copy final_company into company, removing duplicates for companies with both products and services
INSERT INTO company(company_id, company_name)
SELECT DISTINCT id, company_name
FROM FINAL_COMPANY;

--create a temporary discount table
CREATE TABLE temp_discount (discount_type VARCHAR(20) ,
discount_amount VARCHAR(10) ,
discount_description VARCHAR(50) ,
discount_start_date DATE ,
discount_end_date DATE );

--add a column and create keys
ALTER TABLE temp_discount ADD COLUMN DISCOUNT_ID SERIAL PRIMARY KEY;

-- insert coupon types into discount table
INSERT INTO temp_discount (discount_type, discount_amount)
VALUES ('PERCENTAGE COUPON', '25%');

INSERT INTO temp_discount (discount_type, discount_amount)
VALUES ('PERCENTAGE COUPON', '50%');

INSERT INTO temp_discount (discount_type, discount_amount)
VALUES ('PERCENTAGE COUPON', '75%');

INSERT INTO temp_discount (discount_type, discount_amount)
VALUES ('FIXED COUPON', '$10');

INSERT INTO temp_discount (discount_type, discount_amount)
VALUES ('FIXED COUPON', '$25');

INSERT INTO temp_discount (discount_type, discount_amount)
VALUES ('FIXED COUPON', '$50');

INSERT INTO temp_discount (discount_type, discount_amount)
VALUES ('FIXED COUPON', '$100');

INSERT INTO temp_discount (discount_type, discount_amount)
VALUES ('FREEBIE', '100%');

INSERT INTO temp_discount (discount_type, discount_description)
VALUES ('OTHER', 'Buy one get one free');

--update start and end dates of coupons
UPDATE temp_discount SET discount_start_date = '2021-03-10',
discount_end_date = '2021-03-27' WHERE discount_id = 1;

UPDATE temp_discount SET discount_start_date = '2021-03-14',
discount_end_date = '2021-03-23' WHERE discount_id = 2;

UPDATE temp_discount SET discount_start_date = '2021-03-22',
discount_end_date = '2021-03-26' WHERE discount_id = 3;

UPDATE temp_discount SET discount_start_date = '2021-03-17',
discount_end_date = '2021-03-25' WHERE discount_id = 4;

UPDATE temp_discount SET discount_start_date = '2021-03-20',
discount_end_date = '2021-03-29' WHERE discount_id = 5;

UPDATE temp_discount SET discount_start_date = '2021-03-09',
discount_end_date = '2021-03-24' WHERE discount_id = 6;

UPDATE temp_discount SET discount_start_date = '2021-03-01',
discount_end_date = '2021-03-20' WHERE discount_id = 7;

UPDATE temp_discount SET discount_start_date = '2021-03-14',
discount_end_date = '2021-03-20' WHERE discount_id = 8;

UPDATE temp_discount SET discount_start_date = '2021-03-14',
discount_end_date = '2021-03-22' WHERE discount_id = 9;

--create final discount table
CREATE TABLE DISCOUNT(
discount_id VARCHAR(10) NOT NULL,
discount_type VARCHAR(20) NOT NULL CHECK(discount_type = 'FREEBIE' OR
   discount_type = 'PERCENTAGE COUPON' OR
   discount_type = 'FIXED COUPON' OR
   discount_type = 'OTHER'),
discount_amount VARCHAR(5) ,
discount_description VARCHAR(50) ,
discount_start_date DATE  ,
discount_end_date DATE  ,
PRIMARY KEY (discount_id));

--copy temp_discount into final discount
INSERT INTO discount (
  discount_id, discount_type, discount_amount, discount_description,
  discount_start_date, discount_end_date)
  (SELECT discount_id, discount_type, discount_amount, discount_description,
    discount_start_date, discount_end_date
    FROM temp_discount);

--create temp_company_item
CREATE TABLE temp_company_item ( company_id VARCHAR(10) ,
 item_id VARCHAR(10) ,
  is_discounted BOOLEAN DEFAULT FALSE ,
   discount_id VARCHAR(10));

--insert company-item pairs from service table
INSERT INTO temp_company_item (item_id, company_id)
(SELECT DISTINCT item_id, company_id
  FROM temp_service, company
  WHERE item_brand = company_name);

--insert company-item pairs from product table
INSERT INTO temp_company_item (item_id, company_id)
(SELECT DISTINCT item_id, company_id
  FROM temp_product, company
  WHERE item_brand = company_name);


--randonly assign a discount id within the range of discount keys to each tuple
UPDATE temp_company_item SET discount_id = floor(random()*(9-1+1))+1;

--update the is_discounted column if the discount end date hasnt passed yet
UPDATE temp_company_item SET is_discounted = 't' WHERE discount_id IN
(SELECT discount_id
  FROM discount
  WHERE discount_start_date < CURRENT_DATE
  AND discount_end_date > CURRENT_DATE);

--create final company_item table
CREATE TABLE COMPANY_ITEM (
company_id VARCHAR(10) NOT NULL,
item_id VARCHAR(10) NOT NULL,
is_discounted BOOLEAN NOT NULL DEFAULT FALSE,
discount_id VARCHAR(10) NOT NULL ,
PRIMARY KEY (company_id, item_id),
FOREIGN KEY (company_id) REFERENCES COMPANY(company_id),
FOREIGN KEY (item_id) REFERENCES ITEM(item_id),
FOREIGN KEY (discount_id) REFERENCES DISCOUNT(discount_id));

--copy temp_company_item into company_item
INSERT INTO COMPANY_ITEM (company_id, item_id, is_discounted, discount_id)
(SELECT DISTINCT company_id, item_id, is_discounted, discount_id FROM temp_company_item);

--create the first view
CREATE VIEW view_discount_dates AS
WITH RECURSIVE dates AS (
SELECT MIN(d.discount_start_date) as theDate FROM discount d
UNION ALL SELECT da.theDate+1 FROM dates da
WHERE da.theDate+1 <= CURRENT_DATE)
SELECT theDate, count (distinct c.item_id) as no_discounts,
SUM(CASE WHEN da.theDate = d.discount_start_date then 1 else 0 end) as sameDate
FROM (temp_company_item c JOIN discount d ON c.discount_id = d.discount_id)
JOIN dates da ON (da.theDate >= d.discount_start_date
  AND da.theDate <= d.discount_end_date) GROUP BY theDate;

--create sorted view
CREATE VIEW sorted_view AS SELECT *
FROM item
WHERE item_type = 'PRODUCT' ORDER BY item_name ASC;

--add the rest of the table from the relational model

CREATE TABLE CUSTOMER_INTEREST
(customer_id VARCHAR(20) NOT NULL,
customer_interest VARCHAR(20) ,
PRIMARY KEY (customer_id, customer_interest),
FOREIGN KEY (customer_id) REFERENCES CUSTOMER (customer_id));

CREATE TABLE CUSTOMER_COMPANY_PREFERENCE
(customer_id  VARCHAR(20) NOT NULL,
preference_company_id VARCHAR(30) NOT NULL,
PRIMARY KEY (customer_id, preference_company_id),
FOREIGN KEY (preference_company_id) REFERENCES COMPANY(company_id),
FOREIGN KEY (customer_id) REFERENCES CUSTOMER(customer_id));

CREATE TABLE CUSTOMER_ITEM_PREFERENCE
(customer_id VARCHAR(20) NOT NULL,
item_id VARCHAR(10) NOT NULL,
PRIMARY KEY (customer_id, item_id),
FOREIGN KEY (customer_id) REFERENCES CUSTOMER(customer_id),
FOREIGN KEY(item_id) REFERENCES ITEM(item_id));

CREATE TABLE CUSTOMER_LOCATION_PREFERENCE
(customer_id VARCHAR(20) NOT NULL,
preference_location_city VARCHAR(20) NOT NULL,
preference_location_state VARCHAR(20) NOT NULL,
PRIMARY KEY (customer_id, preference_location_city, preference_location_state),
FOREIGN KEY (customer_id) REFERENCES CUSTOMER(customer_id));

CREATE TABLE COMPANY_LOCATION (
company_id VARCHAR(10) NOT NULL,
location_id VARCHAR(10) NOT NULL,
company_location_street_address VARCHAR(40) ,
company_location_city VARCHAR(20) ,
company_location_state VARCHAR(20) ,
company_location_zip_code VARCHAR(10) ,
company_locationphone_nbr INTEGER ,
PRIMARY KEY (location_id),
FOREIGN KEY (company_id) REFERENCES COMPANY(company_id));

CREATE TABLE CUSTOMER_COMPANY_REVIEW (
company_id VARCHAR(10) NOT NULL,
customer_id VARCHAR(20) NOT NULL,
rating_score NUMERIC(2,1) NOT NULL,
comments VARCHAR(100) ,
PRIMARY KEY (company_id, customer_id),
FOREIGN KEY (company_id) REFERENCES COMPANY(company_id),
FOREIGN KEY (customer_id) REFERENCES CUSTOMER(customer_id));

CREATE TABLE CUSTOMER_CHECKIN (
checkin_id VARCHAR(10) NOT NULL,
checkin_date DATE UNIQUE NOT NULL,
customer_id VARCHAR(20) UNIQUE NOT NULL,
company_id VARCHAR(10) UNIQUE NOT NULL,
item_id VARCHAR(10) UNIQUE NOT NULL,
discount_id VARCHAR(10) NOT NULL,
PRIMARY KEY (checkin_id),
FOREIGN KEY (customer_id) REFERENCES CUSTOMER(customer_id),
FOREIGN KEY (company_id) REFERENCES COMPANY(company_id),
FOREIGN KEY (item_id) REFERENCES ITEM(item_id),
FOREIGN KEY (discount_id) REFERENCES DISCOUNT(discount_id));

CREATE TABLE EMPLOYEE(
employee_id VARCHAR(10) NOT NULL,
employee_email VARCHAR(40) UNIQUE  NOT NULL,
employee_first_name VARCHAR(20)  NOT NULL,
employee_last_name VARCHAR(20)  NOT NULL,
employee_job_category VARCHAR(20) ,
employee_salary VARCHAR(9) ,
employee_start_date DATE ,
employee_street_address VARCHAR(40) ,
employee_city_address VARCHAR(20) ,
employee_state_address VARCHAR(20) ,
employee_zip_code VARCHAR(10) ,
PRIMARY KEY (employee_id));

CREATE TABLE COMPANY_TRANSACTION (
transaction_id VARCHAR(10) NOT NULL,
transaction_date DATE NOT NULL,
charge_type VARCHAR(15) NOT NULL CHECK(charge_type = 'ANNUAL FEE' OR
   charge_type = 'CHECKIN FEES'),
transaction_amount NUMERIC(9,2) NOT NULL,
surcharge NUMERIC(9,2) NOT NULL,
total_charge NUMERIC(9,2) NOT NULL
CHECK(total_charge = transaction_amount + surcharge),
is_paid BOOLEAN NOT NULL,
paid_date DATE NOT NULL,
company_id VARCHAR(10) NOT NULL,
PRIMARY KEY (transaction_id),
FOREIGN KEY (company_id) REFERENCES COMPANY(company_id));

CREATE TABLE COMPANY_TRANSACTION_CHECKIN (
transaction_id VARCHAR(10) NOT NULL,
checkin_id VARCHAR(10) NOT NULL,
checkin_charge NUMERIC (9,2) NOT NULL,
PRIMARY KEY (transaction_id, checkin_id),
FOREIGN KEY (transaction_id) REFERENCES COMPANY_TRANSACTION(transaction_id),
FOREIGN KEY (checkin_id) REFERENCES CUSTOMER_CHECKIN(checkin_id));
