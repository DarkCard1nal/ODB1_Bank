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
	SELECT account_from_id AS account_id FROM Transactions WHERE account_from_id IS NOT NULL
	UNION ALL
	SELECT account_to_id AS account_id FROM Transactions WHERE account_to_id IS NOT NULL
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

-- Інші запити

-- 5 простих T-SQL запитів із використанням WHERE
-- Отримати всіх клієнтів, які зареєстровані за певною адресою
SELECT * FROM Client  
WHERE address = '456 Elm St';

-- Отримати всі рахунки у валюті USD
SELECT * FROM Account  
WHERE currency = 'USD';

-- Отримати всі транзакції, які перевищують 1000 одиниць у своїй валюті
SELECT * FROM Transactions  
WHERE amount > 1000;

-- Отримати всі курси валют, встановлені сьогодні
SELECT * FROM CurrencyRate  
WHERE rate_date = CONVERT(DATE, GETDATE());

-- Отримати всі записи про нараховані відсотки з процентною ставкою понад 5%
SELECT * FROM Interest  
WHERE interest_rate > 5.00;

-- 5 простих T-SQL запитів із використанням WHERE у поєднанні з логічними операторами AND, OR, NOT
-- Отримати всіх клієнтів, які проживають у 456 домі або вуриці та мають email
SELECT * FROM Client  
WHERE address LIKE '456%' AND email IS NOT NULL;

-- Отримати всі рахунки у валютах USD або EUR
SELECT * FROM Account  
WHERE currency = 'USD' OR currency = 'EUR';

-- Отримати всі транзакції, що є або зняттям коштів (Withdrawal), або обміном валют (Exchange)
SELECT * FROM Transactions  
WHERE transaction_type = 'Withdrawal' OR transaction_type = 'Exchange';

-- Отримати всі курси валют, крім тих, що стосуються USD
SELECT * FROM CurrencyRate  
WHERE NOT (currency_from = 'USD' OR currency_to = 'USD');

-- Отримати всі записи про нараховані відсотки, якщо ставка більше 5% і дата нарахування не сьогодні
SELECT * FROM Interest  
WHERE interest_rate > 5.00 AND calculation_date <> CONVERT(DATE, GETDATE());

-- 5 простих T-SQL запитів із використанням оператора LIKE
-- Отримати всіх клієнтів, чиє ім'я починається на «A»
SELECT * FROM Client  
WHERE name LIKE 'A%';

-- Отримати всі рахунки, відкриті у гривні (UAH)
SELECT * FROM Account  
WHERE currency LIKE 'UAH';

-- Отримати всіх клієнтів, які мають email на домені example.com
SELECT * FROM Client  
WHERE email LIKE '%@example.com';

-- Отримати всі транзакції, у яких тип операції містить слово Withdrawal
SELECT * FROM Transactions  
WHERE transaction_type LIKE '%Withdrawal%';

-- Отримати всі адреси клієнтів, у яких назва закінчується на «Street»
SELECT * FROM Client  
WHERE address LIKE '%Street';

-- 5 простих T-SQL запитів із використанням JOIN
-- Отримати список усіх рахунків із відповідними іменами клієнтів
SELECT a.account_id, c.name, a.currency, a.balance  
FROM Account a  
JOIN Client c ON a.client_id = c.client_id;

-- Отримати всі транзакції разом з іменами клієнтів, які їх здійснили
SELECT t.transaction_id, c.name, t.transaction_type, t.amount, t.currency, t.transaction_date  
FROM Transactions t  
JOIN Client c ON t.client_id = c.client_id;

-- Отримати всі транзакції з інформацією про рахунки, з яких здійснювалися операції
SELECT t.transaction_id, a.account_id, a.currency, t.amount, t.transaction_date  
FROM Transactions t  
JOIN Account a ON t.account_from_id = a.account_id;

-- Отримати курс обміну валют для кожної операції обміну (Exchange)
SELECT t.transaction_id, t.amount, t.currency, cr.currency_from, cr.currency_to, cr.rate  
FROM Transactions t  
JOIN CurrencyRate cr ON t.currency_rate_id = cr.currency_rate_id  
WHERE t.transaction_type = 'Exchange';

