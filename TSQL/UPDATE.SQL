-- Оновлення адреси клієнта
UPDATE Client
SET address = '789 Oak St'
WHERE client_id = 1;

-- Оновлення балансу рахунку після будь-якої транзакції
UPDATE Account
SET balance = balance + 500.00 --(сума транзакції)
WHERE account_id = 1;
