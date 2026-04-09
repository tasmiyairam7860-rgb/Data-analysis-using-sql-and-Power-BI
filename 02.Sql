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

-- QUERIES 

-- 1) Retrieve all books in the "Fiction" genre:

SELECT * FROM Books 
WHERE Genre='Fiction';

-- 2) Find books published after the year 1950:
SELECT * FROM Books 
WHERE Published_year>1950;

-- 3) List all customers from the Canada:
SELECT * FROM Customers 
WHERE country='Canada';


-- 4) Show orders placed in November 2023:

SELECT * FROM Orders 
WHERE order_date BETWEEN '2023-11-01' AND '2023-11-30';

-- 5) Retrieve the total stock of books available:

SELECT SUM(stock) AS Total_Stock
From Books;


-- 6) Find the details of the most expensive book:
SELECT * FROM Books 
ORDER BY Price DESC 
LIMIT 1;


-- 7) Show all customers who ordered more than 1 quantity of a book:
SELECT * FROM Orders 
WHERE quantity>1;



-- 8) Retrieve all orders where the total amount exceeds $20:
SELECT * FROM Orders 
WHERE total_amount>20;



-- 9) List all genres available in the Books table:
SELECT DISTINCT genre FROM Books;


-- 10) Find the book with the lowest stock:
SELECT * FROM Books 
ORDER BY stock 
LIMIT 1;

- 11) Calculate the total revenue generated from all orders:
SELECT SUM(total_amount) As Revenue 
FROM Orders;

-- Advance Questions : 

-- 1) Retrieve the total number of books sold for each genre:

SELECT * FROM ORDERS;

SELECT b.Genre, SUM(o.Quantity) AS Total_Books_sold
FROM Orders o
JOIN Books b ON o.book_id = b.book_id
GROUP BY b.Genre;


-- 2) Find the average price of books in the "Fantasy" genre:
SELECT AVG(price) AS Average_Price
FROM Books
WHERE Genre = 'Fantasy';


-- 3) List customers who have placed at least 2 orders:
SELECT o.customer_id, c.name, COUNT(o.Order_id) AS ORDER_COUNT
FROM orders o
JOIN customers c ON o.customer_id=c.customer_id
GROUP BY o.customer_id, c.name
HAVING COUNT(Order_id) >=2;




-- 4) Find the most frequently ordered book:
SELECT o.Book_id, b.title, COUNT(o.order_id) AS ORDER_COUNT
FROM orders o
JOIN books b ON o.book_id=b.book_id
GROUP BY o.book_id, b.title
ORDER BY ORDER_COUNT DESC LIMIT 1;



-- 5) Show the top 3 most expensive books of 'Fantasy' Genre :
SELECT * FROM books
WHERE genre ='Fantasy'
ORDER BY price DESC LIMIT 3;


-- 6) Retrieve the total quantity of books sold by each author:

SELECT b.author, SUM(o.quantity) AS Total_Books_Sold
FROM orders o
JOIN books b ON o.book_id=b.book_id
GROUP BY b.Author;





-- 7) List the cities where customers who spent over $30 are located:

SELECT DISTINCT c.city, total_amount
FROM orders o
JOIN customers c ON o.customer_id=c.customer_id
WHERE o.total_amount > 30;


-- 8) Find the customer who spent the most on orders:
SELECT c.customer_id, c.name, SUM(o.total_amount) AS Total_Spent
FROM orders o
JOIN customers c ON o.customer_id=c.customer_id
GROUP BY c.customer_id, c.name
ORDER BY Total_spent Desc LIMIT 1;


--9) Calculate the stock remaining after fulfilling all orders:

SELECT b.book_id, b.title, b.stock, COALESCE(SUM(o.quantity),0) AS Order_quantity,  
	b.stock- COALESCE(SUM(o.quantity),0) AS Remaining_Quantity
FROM books b
LEFT JOIN orders o ON b.book_id=o.book_id
GROUP BY b.book_id ORDER BY b.book_id;