-- Отримати список нарахованих відсотків разом з інформацією про рахунок
SELECT i.interest_id, a.account_id, i.interest_rate, i.amount, i.calculation_date  
FROM Interest i  
JOIN Account a ON i.account_id = a.account_id;

-- 5 простих T-SQL запитів із використанням LEFT JOIN, RIGHT JOIN і FULL JOIN
-- Вивести всі рахунки та, якщо є, відповідні транзакції (LEFT JOIN)
SELECT a.account_id, a.balance, t.transaction_id, t.amount, t.transaction_type  
FROM Account a  
LEFT JOIN Transactions t ON a.account_id = t.account_from_id;

-- Вивести всі транзакції та, якщо є, відповідні рахунки (RIGHT JOIN)
SELECT t.transaction_id, t.amount, t.transaction_type, a.account_id, a.balance  
FROM Transactions t  
RIGHT JOIN Account a ON t.account_from_id = a.account_id;

-- Вивести всіх клієнтів і їхні рахунки (LEFT JOIN)
SELECT c.client_id, c.name, a.account_id, a.balance  
FROM Client c  
LEFT JOIN Account a ON c.client_id = a.client_id;

-- Вивести всі рахунки та, якщо є, відповідні клієнти (RIGHT JOIN)
SELECT c.client_id, c.name, a.account_id, a.balance  
FROM Account a  
RIGHT JOIN Client c ON a.client_id = c.client_id;

-- Вивести всі рахунки та транзакції, навіть якщо немає зв’язку між ними (FULL JOIN)
SELECT a.account_id, a.balance, t.transaction_id, t.amount, t.transaction_type  
FROM Account a  
FULL JOIN Transactions t ON a.account_id = t.account_from_id;

-- 5 простих T-SQL запитів із використанням вкладених запитів (SUBQUERY)
-- Отримати список клієнтів, у яких є рахунки з балансом більше 10 000
SELECT name, client_id  
FROM Client  
WHERE client_id IN (SELECT client_id FROM Account WHERE balance > 10000);

-- Вивести всі рахунки, баланс яких перевищує середній баланс усіх рахунків
SELECT account_id, balance  
FROM Account  
WHERE balance > (SELECT AVG(balance) FROM Account);

-- Вивести транзакції, сума яких перевищує середню суму всіх транзакцій
SELECT transaction_id, amount, transaction_type  
FROM Transactions  
WHERE amount > (SELECT AVG(amount) FROM Transactions);

-- Вивести клієнтів, у яких є більше одного рахунку
SELECT name, client_id  
FROM Client  
WHERE client_id IN (SELECT client_id FROM Account GROUP BY client_id HAVING COUNT(account_id) > 1);

-- Вивести рахунки, які не мають жодної транзакції
SELECT account_id, balance  
FROM Account  
WHERE account_id NOT IN (SELECT DISTINCT account_from_id FROM Transactions WHERE account_from_id IS NOT NULL);

-- 5 простих T-SQL запитів із використанням GROUP BY та HAVING, у тому числі з JOIN
-- Підрахувати кількість рахунків у кожного клієнта
SELECT client_id, COUNT(account_id) AS total_accounts  
FROM Account  
GROUP BY client_id;

-- Вивести клієнтів, у яких більше одного рахунку
SELECT client_id, COUNT(account_id) AS total_accounts  
FROM Account  
GROUP BY client_id  
HAVING COUNT(account_id) > 1;

-- Вивести клієнтів, які здійснили транзакції на загальну суму понад 5000
SELECT client_id, SUM(amount) AS total_transactions  
FROM Transactions  
GROUP BY client_id  
HAVING SUM(amount) > 5000;

-- Підрахувати кількість транзакцій кожного типу
SELECT transaction_type, COUNT(transaction_id) AS total_transactions  
FROM Transactions  
GROUP BY transaction_type;

-- Кількість рахунків кожного клієнта
SELECT c.client_id, c.name, COUNT(a.account_id) AS total_accounts  
FROM Client c  
JOIN Account a ON c.client_id = a.client_id  
GROUP BY c.client_id, c.name;

