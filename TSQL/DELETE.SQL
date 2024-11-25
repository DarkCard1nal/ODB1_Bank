-- Видалення всіх записів із таблиці Interest
DELETE FROM Interest;

-- Видалення всіх записів із таблиці Transactions
DELETE FROM Transactions;

-- Видалення всіх записів із таблиці CurrencyRate
DELETE FROM CurrencyRate;

-- Видалення всіх записів із таблиці Account
DELETE FROM Account;

-- Видалення всіх записів із таблиці Client
DELETE FROM Client;

-- Видалення таблиць у правильному порядку (у разі повного видалення структури БД)
DROP TABLE Interest;
DROP TABLE Transactions;
DROP TABLE CurrencyRate;
DROP TABLE Account;
DROP TABLE Client;
