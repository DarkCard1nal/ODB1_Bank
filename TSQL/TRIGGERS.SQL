SET QUOTED_IDENTIFIER ON;
GO

PRINT '--- CREATE TRIGGER trg_Check_Phone_Length ---';
GO
CREATE TRIGGER trg_Check_Phone_Length
ON Client
AFTER INSERT, UPDATE
AS
BEGIN
	-- Перевірка довжини: дозволено тільки 10 або 12 цифр
	IF EXISTS (
		SELECT 1
		FROM inserted
		WHERE LEN(CAST(phone AS VARCHAR)) NOT IN (10, 12)
	)
	BEGIN
		RAISERROR ('Phone number must have exactly 10 or 12 digits.', 16, 1);
		ROLLBACK TRANSACTION;
		RETURN;
	END
END;
GO

PRINT '--- CREATE TRIGGER trg_LimitAccounts_AfterInsert ---';
GO
CREATE TRIGGER trg_LimitAccounts_AfterInsert
ON Account
AFTER INSERT
AS
BEGIN
	IF EXISTS (
		SELECT i.client_id
		FROM inserted i
		GROUP BY i.client_id
		HAVING (
			SELECT COUNT(*)
			FROM Account a
			WHERE a.client_id = i.client_id
		) > 5
	)
	BEGIN
		RAISERROR('A client cannot have more than 5 accounts.', 16, 1);
		ROLLBACK TRANSACTION;
	END
END;
GO

PRINT '--- CREATE TRIGGER trg_Email_CaseInsensitive_Insert ---';
GO
CREATE TRIGGER trg_Email_CaseInsensitive_Insert
ON Client
INSTEAD OF INSERT
AS
BEGIN
	-- Check if the email already exists in any case-insensitive form
	IF EXISTS (
		SELECT 1
		FROM inserted i
		WHERE EXISTS (
			SELECT 1
			FROM Client c
			WHERE LOWER(c.email) = LOWER(i.email)
		)
	)
	BEGIN
		RAISERROR('Email already exists (case-insensitive check).', 16, 1);
		RETURN;
	END

	-- Insert only if email is unique (case-insensitive)
	INSERT INTO Client (name, address, phone, email)
	SELECT name, address, phone, email
	FROM inserted;
END;
GO

PRINT '--- CREATE TRIGGER trg_Email_CaseInsensitive_Update ---';
GO
CREATE TRIGGER trg_Email_CaseInsensitive_Update
ON Client
INSTEAD OF UPDATE
AS
BEGIN
	IF EXISTS (
		SELECT 1
		FROM inserted i
		WHERE EXISTS (
			SELECT 1
			FROM Client c
			WHERE LOWER(c.email) = LOWER(i.email)
			  AND c.client_id <> i.client_id
		)
	)
	BEGIN
		RAISERROR('Email already exists (case-insensitive check) during update.', 16, 1);
		RETURN;
	END

	-- Perform the update if email is unique
	UPDATE c
	SET c.name = i.name,
		c.address = i.address,
		c.phone = i.phone,
		c.email = i.email
	FROM Client c
	JOIN inserted i ON c.client_id = i.client_id;
END;
GO

PRINT '--- CREATE TRIGGER trg_Log_DDL_Changes ---';
GO
CREATE TRIGGER trg_Log_DDL_Changes
ON DATABASE
FOR CREATE_TABLE, ALTER_TABLE, DROP_TABLE
AS
BEGIN
	DECLARE @EventData XML = EVENTDATA();

	INSERT INTO DDL_Log (
		event_type,
		schema_name,
		object_name,
		user_name
	)
	VALUES (
		@EventData.value('(/EVENT_INSTANCE/EventType)[1]', 'NVARCHAR(100)'),
		@EventData.value('(/EVENT_INSTANCE/SchemaName)[1]', 'NVARCHAR(100)'),
		@EventData.value('(/EVENT_INSTANCE/ObjectName)[1]', 'NVARCHAR(100)'),
		@EventData.value('(/EVENT_INSTANCE/LoginName)[1]', 'NVARCHAR(100)')
	);
END;
GO

PRINT '--- Test TRIGGER trg_Log_DDL_Changes ---';
CREATE TABLE TestLog (id INT);
ALTER TABLE TestLog ADD name NVARCHAR(50);
DROP TABLE TestLog;
SELECT * FROM DDL_Log ORDER BY event_time DESC;
GO

PRINT '--- CREATE TRIGGER trg_Logon_Audit ---';
GO
CREATE TRIGGER trg_Logon_Audit
ON ALL SERVER
FOR LOGON
AS
BEGIN
	DECLARE @login_name SYSNAME = ORIGINAL_LOGIN();
	DECLARE @host_name NVARCHAR(255) = HOST_NAME();
	DECLARE @app_name NVARCHAR(255) = APP_NAME();

	DECLARE @client_ip NVARCHAR(255);
	SELECT @client_ip = client_net_address
	FROM sys.dm_exec_connections
	WHERE session_id = @@SPID;

	INSERT INTO master.dbo.LogonAudit (login_name, host_name, app_name, client_ip)
	VALUES (@login_name, @host_name, @app_name, @client_ip);
END;
GO

PRINT '--- Test TRIGGER trg_Logon_Audit ---';
SELECT * FROM master.dbo.LogonAudit ORDER BY login_time DESC;
GO

SET QUOTED_IDENTIFIER OFF;
GO
