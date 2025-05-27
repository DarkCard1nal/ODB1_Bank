/*
BEGIN TRANSACTION;

INSERT INTO Client (name, phone, email)
VALUES ('Test User', -1234567890, 'test122@example.com');  -- порушення CHECK (phone >= 0)

-- Тут одразу буде помилка і транзакція зупиниться.

COMMIT; -- ніколи не досягнеться, бо INSERT викличе помилку
GO
*/
SET IDENTITY_INSERT Client ON;
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
/*
BEGIN TRANSACTION;
-- Недопустима довжина (наприклад, 9 цифр)
INSERT INTO Client (client_id, name, phone)
VALUES (999999999, 'Bob', 123456789);  -- ще не перевірено

-- Не виправляємо

COMMIT;  -- тригер викликає ROLLBACK через неправильну довжину
GO

BEGIN TRANSACTION;
-- Тимчасове некоректне значення (наприклад, 5 цифр)
INSERT INTO Client (client_id, name, phone, email)
VALUES (999999999, 'Alice', 12345, 'test123@example.com');  -- ще не перевіряється

-- Виправлення довжини на 10 цифр
UPDATE Client
SET phone = 1234567890
WHERE client_id = 999999999;

COMMIT; -- ОК: тригер перевірить — і пропустить
GO

SELECT * FROM Client WHERE client_id = 999999999
GO

DELETE FROM Client WHERE client_id = 999999999;
*/
SET IDENTITY_INSERT Client OFF;
GO