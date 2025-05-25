--SET STATISTICS TIME, IO ON;
GO

USE master;
GO

SET QUOTED_IDENTIFIER ON;
GO

PRINT '--- CREATING PROCEDURES ---';
GO

PRINT '--- 3 global temporary stored procedures ---';
PRINT '--- 1. Global procedure for withdrawing all clients ---';
GO
IF OBJECT_ID('tempdb..##GetAllClients') IS NOT NULL
	DROP PROCEDURE ##GetAllClients;
GO

CREATE PROCEDURE ##GetAllClients
AS
BEGIN
	SELECT * FROM Client;
END;
GO

PRINT '--- 2. Global procedure for calculating the total balance in the Account table ---';
GO
IF OBJECT_ID('tempdb..##GetTotalBalance') IS NOT NULL
	DROP PROCEDURE ##GetTotalBalance;
GO

CREATE PROCEDURE ##GetTotalBalance
AS
BEGIN
	SELECT SUM(balance) AS total_balance FROM Account;
END;
GO

PRINT '--- 3. Global procedure to retrieve the last 5 transactions ---';
GO
IF OBJECT_ID('tempdb..##GetLatestTransactions') IS NOT NULL
	DROP PROCEDURE ##GetLatestTransactions;
GO

CREATE PROCEDURE ##GetLatestTransactions
AS
BEGIN
	SELECT TOP 5 * 
	FROM Transactions
	ORDER BY transaction_date DESC;
END;
GO

PRINT '--- 3 local temporary stored procedures ---';
PRINT '--- 1. Temporary procedure for viewing customer accounts ---';
GO
IF OBJECT_ID('tempdb..#GetClientAccounts') IS NOT NULL
	DROP PROCEDURE #GetClientAccounts;
GO

CREATE PROCEDURE #GetClientAccounts
	@ClientId INT
AS
BEGIN
	SELECT * FROM Account WHERE client_id = @ClientId;
END;
GO

PRINT '--- 2. Temporary procedure for counting client transactions ---';
GO
IF OBJECT_ID('tempdb..#CountClientTransactions') IS NOT NULL
	DROP PROCEDURE #CountClientTransactions;
GO

CREATE PROCEDURE #CountClientTransactions
	@ClientId INT
AS
BEGIN
	SELECT COUNT(*) AS total_transactions
	FROM Transactions
	WHERE client_id = @ClientId;
END;
GO

PRINT '--- 3. Temporary procedure for viewing the history of currency exchange rate changes ---';
GO
IF OBJECT_ID('tempdb..#GetCurrencyHistory') IS NOT NULL
	DROP PROCEDURE #GetCurrencyHistory;
GO

CREATE PROCEDURE #GetCurrencyHistory
	@CurrencyFrom VARCHAR(10),
	@CurrencyTo VARCHAR(10)
AS
BEGIN
	SELECT * 
	FROM CurrencyRate
	WHERE currency_from = @CurrencyFrom AND currency_to = @CurrencyTo
	ORDER BY rate_date DESC;
END;
GO

PRINT '--- 3 user-defined stored procedures parts of the Transaction---';
PRINT '--- 1. Procedure for making a transfer between customer accounts ---';
GO
CREATE PROCEDURE dbo.PerformTransaction
	@FromAccountId INT,
	@ToAccountId INT,
	@Amount DECIMAL(18,2),
	@CurrencyRateId INT,
	@ClientId INT
AS
BEGIN
	BEGIN TRANSACTION;

	BEGIN TRY
		-- Reducing the balance on the sending account
		UPDATE Account
		SET balance = balance - @Amount
		WHERE account_id = @FromAccountId;

		-- Getting the exchange rate
		DECLARE @Rate DECIMAL(18,2);
		SELECT @Rate = rate FROM CurrencyRate WHERE currency_rate_id = @CurrencyRateId;

		-- Increase in the balance on the recipient account based on the exchange rate
		UPDATE Account
		SET balance = balance + (@Amount * @Rate)
		WHERE account_id = @ToAccountId;

		-- Writing to the transaction table
		INSERT INTO Transactions (client_id, account_from_id, account_to_id, currency_rate_id, transaction_type, amount, currency)
		VALUES (@ClientId, @FromAccountId, @ToAccountId, @CurrencyRateId, 'Transfer', @Amount, (SELECT currency FROM Account WHERE account_id = @FromAccountId));

		COMMIT;
	END TRY
	BEGIN CATCH
		ROLLBACK;
		THROW;
	END CATCH
END;
GO

PRINT '--- 2. The procedure for calculating interest by the bank ---';
GO
CREATE PROCEDURE dbo.ApplyInterestToAccounts
	@InterestRate DECIMAL(5,2)
AS
BEGIN
	SET NOCOUNT ON;

	DECLARE @AccountId INT, 
			@Balance DECIMAL(18,2), 
			@InterestAmount DECIMAL(18,2), 
			@TransactionId INT,
			@ClientId INT,
			@Currency VARCHAR(10),
			@Counter INT = 0;

	DECLARE account_cursor CURSOR FOR
	SELECT account_id, balance, client_id, currency FROM Account;

	OPEN account_cursor;
	FETCH NEXT FROM account_cursor INTO @AccountId, @Balance, @ClientId, @Currency;

	WHILE @@FETCH_STATUS = 0
	BEGIN
		-- Calculate interest amount
		SET @InterestAmount = @Balance * (@InterestRate / 100);

		-- Insert into Transactions table
		INSERT INTO Transactions (
			client_id, account_from_id, account_to_id, currency_rate_id, 
			transaction_type, amount, currency
		)
		VALUES (
			@ClientId, 
			NULL, 
			@AccountId, 
			NULL, 
			'Interest', 
			@InterestAmount, 
			@Currency
		);

		-- Get the transaction ID of the just inserted record
		SET @TransactionId = SCOPE_IDENTITY();

		-- Insert into Interest table
		INSERT INTO Interest (account_id, transaction_id, interest_rate, amount)
		VALUES (@AccountId, @TransactionId, @InterestRate, @InterestAmount);

		-- Update the account balance
		UPDATE Account
		SET balance = balance + @InterestAmount
		WHERE account_id = @AccountId;

		-- Move to the next account
		FETCH NEXT FROM account_cursor INTO @AccountId, @Balance, @ClientId, @Currency;
		SET @Counter = @Counter + 1;
	END;

	PRINT CONCAT('Calculated interest account #', @Counter);

	CLOSE account_cursor;
	DEALLOCATE account_cursor;
