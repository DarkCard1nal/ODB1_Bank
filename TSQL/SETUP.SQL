-- Створення таблиці Client
CREATE TABLE Client (
	client_id INT IDENTITY, 
	name VARCHAR(100) NOT NULL,
	address VARCHAR(255),
	phone DECIMAL(18,0),
	email VARCHAR(100),
	CONSTRAINT UQ_Client_Phone UNIQUE (phone),
	CONSTRAINT UQ_Client_Email UNIQUE (email),
	CONSTRAINT CHK_Client_Phone_Positive CHECK (phone >= 0),
	CONSTRAINT CHK_Client_Email_Format CHECK (email LIKE '%@%'),
	CONSTRAINT PK_Client PRIMARY KEY CLUSTERED (client_id)
);
GO

-- Створення таблиці Account
CREATE TABLE Account (
	account_id INT IDENTITY, 
	client_id INT NOT NULL,
	currency VARCHAR(10) NOT NULL, 
	balance DECIMAL(18,2) NOT NULL,
	creation_date DATETIME2 CONSTRAINT DF_Account_CreationDate DEFAULT SYSDATETIME(),
	CONSTRAINT FK_Account_Client FOREIGN KEY (client_id) REFERENCES Client(client_id),
	CONSTRAINT PK_Account PRIMARY KEY CLUSTERED (account_id)
);
GO

-- Створення таблиці CurrencyRate
CREATE TABLE CurrencyRate (
	currency_rate_id INT IDENTITY,
	currency_from VARCHAR(10),
	currency_to VARCHAR(10),
	rate DECIMAL(18,2) NOT NULL,
	rate_date DATE CONSTRAINT DF_CurrencyRate_RateDate DEFAULT CONVERT(DATE, GETDATE()),
	CONSTRAINT UQ_CurrencyRate_Pair UNIQUE (currency_from, currency_to, rate_date),
	CONSTRAINT CHK_Currency_From_To_Different CHECK (currency_from <> currency_to),  -- Tuple constraint
	CONSTRAINT PK_CurrencyRate PRIMARY KEY CLUSTERED (currency_rate_id)
);
GO

-- Створення таблиці Transactions
CREATE TABLE Transactions (
	transaction_id INT IDENTITY, 
	client_id INT NOT NULL,
	account_from_id INT,
	account_to_id INT,
	currency_rate_id INT,
	transaction_type VARCHAR(50),
	amount DECIMAL(18,2) NOT NULL,
	currency VARCHAR(10),
	transaction_date DATETIME2 CONSTRAINT DF_Transactions_TransactionsnDate DEFAULT SYSDATETIME(),
	CONSTRAINT FK_Transactions_Client FOREIGN KEY (client_id) REFERENCES Client(client_id),
	CONSTRAINT FK_Transactions_Account_from FOREIGN KEY (account_from_id) REFERENCES Account(account_id),
	CONSTRAINT FK_Transactions_Account_to FOREIGN KEY (account_to_id) REFERENCES Account(account_id),
	CONSTRAINT FK_Transactions_CurrencyRate FOREIGN KEY (currency_rate_id) REFERENCES CurrencyRate(currency_rate_id),
	CONSTRAINT PK_Transactions PRIMARY KEY CLUSTERED (transaction_id)
);
GO

-- Створення таблиці Interest
CREATE TABLE Interest (
	interest_id INT IDENTITY,
	account_id INT NOT NULL,
	transaction_id INT NOT NULL,
	interest_rate DECIMAL(5,2) NOT NULL,
	amount DECIMAL(18,2) NOT NULL,
	calculation_date DATE CONSTRAINT DF_Interest_InterestDate DEFAULT CONVERT(DATE, GETDATE()),
	CONSTRAINT FK_Interest_Account FOREIGN KEY (account_id) REFERENCES Account(account_id),
	CONSTRAINT FK_Interest_Transactions FOREIGN KEY (transaction_id) REFERENCES Transactions(transaction_id),
	CONSTRAINT PK_Interest PRIMARY KEY CLUSTERED (interest_id)
);
GO

-- Створення таблиці AuditBalanceMismatch (для технічних записів, журнал аудиту та виправлення балансу рахунків)
CREATE TABLE AuditBalanceMismatch (
	audit_id INT IDENTITY PRIMARY KEY,
	account_id INT,
	actual_balance DECIMAL(18,2),
	calculated_balance DECIMAL(18,2),
	discrepancy DECIMAL(18,2),
	log_date DATETIME2 DEFAULT SYSDATETIME()
);
GO

-- Створення таблиці DDL_Log (для технічних записів, журнал DDL операцій CREATE, DROP, ALTER)
CREATE TABLE DDL_Log (
	log_id INT IDENTITY PRIMARY KEY,
	event_type NVARCHAR(100),
	schema_name NVARCHAR(100),
	object_name NVARCHAR(100),
	user_name NVARCHAR(100),
	event_time DATETIME DEFAULT GETDATE()
);
GO

-- Створення таблиці LogonAudit (для технічних записів, журнал аудиту логінів)
CREATE TABLE LogonAudit (
	audit_id INT IDENTITY PRIMARY KEY,
	login_time DATETIME DEFAULT GETDATE(),
	login_name SYSNAME,
	host_name NVARCHAR(255),
	app_name NVARCHAR(255),
	client_ip NVARCHAR(255)
);
GO