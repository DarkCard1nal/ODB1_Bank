SET STATISTICS TIME, IO ON;
GO

PRINT N'--- 1. Check the consistency of transaction records with the account balance ---';
SELECT a.account_id 
FROM Account a
LEFT JOIN (
	-- Counting all credits to the account (Deposit + received Exchanges)
	SELECT account_to_id AS account_id, SUM(amount) AS total_deposited
	FROM Transactions
	WHERE transaction_type IN ('Deposit', 'Exchange', 'Transfer')
	GROUP BY account_to_id
) d ON a.account_id = d.account_id
LEFT JOIN (
	-- Counting all withdrawals from the account (Withdrawals + sent Exchanges)
	SELECT account_from_id AS account_id, SUM(amount) AS total_withdrawn
	FROM Transactions
	WHERE transaction_type IN ('Withdrawal', 'Exchange', 'Transfer')
	GROUP BY account_from_id
) w ON a.account_id = w.account_id
LEFT JOIN (
	-- Calculating accrued interest (Interest)
	SELECT account_to_id AS account_id, SUM(amount) AS total_interest
	FROM Transactions
	WHERE transaction_type = 'Interest'
	GROUP BY account_to_id
) i ON a.account_id = i.account_id
WHERE a.balance <> (COALESCE(d.total_deposited, 0) + COALESCE(i.total_interest, 0) - COALESCE(w.total_withdrawn, 0));
GO

PRINT '--- 2. Find the account with the most transactions ---';
SELECT TOP 1 account_id, COUNT(*) AS operation_count
FROM (
	SELECT account_from_id AS account_id FROM Transactions WHERE account_from_id IS NOT NULL
	UNION ALL
	SELECT account_to_id AS account_id FROM Transactions WHERE account_to_id IS NOT NULL
) t
GROUP BY account_id
ORDER BY operation_count DESC;
GO

PRINT '--- 3. Find accounts that have never been withdrawn from ---';
SELECT a.account_id
FROM Account a
LEFT JOIN Transactions t ON a.account_id = t.account_from_id AND t.transaction_type = 'Withdrawal'
WHERE t.transaction_id IS NULL;
GO

PRINT '--- 4. For a given client, issue a report on all transactions with their accounts ---';
DECLARE @client_id INT = 1;  -- Specify the client ID

SELECT DISTINCT t.transaction_id, t.account_from_id, t.account_to_id, 
	   t.transaction_type, t.amount, t.currency, t.transaction_date
FROM Transactions t
JOIN Account a ON t.account_from_id = a.account_id OR t.account_to_id = a.account_id
WHERE a.client_id = @client_id
ORDER BY t.transaction_date DESC;
GO

PRINT '--- 5. For a given account, convert its balance from one currency to another ---';
DECLARE @account_id INT = 1; -- Account ID
DECLARE @currency_from VARCHAR(10) = 'USD';
DECLARE @currency_to VARCHAR(10) = 'UAH';
DECLARE @rate DECIMAL(18,2);

SELECT @rate = rate
FROM CurrencyRate
WHERE currency_from = @currency_from AND currency_to = @currency_to
ORDER BY rate_date DESC;  -- Taking the last CurrencyRate

SELECT account_id, balance, 
	   balance * @rate AS converted_balance, 
	   @currency_to AS converted_currency
FROM Account
WHERE account_id = @account_id;
GO

PRINT '--- Other requests ---';

PRINT '--- 5 simple T-SQL queries using WHERE ---';
PRINT '--- Get all customers registered at a specific address ---';
SELECT * FROM Client  
WHERE address = '456 Elm St';
GO

PRINT '--- Get all invoices in USD currency ---';
SELECT * FROM Account  
WHERE currency = 'USD';
GO

PRINT '--- Get all transactions that exceed 1000 units in your currency ---';
SELECT * FROM Transactions  
WHERE amount > 1000;
GO

PRINT '--- Get all exchange rates set today ---';
SELECT * FROM CurrencyRate  
WHERE rate_date = CONVERT(DATE, GETDATE());
GO

PRINT '--- Get all records of accrued interest with an interest rate of more than 5% ---';
SELECT * FROM Interest  
WHERE interest_rate > 5.00;
GO

PRINT '--- 5 simple T-SQL queries using WHERE in combination with logical operators AND, OR, NOT ---';
PRINT '--- Get all customers who live in a 456 house or ward and have an email ---';
SELECT * FROM Client  
WHERE address LIKE '456%' AND email IS NOT NULL;
GO

