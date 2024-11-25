-- Додавання записів у таблицю Client
INSERT INTO Client (name, address, phone, email)
VALUES 
('John Doe', '123 Main St', 1234567890, 'john.doe@example.com'),
('Jane Smith', '456 Elm St', 9876543210, 'jane.smith@example.com');

-- Додавання записів у таблицю Account
INSERT INTO Account (client_id, currency, balance)
VALUES
(1, 'USD', 1500.00),
(1, 'UAH', 2000.00),
(2, 'UAH', 5000.00);

-- Додавання записів у таблицю CurrencyRate
INSERT INTO CurrencyRate (currency_from, currency_to, rate)
VALUES
('USD', 'UAH', 36.50),
('UAH', 'USD', 0.02);

-- Додаємо транзакції для нарахування відсотків в Interest
INSERT INTO Transactions (client_id, account_from_id, account_to_id, currency_rate_id, transaction_type, amount, currency)
SELECT 
	1 AS client_id, -- ID клієнта
	NULL AS account_from_id, -- Рахунок відправника
	1 AS account_to_id, -- Рахунок отримувача
	NULL AS currency_rate_id, -- Поле залишаємо NULL, якщо курс не потрібен
	'Interest' AS transaction_type, -- Тип транзакції
	a_to.balance*1.1 AS amount, -- Сума транзакції нараховано 10%
	a_to.currency AS currency -- Валюта з рахунку відправника
FROM 
	Account a_to
WHERE 
	a_to.account_id = 1; -- ID рахунку відправника

INSERT INTO Transactions (client_id, account_from_id, account_to_id, currency_rate_id, transaction_type, amount, currency)
SELECT 
	1 AS client_id, -- ID клієнта
	NULL AS account_from_id, -- Рахунок відправника
	2 AS account_to_id, -- Рахунок отримувача
	NULL AS currency_rate_id, -- Поле залишаємо NULL, якщо курс не потрібен
	'Interest' AS transaction_type, -- Тип транзакції
	a_to.balance*1.1 AS amount, -- Сума транзакції нараховано 10%
	a_to.currency AS currency -- Валюта з рахунку відправника
FROM 
	Account a_to
WHERE 
	a_to.account_id = 2; -- ID рахунку відправника


-- Додавання записів у таблицю Transactions
INSERT INTO Transactions (client_id, account_from_id, account_to_id, currency_rate_id, transaction_type, amount, currency)
SELECT 
	1 AS client_id, -- ID клієнта
	1 AS account_from_id, -- Рахунок, з якого виконується транзакція
	2 AS account_to_id, -- Рахунок, на який виконується транзакція
	(SELECT TOP 1 currency_rate_id 
	FROM CurrencyRate cr
	WHERE cr.currency_from = a_from.currency AND cr.currency_to = a_to.currency
	ORDER BY cr.rate_date DESC) AS currency_rate_id, -- Найсвіжіший курс
	'Exchange' AS transaction_type, -- Тип транзакції
	500.00 AS amount, -- Сума
	a_from.currency AS currency -- Валюта з рахунку відправника
FROM 
	Account a_from
JOIN 
	Account a_to ON a_to.account_id = 2 -- Зв’язуємо з рахунком отримувача
WHERE 
	a_from.account_id = 1; -- Вказуємо рахунок відправника

INSERT INTO Transactions (client_id, account_from_id, account_to_id, currency_rate_id, transaction_type, amount, currency)
SELECT 
	1 AS client_id, -- ID клієнта
	2 AS account_from_id, -- Рахунок відправника
	3 AS account_to_id, -- Рахунок отримувача
	NULL AS currency_rate_id, -- Поле залишаємо NULL, якщо курс не потрібен
	'Transfer' AS transaction_type, -- Тип транзакції
	1000.00 AS amount, -- Сума транзакції
	a_from.currency AS currency -- Валюта з рахунку відправника
FROM 
	Account a_from
WHERE 
	a_from.account_id = 2; -- ID рахунку відправника

-- Важливо оновити баланси після кожної створеної транзакції (приклад в UPDATE.SQL)!

-- Додавання записів у таблицю Interest
INSERT INTO Interest (account_id, transaction_id, interest_rate, amount)
SELECT 
    t.account_to_id AS account_id, -- Рахунок отримувача (з account_to_id транзакції)
    t.transaction_id,              -- ID транзакції
    1.10 AS interest_rate,         -- Ставка відсотків
    t.amount / 1.10 AS amount      -- Розрахунок суми: транзакція поділена на 1.10
FROM 
    Transactions t
WHERE 
    t.transaction_type = 'Interest'; -- Враховуємо лише транзакції типу "Interest"
