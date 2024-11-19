# ODB1_Bank

_Created for the course "Organization of databases" V. N. Karazin Kharkiv National University_

Design and implementation of the Bank's information system (IS) model.

---

В данній проботі розглядається проєктування та реалізація моделі інформаційної системи (ІС) Банку з використанням CASE-засобів.

# Завдання

Вариант №27
Банк
В базе данных должны храниться сведения о счетах клиентов банка, о размерах счета и о самих клиентах. Одним счетом могут пользоваться один и более клиентов. Счета могут открываться в разных валютах гривна, рубли, доллары и евро. Операции, которые могут выполнять клиенты со своим счетом: открытие, закрытие, пополнение счета, а также снятие денег со счета. Банк начисляет проценты на счет в определённые моменты Времени. В базе данных должна храниться история финансовых операций с каждым счетом. Также должны быть данные о курсах валют для перерасчета денег на счетах на каждый день работы банка. Курс валют неизменен в течение всего дня и должен быть известен на каждый день работы банка. Процент по всем счетам равен 10%. Начисление процента на заданный счет выполняется путем формирования в таблице истории счетов для заданного счета записи о его пополнении суммой, равной 10% от остатка наличности на этом счете.
Запросы:

- Проверить согласованность записей об операциях со счетами (истории счетов) с размерами остатка на счетах и выдать номера счетов, в которых имеются расхождения;
- Найти счет, с которым совершили больше всего операций;
- Найти счета, с которых ни разу не снимали деньги
- Для данного клиента выдать отчет обо всех операция с его счетами;
- Для данного счета пересчитать его содержимое из одной заданной валюты в другую заданную валюту.
  Транзакции:
- Выполнение операций со счетом клиента
- Начисление процентов на счет банком и задание курсов валют на новый день работы банка.

# IDEF0, IDEF3, DFD представлення

Створимо представлення ІС Банку за допомогою CASE-засобів:

Робота A-0 базовий блок:
![A-0](https://github.com/user-attachments/assets/7ed022d8-e2c4-4f5d-8d95-46c79c784bd1)

Робота A0 (IDEF0) декомпозиція блока А-0:
![A0](https://github.com/user-attachments/assets/5449ec27-67d1-4f78-b4dd-01a0326313ad)

Робота A1 (DFD), відповідатиме за управління рахунками
клієнтів:
![A1](https://github.com/user-attachments/assets/d18b3bb4-f05f-4783-b3dd-8aa79eb340bd)

Робота A2 (DFD), відповідатиме за управління операціями,
історією, аудит:
![A2](https://github.com/user-attachments/assets/9a6e4409-de86-44b7-99bf-f61a446d1e39)

Робота A3.1 (IDEF3), відповідатиме за управління курсами
валют, перерахунок відсотків в інших валютах.:
![A3 1](https://github.com/user-attachments/assets/f5b50105-92e9-472d-8dea-e15ff6234d4f)

Робота A4 (DFD), відповідатиме за нарахування відсотків:
![A4](https://github.com/user-attachments/assets/5fb4bd12-445f-4e96-b1b9-d2a2fcf32eed)

Загальна діаграма дерева вузлів:
![image](https://github.com/user-attachments/assets/edcdbac8-4049-472f-8347-3d2a238b9418)

# ER-модель (IDEF1X)

#### **Основні сутності та їх атрибути:**

1. **Client (Клієнт)**:

   - `client_id` (PK): Унікальний ідентифікатор клієнта
   - `name`: Ім'я клієнта
   - `address`: Адреса клієнта
   - `phone`: Номер телефону клієнта
   - `email`: Електронна пошта клієнта

2. **Account (Рахунок)**:

   - `account_id` (PK): Унікальний ідентифікатор рахунку
   - `currency`: Тип валюти (UAH, USD, EUR, RUB)
   - `balance`: Поточний баланс рахунку
   - `creation_date`: Дата відкриття рахунку
   - `client_id` (FK): Ідентифікатор клієнта (зв'язок з таблицею Client)

3. **Transaction (Операція)**:

   - `transaction_id` (PK): Унікальний ідентифікатор операції
   - `account_id` (FK): Ідентифікатор рахунку (зв'язок з таблицею Account)
   - `client_id` (FK): Ідентифікатор клієнта (зв'язок з таблицею Client)
   - `related_account_id` (FK): Ідентифікатор рахунку, з яким пов'язана операція (для конвертації валют)
   - `currency_rate_id` (FK): Унікальний ідентифікатор курсу
   - `transaction_type`: Тип операції (Deposit, Withdrawal, Interest, Exchange)
   - `amount`: Сума операції
   - `transaction_date`: Дата виконання операції
   - `currency`: Валюта операції

4. **Interest (Нарахування відсотків)**:

   - `interest_id` (PK): Унікальний ідентифікатор нарахування
   - `account_id` (FK): Ідентифікатор рахунку (зв'язок з таблицею Account)
   - `interest_rate`: Відсоткова ставка (фіксована 10%)
   - `calculation_date`: Дата нарахування
   - `amount`: Сума нарахованих відсотків

5. **CurrencyRate (Курс Валют)**:
   - `currency_rate_id` (PK): Унікальний ідентифікатор курсу
   - `currency_from`: Валюта, з якої конвертують
   - `currency_to`: Валюта, в яку конвертують
   - `rate`: Курс обміну (наприклад, 1 USD = 27.5 UAH)
   - `rate_date`: Дата встановлення курсу

#### **Зв'язки між сутностями:**

- Один **Client** може мати декілька **Account**.
- Один **Account** може мати декілька **Transaction**.
- Один **Account** може мати декілька нарахувань **Interest**.
- **CurrencyRate** зберігає курс обміну між валютами на конкретну дату.

За допомогою CASE-засобів створимо логічний рівень:
![image](https://github.com/user-attachments/assets/47e15009-0460-4934-acba-2ac497ebdfae)

За логічним рівнем згенеруємо фізичний рівень:
![image](https://github.com/user-attachments/assets/c4f19277-acab-48f8-b1bb-a353cd6217f6)

Отримана ER-модель відповідає формам 1NF, 2NF, 3NF, BCNF.
В цій моделі відсутні рекурсивні зв’язки, оскільки жодна сутність не повинна напряму взаємодіяти сама з собою (з такою ж сутністю).

# Приклад запиту мовою реляційної алгебри

Виконаємо мовою реляційної алгебри запит 4: 

Для конкретного клієнта знайти усі рахунки, для кожного з них знайти усі транзакції що були виконані з ним.

Запит:

1.	Отримати всі рахунки конкретного клієнта (з ідентифікатором `C1`):

`Account WHERE client_id = ′C1′`

2.	Отримати всі транзакції, виконані для рахунків цього клієнта:

`((Account WHERE client_id = ′C1′) JOIN Transaction )[transaction_id, account_id, transaction_type, amount, transaction_date]`


Докладніше:

1.	Вибрати всі рахунки клієнта з ідентифікатором `C1`:

`T1 := Account WHERE client_id = ′C1′`

2.	З'єднати таблицю рахунків із таблицею транзакцій за `account_id`:

`T2 := T1 JOIN Transaction `

3.	Проекція результату для виводу всіх атрибутів транзакцій:

`T3 := T2[transaction_id, account_id, transaction_type, amount, transaction_date] `

У результаті отримаємо всі транзакції, виконані для рахунків клієнта з `client_id = 'C1'`.