PRINT '--- Get all invoices in USD or EUR ---';
SELECT * FROM Account  
WHERE currency = 'USD' OR currency = 'EUR';
GO

PRINT '--- Get all transactions that are either withdrawals or exchanges ---';
SELECT * FROM Transactions  
WHERE transaction_type = 'Withdrawal' OR transaction_type = 'Exchange';
GO

PRINT '--- Get all currency rates except those related to USD ---';
SELECT * FROM CurrencyRate  
WHERE NOT (currency_from = 'USD' OR currency_to = 'USD');
GO

PRINT '--- Get all records of accrued interest if the rate is more than 5% and the date of accrual is not today ---';
SELECT * FROM Interest  
WHERE interest_rate > 5.00 AND calculation_date <> CONVERT(DATE, GETDATE());
GO

PRINT '--- 5 simple T-SQL queries using the LIKE operator ---';
PRINT '--- Get all customers whose name starts with "A" ---';
SELECT * FROM Client  
WHERE name LIKE 'A%';
GO

PRINT '--- Get all accounts opened in Ukrainian hryvnia (UAH) ---';
SELECT * FROM Account  
WHERE currency LIKE 'UAH';
GO

PRINT '--- Get all customers who have an email on the example.com domain ---';
SELECT * FROM Client  
WHERE email LIKE '%@example.com';
GO

PRINT '--- Get all transactions where the transaction type contains the word Withdrawal ---';
SELECT * FROM Transactions  
WHERE transaction_type LIKE '%Withdrawal%';
GO

PRINT '--- Get all customer addresses that end in "Street" ---';
SELECT * FROM Client  
WHERE address LIKE '%Street';
GO

PRINT '--- 5 simple T-SQL queries using JOIN ---';
PRINT '--- Get a list of all accounts with corresponding customer names ---';
SELECT a.account_id, c.name, a.currency, a.balance  
FROM Account a  
JOIN Client c ON a.client_id = c.client_id;
GO

PRINT '--- Get all transactions along with the names of the customers who made them ---';
SELECT t.transaction_id, c.name, t.transaction_type, t.amount, t.currency, t.transaction_date  
FROM Transactions t  
JOIN Client c ON t.client_id = c.client_id;
GO

PRINT '--- Get all transactions with information about the accounts from which the transactions were made ---';
SELECT t.transaction_id, a.account_id, a.currency, t.amount, t.transaction_date  
FROM Transactions t  
JOIN Account a ON t.account_from_id = a.account_id;
GO

PRINT '--- Get the exchange rate for each Exchange transaction ---';
SELECT t.transaction_id, t.amount, t.currency, cr.currency_from, cr.currency_to, cr.rate  
FROM Transactions t  
JOIN CurrencyRate cr ON t.currency_rate_id = cr.currency_rate_id  
WHERE t.transaction_type = 'Exchange';
GO

PRINT '--- Get a list of accrued interest along with account information ---';
SELECT i.interest_id, a.account_id, i.interest_rate, i.amount, i.calculation_date  
FROM Interest i  
JOIN Account a ON i.account_id = a.account_id;
GO

PRINT '--- 5 simple T-SQL queries using LEFT JOIN, RIGHT JOIN, and FULL JOIN ---';
PRINT '--- Display all accounts and, if available, the corresponding transactions (LEFT JOIN) ---';
SELECT a.account_id, a.balance, t.transaction_id, t.amount, t.transaction_type  
FROM Account a  
LEFT JOIN Transactions t ON a.account_id = t.account_from_id;
GO

PRINT '--- Display all transactions and, if available, the corresponding accounts (RIGHT JOIN) ---';
SELECT t.transaction_id, t.amount, t.transaction_type, a.account_id, a.balance  
FROM Transactions t  
RIGHT JOIN Account a ON t.account_from_id = a.account_id;
GO

PRINT '--- Withdraw all customers and their accounts (LEFT JOIN) ---';
SELECT c.client_id, c.name, a.account_id, a.balance  
FROM Client c  
LEFT JOIN Account a ON c.client_id = a.client_id;
GO

PRINT '--- Display all accounts and, if available, the corresponding customers (RIGHT JOIN) ---';
SELECT c.client_id, c.name, a.account_id, a.balance  
FROM Account a  
RIGHT JOIN Client c ON a.client_id = c.client_id;
GO