END;
GO

PRINT '--- 3. The procedure for adding the exchange rate for a new day ---';
GO
CREATE PROCEDURE dbo.SetCurrencyRateForNewDay
	@CurrencyFrom VARCHAR(10),
	@CurrencyTo VARCHAR(10),
	@Rate DECIMAL(18,2),
	@RateDate DATE
AS
BEGIN
	-- If such a course has not yet been set for this day, add
	IF NOT EXISTS (
		SELECT 1 FROM CurrencyRate
		WHERE currency_from = @CurrencyFrom AND currency_to = @CurrencyTo AND rate_date = @RateDate
	)
	BEGIN
		INSERT INTO CurrencyRate (currency_from, currency_to, rate, rate_date)
		VALUES (@CurrencyFrom, @CurrencyTo, @Rate, @RateDate);
	END
	ELSE
	BEGIN
		-- Otherwise, update the existing record
		UPDATE CurrencyRate
		SET rate = @Rate
		WHERE currency_from = @CurrencyFrom AND currency_to = @CurrencyTo AND rate_date = @RateDate;
	END
END;
GO

PRINT '--- The procedure for adding the specified number of rows to the Client table ---';
GO
CREATE PROCEDURE dbo.InsertClients
	@RowCount INT
AS
BEGIN
	SET NOCOUNT ON;

	DECLARE @Counter INT = 1;

	WHILE @Counter <= @RowCount
	BEGIN
		INSERT INTO Client (name, address, phone, email)
		VALUES (
			CONCAT('Test Client ', @Counter),
			'Test Address',
			990000000000 + @Counter,
			CONCAT('TestClient', @Counter, '@example.com')
		);

		SET @Counter = @Counter + 1;
	END
	
	PRINT CONCAT('Inserted client #', @Counter);
END;
GO


PRINT '--- EXEC PROCEDURES ---';

PRINT '--- 3 system stored procedures ---';
-- 1. List of all tables in the database
PRINT '--- List of all tables in the database ---';
GO
EXEC sp_tables @table_type = "'TABLE'";
GO

-- 2. Information about indexes in the Transactions table
PRINT '--- Information about indexes in the Transactions table ---';
GO
EXEC sp_helpindex @objname = 'Transactions';
GO

-- 3. Statistics on memory usage by the Client table
PRINT '--- Information on memory usage by the Client table ---';
GO
EXEC sp_spaceused @objname = 'Client';
GO

PRINT '--- 3 global temporary stored procedures ---';
PRINT '--- 1. Global procedure for withdrawing all clients ---';
GO
EXEC ##GetAllClients;
GO

PRINT '--- 2. Global procedure for calculating the total balance in the Account table ---';
GO
EXEC ##GetTotalBalance;
GO

PRINT '--- 3. Global procedure to retrieve the last 5 transactions ---';
GO
EXEC ##GetLatestTransactions;
GO

PRINT '--- 3 local temporary stored procedures ---';
PRINT '--- 1. Temporary procedure for viewing customer accounts ---';
GO
EXEC #GetClientAccounts @ClientId = 1;
GO

PRINT '--- 2. Temporary procedure for counting client transactions ---';
GO
EXEC #CountClientTransactions @ClientId = 1;
GO

PRINT '--- 3. Temporary procedure for viewing the history of currency exchange rate changes ---';
GO
EXEC #GetCurrencyHistory @CurrencyFrom = 'USD', @CurrencyTo = 'UAH';
GO

PRINT '--- 3 user-defined stored procedures parts of the Transaction---';
PRINT '--- 1. Procedure for making a transfer between customer accounts ---';
GO
-- Transfer 100 USD from account 1 to account 2
EXEC dbo.PerformTransaction @FromAccountId = 1, @ToAccountId = 2, @Amount = 100.00, @CurrencyRateId = 5, @ClientId = 1;
GO

PRINT '--- 2. The procedure for calculating interest by the bank ---';
GO
-- 10% interest on all accounts
EXEC dbo.ApplyInterestToAccounts @InterestRate = 10;
GO

PRINT '--- 3. The procedure for adding the exchange rate for a new day ---';
GO
-- Setting the USD-UAH exchange rate for a new day
DECLARE @Today DATE = CAST(GETDATE() AS DATE);
EXEC dbo.SetCurrencyRateForNewDay @CurrencyFrom = 'USD', @CurrencyTo = 'UAH', @Rate = 39.25, @RateDate = @Today;
EXEC dbo.SetCurrencyRateForNewDay @CurrencyFrom = 'UAH', @CurrencyTo = 'USD', @Rate = 0.025, @RateDate = @Today;
GO

PRINT '--- The procedure for adding the specified number of rows to the Client table ---';
GO
-- Add 3 new Clients
EXEC dbo.InsertClients @RowCount = 3;
GO



SET QUOTED_IDENTIFIER OFF;
GO

SET STATISTICS TIME, IO OFF;
GO