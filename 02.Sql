-- Data cleaning in books table

-- 1. Remove rows with missing book_id
DELETE FROM books WHERE book_id IS NULL OR book_id = '';

-- 2. Trim spaces and normalize case
UPDATE books
SET title = TRIM(title),
    author = TRIM(author),
    genre = TRIM(genre);

-- 3. Replace N/A or blank with NULL
UPDATE books
SET title = NULL WHERE title = '' OR title = 'N/A';
UPDATE books
SET author = NULL WHERE author = '' OR author = 'N/A';
UPDATE books
SET genre = NULL WHERE genre = '' OR genre = 'N/A';

-- 4. Clean published_year: set invalids to NULL, convert to INT
UPDATE books
SET published_year = NULL
WHERE published_year IS NULL
   OR published_year = '' 
   OR published_year = 'Unknown';

-- 5. Clean price: remove text, convert to numeric, set invalids to NULL
UPDATE books
SET price = NULL
WHERE price IS NULL OR price NOT REGEXP '^[0-9]+(\.[0-9]{1,2})?$';

-- 6. Clean stock: negative values or invalid set to 0
UPDATE books
SET stock = CASE 
                WHEN stock < 0 THEN 0
                ELSE stock
            END;

-- 7. fill missing stock with 0
UPDATE books SET stock = 0 WHERE stock IS NULL;

-- Data cleaning in customers table 

-- 1. Remove rows with missing customer_id
DELETE FROM customers WHERE customer_id IS NULL;

-- 2. Trim and normalize strings
UPDATE customers
SET name = TRIM(name),
    city = TRIM(city),
    country = TRIM(country);

-- 3. Replace N/A or blank with NULL
UPDATE customers
SET name = NULL WHERE name = '' OR name = 'N/A';
UPDATE customers
SET city = NULL WHERE city = '' OR city = 'N/A';
UPDATE customers
SET country = NULL WHERE country = '' OR country = 'N/A';

-- 4. Clean emails: basic format validation
UPDATE customers
SET email = NULL
WHERE email NOT REGEXP '^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$';

-- 5. Clean phone numbers: keep only 10 digits and standardize
UPDATE customers
SET phone = REGEXP_REPLACE(phone, '[^0-9]', '') -- remove non-digits
WHERE phone IS NOT NULL;

UPDATE customers
SET phone = NULL WHERE LENGTH(phone) != 10;

-- Data cleaning in orders table

-- 1. Remove rows with invalid foreign keys
DELETE FROM orders
WHERE customer_id IS NULL OR customer_id NOT IN (SELECT customer_id FROM customers);

DELETE FROM orders
WHERE book_id IS NULL OR book_id NOT IN (SELECT book_id FROM books);

-- 2. Clean quantity: negative or zero -> 1
UPDATE orders
SET quantity = CASE
                  WHEN quantity IS NULL OR quantity <= 0 THEN 1
                  ELSE quantity
               END;

-- 3. Clean order_date: convert to standard DATE format, set invalids to NULL
UPDATE orders
SET order_date = STR_TO_DATE(order_date, '%Y-%m-%d')
WHERE order_date REGEXP '^[0-9]{4}-[0-9]{2}-[0-9]{2}$';

UPDATE orders
SET order_date = STR_TO_DATE(order_date, '%d/%m/%Y')
WHERE order_date REGEXP '^[0-9]{2}/[0-9]{2}/[0-9]{4}$';

-- 4.  Invalid dates -> NULL
UPDATE orders
SET order_date = NULL
WHERE order_date IS NULL OR order_date = '32-13-2020' OR order_date = '';