PRINT '--- Display all accounts and transactions, even if there is no connection between them (FULL JOIN) ---';
SELECT a.account_id, a.balance, t.transaction_id, t.amount, t.transaction_type  
FROM Account a  
FULL JOIN Transactions t ON a.account_id = t.account_from_id;
GO

PRINT '--- 5 simple T-SQL queries using nested queries (SUBQUERY) ---';
PRINT '--- Get a list of customers who have accounts with a balance of more than 10 000 ---';
SELECT name, client_id  
FROM Client  
WHERE client_id IN (SELECT client_id FROM Account WHERE balance > 10000);
GO

PRINT '--- Withdraw all accounts whose balance exceeds the average balance of all accounts ---';
SELECT account_id, balance  
FROM Account  
WHERE balance > (SELECT AVG(balance) FROM Account);
GO

PRINT '--- Display transactions that exceed the average amount of all transactions ---';
SELECT transaction_id, amount, transaction_type  
FROM Transactions  
WHERE amount > (SELECT AVG(amount) FROM Transactions);
GO

PRINT '--- Withdraw customers who have more than one account ---';
SELECT name, client_id  
FROM Client  
WHERE client_id IN (SELECT client_id FROM Account GROUP BY client_id HAVING COUNT(account_id) > 1);
GO

PRINT '--- Withdraw accounts that have no transactions ---';
SELECT account_id, balance  
FROM Account  
WHERE account_id NOT IN (SELECT DISTINCT account_from_id FROM Transactions WHERE account_from_id IS NOT NULL);
GO

PRINT '--- 5 simple T-SQL queries using GROUP BY and HAVING, including JOIN ---';
PRINT '--- Count the number of accounts for each client ---';
SELECT client_id, COUNT(account_id) AS total_accounts  
FROM Account  
GROUP BY client_id;
GO

PRINT '--- Withdraw customers who have more than one account ---';
SELECT client_id, COUNT(account_id) AS total_accounts  
FROM Account  
GROUP BY client_id  
HAVING COUNT(account_id) > 1;
GO

PRINT '--- Withdraw customers who have made transactions totaling more than 5000 ---';
SELECT client_id, SUM(amount) AS total_transactions  
FROM Transactions  
GROUP BY client_id  
HAVING SUM(amount) > 5000;
GO

PRINT '--- Count the number of transactions of each type ---';
SELECT transaction_type, COUNT(transaction_id) AS total_transactions  
FROM Transactions  
GROUP BY transaction_type;
GO

PRINT '--- Number of accounts of each client ---';
SELECT c.client_id, c.name, COUNT(a.account_id) AS total_accounts  
FROM Client c  
JOIN Account a ON c.client_id = a.client_id  
GROUP BY c.client_id, c.name;
GO

PRINT '--- 5 complex SQL queries that combine JOIN, nested queries, GROUP BY, HAVING, and complex filtering conditions ---';
PRINT '--- Sum of all exchanges of each client for the last 30 days ---';
SELECT c.client_id, c.name, SUM(t.amount) AS total_exchange
FROM Client c  
JOIN Account a ON c.client_id = a.client_id  
JOIN Transactions t ON a.account_id = t.account_to_id  
WHERE t.transaction_type = 'Exchange'  
AND t.transaction_date >= DATEADD(DAY, -30, GETDATE())  
GROUP BY c.client_id, c.name  
HAVING SUM(t.amount) > 0;
GO

PRINT '--- Customers with accounts with an above average balance ---';
SELECT c.client_id, c.name, a.account_id, a.balance  
FROM Client c  
JOIN Account a ON c.client_id = a.client_id  
WHERE a.balance > (SELECT AVG(balance) FROM Account);
GO

PRINT '--- The largest transaction of each client ---';
SELECT t.client_id, c.name, t.transaction_id, t.amount  
FROM Transactions t  
JOIN Client c ON t.client_id = c.client_id  
WHERE t.amount = (  
	SELECT MAX(amount) FROM Transactions WHERE client_id = t.client_id  
);
GO

PRINT '--- Currency rates that have changed by more than 5% in the last 7 days ---';
SELECT cr1.currency_from, cr1.currency_to,  
	   cr1.rate AS latest_rate, cr2.rate AS old_rate,  
	   ABS((cr1.rate - cr2.rate) / cr2.rate * 100) AS rate_change  