-- 5 складних SQL-запитів, які комбінують JOIN, вкладені запити, GROUP BY, HAVING та складні умови фільтрації
-- Сума всіх Exchange кожного клієнта за останні 30 днів
SELECT c.client_id, c.name, SUM(t.amount) AS total_exchange
FROM Client c  
JOIN Account a ON c.client_id = a.client_id  
JOIN Transactions t ON a.account_id = t.account_to_id  
WHERE t.transaction_type = 'Exchange'  
AND t.transaction_date >= DATEADD(DAY, -30, GETDATE())  
GROUP BY c.client_id, c.name  
HAVING SUM(t.amount) > 0;

-- Клієнти, які мають рахунки з балансом вище середнього
SELECT c.client_id, c.name, a.account_id, a.balance  
FROM Client c  
JOIN Account a ON c.client_id = a.client_id  
WHERE a.balance > (SELECT AVG(balance) FROM Account);

-- Найбільша транзакція кожного клієнта
SELECT t.client_id, c.name, t.transaction_id, t.amount  
FROM Transactions t  
JOIN Client c ON t.client_id = c.client_id  
WHERE t.amount = (  
	SELECT MAX(amount) FROM Transactions WHERE client_id = t.client_id  
);

-- Курси валют, які змінювалися більше ніж на 5% за останні 7 днів
SELECT cr1.currency_from, cr1.currency_to,  
	   cr1.rate AS latest_rate, cr2.rate AS old_rate,  
	   ABS((cr1.rate - cr2.rate) / cr2.rate * 100) AS rate_change  
FROM CurrencyRate cr1  
JOIN CurrencyRate cr2 ON cr1.currency_from = cr2.currency_from  
AND cr1.currency_to = cr2.currency_to  
AND cr1.rate_date = CONVERT(DATE, GETDATE())  
AND cr2.rate_date = CONVERT(DATE, DATEADD(DAY, -7, GETDATE()))  
WHERE ABS((cr1.rate - cr2.rate) / cr2.rate * 100) > 5;

-- Клієнти, які мають більше одного рахунку та хоча б одну транзакцію
SELECT c.client_id, c.name, COUNT(DISTINCT a.account_id) AS total_accounts  
FROM Client c  
JOIN Account a ON c.client_id = a.client_id  
JOIN Transactions t ON a.account_id = t.account_from_id OR a.account_id = t.account_to_id  
GROUP BY c.client_id, c.name  
HAVING COUNT(DISTINCT a.account_id) > 1 AND COUNT(t.transaction_id) > 0;

-- 5 SQL-запитів, що комбінують JOIN та WHERE для фільтрації даних
-- Вибірка транзакцій клієнтів із сумою більше 1000
SELECT t.transaction_id, c.name, t.amount, t.transaction_date  
FROM Transactions t  
JOIN Client c ON t.client_id = c.client_id  
WHERE t.amount > 1000;

-- Вибірка рахунків у доларах із балансом понад 5000
SELECT a.account_id, c.name, a.balance, a.currency  
FROM Account a  
JOIN Client c ON a.client_id = c.client_id  
WHERE a.currency = 'USD' AND a.balance > 5000;

-- Транзакції між рахунками одного клієнта
SELECT t.transaction_id, c.name, t.account_from_id, t.account_to_id, t.amount  
FROM Transactions t  
JOIN Client c ON t.client_id = c.client_id  
JOIN Account a1 ON t.account_from_id = a1.account_id  
JOIN Account a2 ON t.account_to_id = a2.account_id  
WHERE a1.client_id = a2.client_id;

-- Вибірка останніх транзакцій за певний період
SELECT t.transaction_id, c.name, t.amount, t.transaction_date  
FROM Transactions t  
JOIN Client c ON t.client_id = c.client_id  
WHERE t.transaction_date >= DATEADD(DAY, -30, GETDATE());

-- Клієнти, які здійснили транзакції у доларах
SELECT DISTINCT c.client_id, c.name  
FROM Client c  
JOIN Transactions t ON c.client_id = t.client_id  
WHERE t.currency = 'USD';
