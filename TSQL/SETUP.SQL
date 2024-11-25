-- Створення таблиці Client
CREATE TABLE Client (
	client_id INT IDENTITY PRIMARY KEY, 
	name VARCHAR(100) NOT NULL,
	address VARCHAR(255),
	phone DECIMAL(18,0) UNIQUE CHECK (phone >= 0),
	email VARCHAR(100) UNIQUE CHECK (email LIKE '%@%')
);

-- Створення таблиці Account
CREATE TABLE Account (
	account_id INT IDENTITY PRIMARY KEY, 
	client_id INT NOT NULL,
	currency VARCHAR(10) NOT NULL, 
	balance DECIMAL(18,2) NOT NULL,
	creation_date DATETIME2 DEFAULT SYSDATETIME(),  
	FOREIGN KEY (client_id) REFERENCES Client(client_id)
);

-- Створення таблиці CurrencyRate
CREATE TABLE CurrencyRate (
	currency_rate_id INT IDENTITY PRIMARY KEY,
	currency_from VARCHAR(10),
	currency_to VARCHAR(10),
	rate DECIMAL(18,2) NOT NULL,
	rate_date DATE DEFAULT CONVERT(DATE, GETDATE()),
	CONSTRAINT unique_currency_pair UNIQUE (currency_from, currency_to, rate_date)
);

-- Створення таблиці Transactions
CREATE TABLE Transactions (
	transaction_id INT IDENTITY PRIMARY KEY, 
	client_id INT NOT NULL,
	account_from_id INT,
	account_to_id INT,
	currency_rate_id INT,
	transaction_type VARCHAR(50),
	amount DECIMAL(18,2) NOT NULL,
	currency VARCHAR(10),
	transaction_date DATETIME2 DEFAULT SYSDATETIME(),
	FOREIGN KEY (client_id) REFERENCES Client(client_id),
	FOREIGN KEY (account_from_id) REFERENCES Account(account_id),
	FOREIGN KEY (account_to_id) REFERENCES Account(account_id),
	FOREIGN KEY (currency_rate_id) REFERENCES CurrencyRate(currency_rate_id)
);

-- Створення таблиці Interest
CREATE TABLE Interest (
	interest_id INT IDENTITY PRIMARY KEY,
	account_id INT NOT NULL,
	transaction_id INT NOT NULL,
	interest_rate DECIMAL(5,2) NOT NULL,
	calculation_date DATE DEFAULT CONVERT(DATE, GETDATE()),
	amount DECIMAL(18,2) NOT NULL,
	FOREIGN KEY (account_id) REFERENCES Account(account_id),
	FOREIGN KEY (transaction_id) REFERENCES Transactions(transaction_id)
);