FROM CurrencyRate cr1  
JOIN CurrencyRate cr2 ON cr1.currency_from = cr2.currency_from  
AND cr1.currency_to = cr2.currency_to  
AND cr1.rate_date = CONVERT(DATE, GETDATE())  
AND cr2.rate_date = CONVERT(DATE, DATEADD(DAY, -7, GETDATE()))  
WHERE ABS((cr1.rate - cr2.rate) / cr2.rate * 100) > 5;
GO

PRINT '--- Customers with more than one account and at least one transaction ---';
SELECT c.client_id, c.name, COUNT(DISTINCT a.account_id) AS total_accounts  
FROM Client c  
JOIN Account a ON c.client_id = a.client_id  
JOIN Transactions t ON a.account_id = t.account_from_id OR a.account_id = t.account_to_id  
GROUP BY c.client_id, c.name  
HAVING COUNT(DISTINCT a.account_id) > 1 AND COUNT(t.transaction_id) > 0;
GO

PRINT '--- 5 SQL queries that combine JOIN and WHERE to filter data ---';
PRINT '--- Selecting customer transactions with an amount over 1000 ---';
SELECT t.transaction_id, c.name, t.amount, t.transaction_date  
FROM Transactions t  
JOIN Client c ON t.client_id = c.client_id  
WHERE t.amount > 1000;
GO

PRINT '--- Selection of accounts in dollars with a balance over 5000 ---';
SELECT a.account_id, c.name, a.balance, a.currency  
FROM Account a  
JOIN Client c ON a.client_id = c.client_id  
WHERE a.currency = 'USD' AND a.balance > 5000;
GO

PRINT '--- Transactions between accounts of the same client ---';
SELECT t.transaction_id, c.name, t.account_from_id, t.account_to_id, t.amount  
FROM Transactions t  
JOIN Client c ON t.client_id = c.client_id  
JOIN Account a1 ON t.account_from_id = a1.account_id  
JOIN Account a2 ON t.account_to_id = a2.account_id  
WHERE a1.client_id = a2.client_id;
GO

PRINT '--- Selection of the latest transactions for a certain period ---';
SELECT t.transaction_id, c.name, t.amount, t.transaction_date  
FROM Transactions t  
JOIN Client c ON t.client_id = c.client_id  
WHERE t.transaction_date >= DATEADD(DAY, -30, GETDATE());
GO

PRINT '--- Clients who made transactions in dollars ---';
SELECT DISTINCT c.client_id, c.name  
FROM Client c  
JOIN Transactions t ON c.client_id = t.client_id  
WHERE t.currency = 'USD';
GO

PRINT '--- 3 examples of SQL queries using multi-table operations (JOIN, UNION, subqueries) ---';
PRINT '--- Get all transactions with client information ---';
SELECT t.transaction_id, t.transaction_date, t.amount, c.name AS client_name, c.email AS client_email
FROM Transactions t
JOIN Client c ON t.client_id = c.client_id;
GO

PRINT '--- Get all accounts and transactions ---';
SELECT account_id AS record_id, client_id, currency, balance, creation_date 
FROM Account
UNION
SELECT transaction_id AS record_id, client_id, NULL AS currency, amount, transaction_date 
FROM Transactions;
GO

PRINT '--- Get clients with balance greater than average ---';
SELECT c.client_id, c.name, a.balance
FROM Client c
JOIN Account a ON c.client_id = a.client_id
WHERE a.balance > (SELECT AVG(balance) FROM Account);
GO

PRINT '--- 3 queries with cascading actions ---';
-- Creating the Customers table
CREATE TABLE Customers (
    customer_id INT PRIMARY KEY,
    customer_name VARCHAR(100)
);
GO

-- Creating the Orders table with a foreign key referencing Customers
CREATE TABLE Orders (
    order_id INT PRIMARY KEY,
    customer_id INT,
    order_date DATETIME,
    FOREIGN KEY (customer_id)
    REFERENCES Customers(customer_id)
    ON DELETE CASCADE
    ON UPDATE CASCADE
);
GO

-- Inserting data into the Customers table
INSERT INTO Customers (customer_id, customer_name)
VALUES (1, 'John Doe'), (2, 'Jane Smith');
GO

-- Inserting data into the Orders table
INSERT INTO Orders (order_id, customer_id, order_date)
VALUES (101, 1, '2025-04-01'), (102, 2, '2025-04-02');
GO

-- Deleting the customer with customer_id = 1 from the Customers table
PRINT '--- Deleting customer with customer_id = 1 ---';
DELETE FROM Customers WHERE customer_id = 1;
GO

