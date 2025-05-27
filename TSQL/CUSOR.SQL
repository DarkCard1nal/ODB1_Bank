SET QUOTED_IDENTIFIER ON;

PRINT '--- 1. Transaction: audit, logging, and balance correction ---';
GO
BEGIN TRY
	BEGIN TRANSACTION;

	-- Savepoint before any update
	SAVE TRANSACTION BeforeFix;

	-- Temporary table to store mismatches
	CREATE TABLE #BalanceMismatches (
		account_id INT,
		actual_balance DECIMAL(18,2),
		calculated_balance DECIMAL(18,2)
	);

	-- CTE to get last audit date and last known calculated balance
	WITH LastAudit AS (
		SELECT account_id, 
				MAX(log_date) AS last_audit_date,
				MAX(calculated_balance) AS last_known_balance
		FROM AuditBalanceMismatch
		GROUP BY account_id
	)

	-- Now recalculate balance from last audit forward
	INSERT INTO #BalanceMismatches(account_id, actual_balance, calculated_balance)
	SELECT 
		a.account_id,
		a.balance,
		COALESCE(la.last_known_balance, 0) +
		COALESCE(d.total_deposited, 0) + COALESCE(i.total_interest, 0) - COALESCE(w.total_withdrawn, 0)
	FROM Account a
	LEFT JOIN LastAudit la ON a.account_id = la.account_id
	LEFT JOIN (
		SELECT account_to_id AS account_id, SUM(amount) AS total_deposited
		FROM Transactions t
		JOIN Account a ON t.account_to_id = a.account_id
		LEFT JOIN AuditBalanceMismatch abm ON abm.account_id = a.account_id
		WHERE transaction_type IN ('Deposit', 'Exchange', 'Transfer')
		AND t.transaction_date > ISNULL((SELECT MAX(log_date) FROM AuditBalanceMismatch WHERE account_id = t.account_to_id), '1900-01-01')
		GROUP BY account_to_id
	) d ON a.account_id = d.account_id
	LEFT JOIN (
		SELECT account_from_id AS account_id, SUM(amount) AS total_withdrawn
		FROM Transactions t
		JOIN Account a ON t.account_from_id = a.account_id
		LEFT JOIN AuditBalanceMismatch abm ON abm.account_id = a.account_id
		WHERE transaction_type IN ('Withdrawal', 'Exchange', 'Transfer')
		AND t.transaction_date > ISNULL((SELECT MAX(log_date) FROM AuditBalanceMismatch WHERE account_id = t.account_from_id), '1900-01-01')
		GROUP BY account_from_id
	) w ON a.account_id = w.account_id
	LEFT JOIN (
		SELECT account_to_id AS account_id, SUM(amount) AS total_interest
		FROM Transactions t
		JOIN Account a ON t.account_to_id = a.account_id
		LEFT JOIN AuditBalanceMismatch abm ON abm.account_id = a.account_id
		WHERE transaction_type = 'Interest'
		AND t.transaction_date > ISNULL((SELECT MAX(log_date) FROM AuditBalanceMismatch WHERE account_id = t.account_to_id), '1900-01-01')
		GROUP BY account_to_id
	) i ON a.account_id = i.account_id
	WHERE a.balance <> 
			(COALESCE(la.last_known_balance, 0) + 
			COALESCE(d.total_deposited, 0) + 
			COALESCE(i.total_interest, 0) - 
			COALESCE(w.total_withdrawn, 0));

	-- Check if any mismatches found
	IF EXISTS (SELECT 1 FROM #BalanceMismatches)
	BEGIN
		PRINT '--- Discrepancy found. Logging and correcting balances ---';

		-- Log mismatches
		INSERT INTO AuditBalanceMismatch (account_id, actual_balance, calculated_balance, discrepancy)
		SELECT 
			account_id,
			actual_balance,
			calculated_balance,
			calculated_balance - actual_balance
		FROM #BalanceMismatches;

		-- Correct balances in Account table
		UPDATE a
		SET a.balance = b.calculated_balance
		FROM Account a
		JOIN #BalanceMismatches b ON a.account_id = b.account_id;

		-- Optional error simulation (uncomment to test ROLLBACK)
		-- THROW 50001, 'Simulated error after update', 1;

		-- Check for errors manually (additional safety)
		IF @@ERROR <> 0
		BEGIN
			PRINT '--- Error occurred. Rolling back to savepoint ---';
			ROLLBACK TRANSACTION BeforeFix;
		END
	END
	ELSE
	BEGIN
		PRINT '--- No discrepancies found ---';
	END

	-- Final commit
	COMMIT TRANSACTION;
END TRY
BEGIN CATCH
	PRINT '--- Exception caught. Rolling back entire transaction ---';
	ROLLBACK TRANSACTION;

	-- Print error details
	PRINT ERROR_MESSAGE();
END CATCH;
GO

PRINT '--- AuditBalanceMismatch: ---';
SELECT * FROM AuditBalanceMismatch
GO

/*
PRINT '--- 1. Check the consistency of transaction records with the account balance ---';
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
*/

-- Transaction that logs start and end timestamps for procedure execution
BEGIN TRAN;

BEGIN TRY
	PRINT '--- Procedure execution 1 started ---';
	DECLARE @StartTime DATETIME2 = SYSDATETIME();
	PRINT CONCAT('Start Time: ', CONVERT(varchar, @StartTime, 121));

	-- Call the existing stored procedure
	EXEC dbo.ApplyInterestToAccounts @InterestRate = 10;

	DECLARE @EndTime DATETIME2 = SYSDATETIME();
	PRINT CONCAT('End Time: ', CONVERT(varchar, @EndTime, 121));

	-- Calculate duration in seconds
	DECLARE @DurationInSeconds FLOAT = DATEDIFF(SECOND, @StartTime, @EndTime) 
		+ DATEDIFF(MILLISECOND, @StartTime, @EndTime) % 1000 / 1000.0;

	PRINT CONCAT('Execution Duration: ', CAST(@DurationInSeconds AS VARCHAR(10)), ' seconds');
	PRINT '--- Procedure execution 1 completed ---';
	COMMIT;
END TRY
BEGIN CATCH
	ROLLBACK;
	PRINT 'Error during procedure execution 1: ' + ERROR_MESSAGE();
END CATCH;
GO

-- Index for quick access to Interest records by account_id
CREATE NONCLUSTERED INDEX IX_Interest_AccountId 
ON Interest(account_id);
GO

-- Index for quick access to transactions by client_id
CREATE NONCLUSTERED INDEX IX_Transactions_ClientId 
ON Transactions(client_id);
GO

-- Index for quick access to transactions by account_to_id
CREATE NONCLUSTERED INDEX IX_Transactions_AccountToId 
ON Transactions(account_to_id);
GO

-- Index for quick filtering/insertion by currency (may come in handy if you have aggregation or JOIN)
CREATE NONCLUSTERED INDEX IX_Account_Currency 
ON Account(currency);
GO

-- Transaction that logs start and end timestamps for procedure execution
BEGIN TRAN;

BEGIN TRY
	PRINT '--- Procedure execution 2 started ---';
	DECLARE @StartTime2 DATETIME2 = SYSDATETIME();
	PRINT CONCAT('Start Time: ', CONVERT(varchar, @StartTime2, 121));

	-- Call the existing stored procedure
	EXEC dbo.ApplyInterestToAccounts @InterestRate = 10;

	DECLARE @EndTime2 DATETIME2 = SYSDATETIME();
	PRINT CONCAT('End Time: ', CONVERT(varchar, @EndTime2, 121));

	-- Calculate duration in seconds
	DECLARE @DurationInSeconds2 FLOAT = DATEDIFF(SECOND, @StartTime2, @EndTime2) 
		+ DATEDIFF(MILLISECOND, @StartTime2, @EndTime2) % 1000 / 1000.0;

	PRINT CONCAT('Execution Duration: ', CAST(@DurationInSeconds2 AS VARCHAR(10)), ' seconds');
	PRINT '--- Procedure execution 2 completed ---';
	COMMIT;
END TRY
BEGIN CATCH
	ROLLBACK;
	PRINT 'Error during procedure execution 2: ' + ERROR_MESSAGE();
END CATCH;
GO

-- Create a table with a single row to move the cursor through
DECLARE @InterestRate DECIMAL(5,2);
DECLARE interest_cursor CURSOR FOR 
SELECT CAST(10.00 AS DECIMAL(5,2))

BEGIN TRAN;

BEGIN TRY
	PRINT '--- Procedure execution 3 started (via cursor) ---';

	DECLARE @StartTime3 DATETIME2 = SYSDATETIME();
	PRINT CONCAT('Start Time: ', CONVERT(varchar, @StartTime3, 121));

	OPEN interest_cursor;
	FETCH NEXT FROM interest_cursor INTO @InterestRate;

	WHILE @@FETCH_STATUS = 0
	BEGIN
		EXEC dbo.ApplyInterestToAccounts @InterestRate = @InterestRate;

		FETCH NEXT FROM interest_cursor INTO @InterestRate;
	END

	CLOSE interest_cursor;

	DECLARE @EndTime3 DATETIME2 = SYSDATETIME();
	PRINT CONCAT('End Time: ', CONVERT(varchar, @EndTime3, 121));

	DECLARE @DurationInSeconds3 FLOAT = DATEDIFF(SECOND, @StartTime3, @EndTime3)
		+ DATEDIFF(MILLISECOND, @StartTime3, @EndTime3) % 1000 / 1000.0;

	PRINT CONCAT('Execution Duration: ', CAST(@DurationInSeconds3 AS VARCHAR(10)), ' seconds');
	PRINT '--- Procedure execution 3 completed ---';

	COMMIT;
END TRY
BEGIN CATCH
	ROLLBACK;
	PRINT 'Error during procedure execution 3: ' + ERROR_MESSAGE();
END CATCH;

BEGIN TRAN;

BEGIN TRY
	PRINT '--- Procedure execution 4 started (via cursor) ---';

	DECLARE @StartTime4 DATETIME2 = SYSDATETIME();
	PRINT CONCAT('Start Time: ', CONVERT(varchar, @StartTime4, 121));

	OPEN interest_cursor;
	FETCH NEXT FROM interest_cursor INTO @InterestRate;

	WHILE @@FETCH_STATUS = 0
	BEGIN
		-- Викликаємо процедуру через курсор
		EXEC dbo.ApplyInterestToAccounts @InterestRate = @InterestRate;

		FETCH NEXT FROM interest_cursor INTO @InterestRate;
	END

	CLOSE interest_cursor;

	DECLARE @EndTime4 DATETIME2 = SYSDATETIME();
	PRINT CONCAT('End Time: ', CONVERT(varchar, @EndTime4, 121));

	DECLARE @DurationInSeconds4 FLOAT = DATEDIFF(SECOND, @StartTime4, @EndTime4)
		+ DATEDIFF(MILLISECOND, @StartTime4, @EndTime4) % 1000 / 1000.0;

	PRINT CONCAT('Execution Duration: ', CAST(@DurationInSeconds4 AS VARCHAR(10)), ' seconds');
	PRINT '--- Procedure execution 4 completed ---';

	COMMIT;
END TRY
BEGIN CATCH
	ROLLBACK;
	PRINT 'Error during procedure execution 4: ' + ERROR_MESSAGE();
END CATCH;

DEALLOCATE interest_cursor;
GO