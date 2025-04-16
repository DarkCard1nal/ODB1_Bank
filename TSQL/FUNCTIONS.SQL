-- Create a scalar function that returns full client info as a single string
CREATE FUNCTION dbo.GetClientInfo(@ClientId INT)
RETURNS NVARCHAR(300)
AS
BEGIN
	DECLARE @Result NVARCHAR(300)

	SELECT @Result = 
		'Name: ' + name + ', Email: ' + email + ', Phone: ' + CAST(phone AS NVARCHAR)
	FROM Client
	WHERE client_id = @ClientId

	RETURN @Result
END
GO

-- Create function to classify client based on number of transactions
CREATE FUNCTION dbo.GetClientCategory(@ClientId INT)
RETURNS NVARCHAR(20)
AS
BEGIN
	DECLARE @TransactionCount INT
	DECLARE @Category NVARCHAR(20)

	SELECT @TransactionCount = COUNT(*) 
	FROM Transactions 
	WHERE client_id = @ClientId

	IF @TransactionCount >= 10
		SET @Category = 'Active'
	ELSE IF @TransactionCount >= 5
		SET @Category = 'Moderate'
	ELSE
		SET @Category = 'Passive'

	RETURN @Category
END
GO

-- Function that calculates bonus amount as 5% of total interest
CREATE FUNCTION dbo.GetBonusInterest(@ClientId INT)
RETURNS DECIMAL(18,2)
AS
BEGIN
	DECLARE @TotalInterest DECIMAL(18,2)

	SELECT @TotalInterest = SUM(i.amount)
	FROM Interest i
	JOIN Account a ON i.account_id = a.account_id
	WHERE a.client_id = @ClientId

	RETURN ISNULL(@TotalInterest * 0.05, 0)
END
GO

-- Inline function that returns all accounts of a client
CREATE FUNCTION dbo.fn_GetClientAccounts
(
	@ClientId INT
)
RETURNS TABLE
AS
RETURN
(
	SELECT account_id, currency, balance, creation_date
	FROM Account
	WHERE client_id = @ClientId
);
GO

-- Inline function that returns recent transactions for a client
CREATE FUNCTION dbo.fn_GetRecentTransactions
(
	@ClientId INT
)
RETURNS TABLE
AS
RETURN
(
	SELECT transaction_id, account_from_id, account_to_id, amount, currency, transaction_date
	FROM Transactions
	WHERE client_id = @ClientId
	  AND transaction_date >= DATEADD(DAY, -30, SYSDATETIME())
);
GO

-- Inline function to get accounts with total interest > 100
CREATE FUNCTION dbo.fn_AccountsWithHighInterest()
RETURNS TABLE
AS
RETURN
(
	SELECT a.account_id, a.client_id, SUM(i.amount) AS total_interest
	FROM Account a
	JOIN Interest i ON a.account_id = i.account_id
	GROUP BY a.account_id, a.client_id
	HAVING SUM(i.amount) > 100
);
GO

-- Create Multistatement TVF
CREATE FUNCTION dbo.fn_ClientTransactionsWithFlag
(
	@ClientId INT
)
RETURNS @Result TABLE
(
	transaction_id INT,
	amount DECIMAL(18,2),
	currency VARCHAR(10),
	transaction_date DATETIME2,
	is_large_transaction BIT
)
AS
BEGIN
	INSERT INTO @Result
	SELECT 
		transaction_id,
		amount,
		currency,
		transaction_date,
		CASE 
			WHEN amount > 1000 THEN 1 
			ELSE 0 
		END AS is_large_transaction
	FROM Transactions
	WHERE client_id = @ClientId;

	RETURN;
END;
GO

-- Get all client accounts along with the total amount of interest
CREATE FUNCTION dbo.fn_ClientAccountsWithInterest
(
	@ClientId INT
)
RETURNS @Result TABLE
(
	account_id INT,
	currency VARCHAR(10),
	balance DECIMAL(18,2),
	total_interest DECIMAL(18,2)
)
AS
BEGIN
	INSERT INTO @Result
	SELECT 
		a.account_id,
		a.currency,
		a.balance,
		ISNULL((
			SELECT SUM(i.amount)
			FROM Interest i
			WHERE i.account_id = a.account_id
		), 0) AS total_interest
	FROM Account a
	WHERE a.client_id = @ClientId;

	RETURN;
END;
GO

-- Get the history of exchange transactions for the specified currency
CREATE FUNCTION dbo.fn_CurrencyExchangeHistory
(
	@CurrencyFrom VARCHAR(10),
	@CurrencyTo VARCHAR(10)
)
RETURNS @Result TABLE
(
	rate_date DATE,
	rate DECIMAL(18,2)
)
AS
BEGIN
	INSERT INTO @Result
	SELECT rate_date, rate
	FROM CurrencyRate
	WHERE currency_from = @CurrencyFrom AND currency_to = @CurrencyTo
	ORDER BY rate_date DESC;

	RETURN;
END;
GO

-- Return full client name based on client_id
CREATE FUNCTION dbo.fn_GetClientName(@ClientId INT)
RETURNS NVARCHAR(200)
AS
BEGIN
	DECLARE @FullName NVARCHAR(200);

	SELECT @FullName = name
	FROM Client
	WHERE client_id = @ClientId;

	RETURN @FullName;
END;
GO

-- Return a list of transactions for a customer with a filter by minimum amount
CREATE FUNCTION dbo.fn_TransactionsAboveAmount
(
	@ClientId INT,
	@MinAmount DECIMAL(18,2)
)
RETURNS TABLE
AS
RETURN (
	SELECT transaction_id, amount, currency, transaction_date
	FROM Transactions
	WHERE client_id = @ClientId AND amount >= @MinAmount
);
GO

-- Return client accounts with information about the number of transactions for each of them
CREATE FUNCTION dbo.fn_ClientAccountsWithTransactionCount(@ClientId INT)
RETURNS @Result TABLE
(
	account_id INT,
	currency VARCHAR(10),
	balance DECIMAL(18,2),
	transaction_count INT
)
AS
BEGIN
	INSERT INTO @Result
	SELECT 
		a.account_id,
		a.currency,
		a.balance,
		(
			SELECT COUNT(*) 
			FROM Transactions t 
			WHERE t.account_from_id = a.account_id OR t.account_to_id = a.account_id
		) AS transaction_count
	FROM Account a
	WHERE a.client_id = @ClientId;

	RETURN;
END;
GO