-- Checking the result in the Orders table
PRINT '--- Checking Orders table after deleting customer ---';
SELECT * FROM Orders;
GO

-- Updating customer_id from 2 to 1 in the Customers table
PRINT '--- Updating customer_id from 2 to 1 in Customers table ---';
UPDATE Customers SET customer_id = 1 WHERE customer_id = 2;
GO

-- Checking the result in the Orders table
PRINT '--- Checking Orders table after updating customer_id ---';
SELECT * FROM Orders;
GO

-- Deleting all records from the tables
DELETE FROM Orders;
DELETE FROM Customers;
GO

PRINT '--- 3 SQL queries that use the ORDER BY statement to sort data by various criteria, following the T-SQL template ---';
PRINT '--- Get all clients sorted by name in ascending order ---';
SELECT * FROM Client
ORDER BY name ASC;
GO

PRINT '--- Get all transactions sorted by amount in descending order ---';
SELECT * FROM Transactions
ORDER BY amount DESC;
GO

PRINT '--- Get all accounts sorted by balance in descending order and by creation date in ascending order ---';
SELECT * FROM Account
ORDER BY balance DESC, creation_date ASC;
GO


PRINT '--- 3 SQL queries that use Boolean (AND, OR, NOT) and relational (=, >, <, >=, <=, <>) operators in T-SQL ---';
PRINT '--- Get all clients who have both email and phone number ---';
SELECT * FROM Client
WHERE email IS NOT NULL AND phone IS NOT NULL;
GO

PRINT '--- Get all transactions where amount is greater than 1000 or currency is USD ---';
SELECT * FROM Transactions
WHERE amount > 1000 OR currency = 'USD';
GO

PRINT '--- Get all accounts where balance is not zero and creation date is not today ---';
SELECT * FROM Account
WHERE balance <> 0 AND creation_date <> CONVERT(DATE, GETDATE());
GO

PRINT '--- 3 SQL queries that use different types of JOIN in T-SQL ---';
PRINT '--- Get all clients with their accounts, including those without accounts ---';
SELECT c.client_id, c.name, a.account_id, a.currency, a.balance
FROM Client c
LEFT JOIN Account a ON c.client_id = a.client_id;
GO

PRINT '--- Get all transactions with their exchange rates, including transactions without rates ---';
SELECT t.transaction_id, t.amount, t.currency, cr.currency_from, cr.currency_to, cr.rate
FROM Transactions t
RIGHT JOIN CurrencyRate cr ON t.currency_rate_id = cr.currency_rate_id;
GO

PRINT '--- Get all accounts with clients and transactions, including unmatched records ---';
SELECT a.account_id, a.currency, a.balance, c.name, t.transaction_id, t.amount
FROM Account a
FULL JOIN Transactions t ON a.account_id = t.account_from_id OR a.account_id = t.account_to_id
FULL JOIN Client c ON a.client_id = c.client_id;
GO

PRINT '--- 5 SQL queries using GROUP BY and HAVING in combination with JOIN ---';
PRINT '--- Get clients with more than one account ---';
SELECT c.client_id, c.name, COUNT(a.account_id) AS account_count
FROM Client c
JOIN Account a ON c.client_id = a.client_id
GROUP BY c.client_id, c.name
HAVING COUNT(a.account_id) > 1;
GO

PRINT '--- Get total balance per currency where total is more than 10 000 ---';
SELECT a.currency, SUM(a.balance) AS total_balance
FROM Account a
GROUP BY a.currency
HAVING SUM(a.balance) > 10000;
GO

PRINT '--- Get clients with more than 5 transactions ---';
SELECT c.client_id, c.name, COUNT(t.transaction_id) AS transaction_count
FROM Client c
JOIN Transactions t ON c.client_id = t.client_id
GROUP BY c.client_id, c.name
HAVING COUNT(t.transaction_id) > 5;
GO

PRINT '--- Get currency pairs with average rate higher than 1.5 ---';
SELECT cr.currency_from, cr.currency_to, AVG(cr.rate) AS avg_rate
FROM CurrencyRate cr
GROUP BY cr.currency_from, cr.currency_to
HAVING AVG(cr.rate) > 1.5;
GO

PRINT '--- Get accounts with total interest amount greater than 500 ---';
SELECT i.account_id, SUM(i.amount) AS total_interest
FROM Interest i
GROUP BY i.account_id
HAVING SUM(i.amount) > 500;
GO

SET STATISTICS TIME, IO OFF;
GO