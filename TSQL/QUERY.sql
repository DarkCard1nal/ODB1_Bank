-- 1. Перевірити узгодженість записів про операції зі станом балансу рахунку
SELECT a.account_id 
FROM Account a
LEFT JOIN (
    -- Підрахунок усіх зарахувань на рахунок (Deposit + отримані Exchange)
    SELECT account_to_id AS account_id, SUM(amount) AS total_deposited
    FROM Transactions
    WHERE transaction_type IN ('Deposit', 'Exchange', 'Transfer')
    GROUP BY account_to_id
) d ON a.account_id = d.account_id
LEFT JOIN (
    -- Підрахунок усіх списань з рахунку (Withdrawal + відправлені Exchange)
    SELECT account_from_id AS account_id, SUM(amount) AS total_withdrawn
    FROM Transactions
    WHERE transaction_type IN ('Withdrawal', 'Exchange', 'Transfer')
    GROUP BY account_from_id
) w ON a.account_id = w.account_id
LEFT JOIN (
    -- Підрахунок нарахованих відсотків (Interest)
    SELECT account_to_id AS account_id, SUM(amount) AS total_interest
    FROM Transactions
    WHERE transaction_type = 'Interest'
    GROUP BY account_to_id
) i ON a.account_id = i.account_id
WHERE a.balance <> (COALESCE(d.total_deposited, 0) + COALESCE(i.total_interest, 0) - COALESCE(w.total_withdrawn, 0));


-- 2. Знайти рахунок, з яким здійснено найбільше операцій
SELECT TOP 1 account_id, COUNT(*) AS operation_count
FROM (
    SELECT account_from_id AS account_id FROM Transactions
    UNION ALL
    SELECT account_to_id AS account_id FROM Transactions
) t
GROUP BY account_id
ORDER BY operation_count DESC;

-- 3. Знайти рахунки, з яких ніколи не знімали кошти
SELECT a.account_id
FROM Account a
LEFT JOIN Transactions t ON a.account_id = t.account_from_id AND t.transaction_type = 'Withdrawal'
WHERE t.transaction_id IS NULL;

-- 4. Для даного клієнта видати звіт про всі операції з його рахунками
DECLARE @client_id INT = 1;  -- Вкажіть ID клієнта

SELECT DISTINCT t.transaction_id, t.account_from_id, t.account_to_id, 
       t.transaction_type, t.amount, t.currency, t.transaction_date
FROM Transactions t
JOIN Account a ON t.account_from_id = a.account_id OR t.account_to_id = a.account_id
WHERE a.client_id = @client_id
ORDER BY t.transaction_date DESC;


-- 5. Для даного рахунку перерахувати його баланс з однієї валюти в іншу
DECLARE @account_id INT = 1; -- ID рахунку
DECLARE @currency_from VARCHAR(10) = 'USD';
DECLARE @currency_to VARCHAR(10) = 'UAH';
DECLARE @rate DECIMAL(18,2);

SELECT @rate = rate
FROM CurrencyRate
WHERE currency_from = @currency_from AND currency_to = @currency_to
ORDER BY rate_date DESC;  -- Беремо останній курс

SELECT account_id, balance, 
       balance * @rate AS converted_balance, 
       @currency_to AS converted_currency
FROM Account
WHERE account_id = @account_id;

