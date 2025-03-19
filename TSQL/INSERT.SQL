-- Додавання записів у таблицю Client
INSERT INTO Client (name, address, phone, email)
VALUES 
('John Doe', '123 Main St', 1234567890, 'john.doe@example.com'),
('Jane Smith', '456 Elm St', 9876543210, 'jane.smith@example.com');

-- Додавання записів у таблицю Account
INSERT INTO Account (client_id, currency, balance)
VALUES
(1, 'USD', 1500.00),
(1, 'UAH', 2000.00),
(2, 'UAH', 1000.00);

-- Додавання записів у таблицю CurrencyRate
INSERT INTO CurrencyRate (currency_from, currency_to, rate)
VALUES
('USD', 'UAH', 36.50),
('UAH', 'USD', 0.02);

-- Додавання записів у таблицю Transactions
INSERT INTO Transactions (client_id, account_from_id, account_to_id, currency_rate_id, transaction_type, amount, currency)
SELECT 
	1 AS client_id, -- ID клієнта
	1 AS account_from_id, -- Рахунок, з якого виконується транзакція
	2 AS account_to_id, -- Рахунок, на який виконується транзакція
	(SELECT TOP 1 currency_rate_id 
	FROM CurrencyRate cr
	WHERE cr.currency_from = a_from.currency AND cr.currency_to = a_to.currency
	ORDER BY cr.rate_date DESC) AS currency_rate_id, -- Найсвіжіший курс
	'Exchange' AS transaction_type, -- Тип транзакції
	500.00 AS amount, -- Сума
	a_from.currency AS currency -- Валюта з рахунку відправника
FROM 
	Account a_from
JOIN 
	Account a_to ON a_to.account_id = 2 -- Зв’язуємо з рахунком отримувача
WHERE 
	a_from.account_id = 1; -- Вказуємо рахунок відправника

INSERT INTO Transactions (client_id, account_from_id, account_to_id, currency_rate_id, transaction_type, amount, currency)
SELECT 
	1 AS client_id, -- ID клієнта
	2 AS account_from_id, -- Рахунок відправника
	3 AS account_to_id, -- Рахунок отримувача
	NULL AS currency_rate_id, -- Поле залишаємо NULL, якщо курс не потрібен
	'Transfer' AS transaction_type, -- Тип транзакції
	1000.00 AS amount, -- Сума транзакції
	a_from.currency AS currency -- Валюта з рахунку відправника
FROM 
	Account a_from
WHERE 
	a_from.account_id = 2; -- ID рахунку відправника

INSERT INTO Transactions (client_id, account_from_id, account_to_id, currency_rate_id, transaction_type, amount, currency)
SELECT 
	1 AS client_id, -- ID клієнта
	1 AS account_from_id, -- Рахунок, з якого виконується транзакція
	NULL AS account_to_id, -- Поле залишаємо NULL, якщо зняття коштів
	NULL AS currency_rate_id, -- Поле залишаємо NULL, якщо курс не потрібен
	'Withdrawal' AS transaction_type, -- Тип транзакції
	500.00 AS amount, -- Сума
	a_from.currency AS currency -- Валюта з рахунку відправника
FROM 
	Account a_from
WHERE 
	a_from.account_id = 1; -- Вказуємо рахунок відправника

-- Важливо оновити баланси після кожної створеної транзакції (приклад в UPDATE.SQL)!

-- Додавання 100 записів у таблицю Client
INSERT INTO Client (name, address, phone, email)
VALUES 
('Jessamyn Czadla', '4 Blue Bill Park Way', 4626466355, 'jczadla0@usda.gov'),
('Gery Shaddick', '60 Badeau Street', 9589590409, 'gshaddick1@newsvine.com'),
('Courtney Skitral', '196 Vera Drive', 6467678422, 'cskitral2@amazonaws.com'),
('Jeff Storton', '8 Ruskin Terrace', 9311690617, 'jstorton3@sitemeter.com'),
('Rooney Korneluk', '984 Stephen Trail', 9570650506, 'rkorneluk4@cyberchimps.com'),
('Hercules Enoksson', '84934 South Hill', 6527201551, 'henoksson5@nih.gov'),
('Saleem Ber', '9885 Service Alley', 8536912260, 'sber6@japanpost.jp'),
('Gerrie Fulstow', '04 Lien Trail', 7179685570, 'gfulstow7@ft.com'),
('Evonne Moody', '7367 Ryan Way', 9096672619, 'emoody8@scientificamerican.com'),
('Felisha McVie', '7 Farragut Point', 2316118232, 'fmcvie9@ft.com'),
('Madlen Labbey', '28541 Caliangt Way', 2491221467, 'mlabbeya@blinklist.com'),
('Kynthia Bellanger', '820 Maywood Crossing', 1403216363, 'kbellangerb@seattletimes.com'),
('Gage Dugue', '69985 Debs Park', 7249850053, 'gduguec@mtv.com'),
('Elisha Killimister', '7 Corben Pass', 7711003955, 'ekillimisterd@google.com.hk'),
('Joete Othen', '98 Canary Alley', 2295627301, 'jothene@webnode.com'),
('Theda Dolling', '3 3rd Pass', 5641842976, 'tdollingf@netscape.com'),
('Hyacinthie Bowcock', '8 Eggendart Court', 6568246639, 'hbowcockg@slate.com'),
('Issy Dymoke', '813 Mcbride Drive', 9263815720, 'idymokeh@ted.com'),
('Giacinta Tebbit', '12 Cardinal Parkway', 3570481395, 'gtebbiti@ocn.ne.jp'),
('Orelle Victoria', '01 Steensland Lane', 6093581099, 'ovictoriaj@wikia.com'),
('Trever Degoy', '559 Meadow Vale Point', 4598902186, 'tdegoyk@posterous.com'),
('Townie Clue', '04822 Union Road', 4662959021, 'tcluel@wordpress.com'),
('Horten Saffon', '688 1st Park', 3819557750, 'hsaffonm@storify.com'),
('Raina Rotchell', '9 Fremont Point', 6977706162, 'rrotchelln@edublogs.org'),
('Maridel Pamment', '15 School Avenue', 4676914860, 'mpammento@amazonaws.com'),
('Minne Tunuy', '0 Spohn Junction', 9191878663, 'mtunuyp@sbwire.com'),
('Lindsay Jorry', '71260 Golf View Point', 7910994196, 'ljorryq@usda.gov'),
('Marleah Spiniello', '61713 Harper Plaza', 5662474757, 'mspiniellor@studiopress.com'),
('Barny Tibbits', '4846 Butternut Center', 1859293801, 'btibbitss@naver.com'),
('Robinett Collcott', '6 Macpherson Lane', 8089373480, 'rcollcottt@sphinn.com'),
('L,urette Fernao', '7 Evergreen Way', 7973060290, 'lfernaou@imgur.com'),
('Felicdad Hanham', '62725 Schmedeman Court', 7903349686, 'fhanhamv@technorati.com'),
('Noah Tomaello', '5799 Leroy Trail', 9131217910, 'ntomaellow@ning.com'),
('Read Hardingham', '2 Village Road', 9752177771, 'rhardinghamx@over-blog.com'),
('Quinn Lewer', '34 Kedzie Court', 9393025978, 'qlewery@usnews.com'),
('Marianne Dinnies', '12198 Homewood Drive', 5750654018, 'mdinniesz@nymag.com'),
('Marisa Crummay', '8 Coolidge Hill', 7063154491, 'mcrummay10@mlb.com'),
('Frank Mytton', '281 Bellgrove Terrace', 7803311139, 'fmytton11@dropbox.com'),
('Artair Pirri', '1 Homewood Lane', 8907304772, 'apirri12@narod.ru'),
('Barby Wolfe', '5 Linden Parkway', 8799286231, 'bwolfe13@blogger.com'),
('Wilow Tanguy', '40978 Raven Place', 2141382326, 'wtanguy14@bloomberg.com'),
('Alvera Gapper', '56 Shelley Crossing', 9892679662, 'agapper15@nasa.gov'),
('Zelda Tilne', '5498 Fairfield Road', 3329894141, 'ztilne16@fotki.com'),
('Sophronia Sollam', '82 Straubel Place', 8852695058, 'ssollam17@telegraph.co.uk'),
('Federica Ellington', '9642 Warrior Point', 7755659002, 'fellington18@e-recht24.de'),
('Egon Jellett', '275 Carberry Avenue', 7433407726, 'ejellett19@wordpress.com'),
('Nydia Qualtrough', '940 Eagan Alley', 2224305309, 'nqualtrough1a@dedecms.com'),
('Aleen Smyth', '62605 Pawling Way', 8173961713, 'asmyth1b@live.com'),
('Filberte Riddles', '61869 Debs Way', 5049790685, 'friddles1c@booking.com'),
('Brooks Ivantyev', '6795 Golf View Trail', 2183858174, 'bivantyev1d@livejournal.com'),
('Maritsa Culley', '89677 Upham Center', 6059149543, 'mculley1e@artisteer.com'),
('Oriana Vidyapin', '68552 Hoard Hill', 9545452337, 'ovidyapin1f@arstechnica.com'),
('Constanta Eddow', '17 Fisk Plaza', 3795383038, 'ceddow1g@mit.edu'),
('Joachim Lay', '321 Di Loreto Point', 3398083177, 'jlay1h@rambler.ru'),
('Evangelia Bampford', '116 Florence Way', 6345270586, 'ebampford1i@digg.com'),
('Nanny Milland', '7 Haas Parkway', 9590165112, 'nmilland1j@ow.ly'),
('Doralynne Stockhill', '809 Hoffman Lane', 5281762797, 'dstockhill1k@storify.com'),
('Murial Scholcroft', '4 Macpherson Way', 7421032479, 'mscholcroft1l@sina.com.cn'),
('Saloma Dilkes', '10 Cordelia Plaza', 2285957160, 'sdilkes1m@twitpic.com'),
('Hilliard Wilder', '31900 Melrose Lane', 9932088528, 'hwilder1n@bing.com'),
('Maisey Lumsdaine', '61056 Gina Pass', 9732625236, 'mlumsdaine1o@answers.com'),
('Garrott Dorning', '7 Stoughton Crossing', 2736631515, 'gdorning1p@yellowbook.com'),
('Anson Silverthorne', '39 8th Hill', 5817199864, 'asilverthorne1q@state.tx.us'),
('Hammad Passingham', '5691 Heffernan Way', 9972445508, 'hpassingham1r@a8.net'),
('Jody Jonuzi', '4 Dakota Place', 2852178946, 'jjonuzi1s@t.co'),
('Chalmers Readwing', '81 Cordelia Way', 7171400631, 'creadwing1t@discovery.com'),
('Richie Watman', '74228 Amoth Avenue', 6074482571, 'rwatman1u@stanford.edu'),
('Stefano Meers', '22 Derek Street', 8972481081, 'smeers1v@a8.net'),
('Corrine Riach', '7 Hintze Plaza', 9084036717, 'criach1w@xing.com'),
('Blanca Rieger', '33614 Holy Cross Plaza', 9507420580, 'brieger1x@blogger.com'),
('Bronny Dahill', '6897 Kennedy Plaza', 5907148638, 'bdahill1y@smh.com.au'),
('Beverly Forsyde', '037 Johnson Trail', 8848322176, 'bforsyde1z@delicious.com'),
('Melisa Whatham', '6197 Rowland Plaza', 7107228462, 'mwhatham20@wikimedia.org'),
('Carny Halwill', '78157 Schiller Center', 6622664400, 'chalwill21@illinois.edu'),
('Alejoa Zemler', '52710 Meadow Ridge Way', 5229259884, 'azemler22@cnbc.com'),
('Kelly Colisbe', '559 Maryland Point', 2523701092, 'kcolisbe23@4shared.com'),
('Evan Broadley', '3 Bonner Terrace', 3226121578, 'ebroadley24@europa.eu'),
('Johnathon Gibbetts', '7756 Esker Point', 4300513740, 'jgibbetts25@microsoft.com'),
('Chrisy Menzies', '50 Vera Hill', 9741357824, 'cmenzies26@paypal.com'),
('Paulie Yepiskov', '631 7th Hill', 7814571186, 'pyepiskov27@sfgate.com'),
('Anya Inglesfield', '6 Manley Street', 1857627033, 'ainglesfield28@hibu.com'),
('Goraud Kenafaque', '5542 Fairfield Pass', 8594692912, 'gkenafaque29@usa.gov'),
('Danya Hodges', '9 Esker Center', 5779733358, 'dhodges2a@dropbox.com'),
('Genia Hanson', '042 Chive Center', 7675464261, 'ghanson2b@loc.gov'),
('Sada Maclaine', '5 Sauthoff Circle', 2363553747, 'smaclaine2c@example.com'),
('Alleen Hoyes', '640 Basil Place', 1249183281, 'ahoyes2d@smh.com.au'),
('Aveline Piscopo', '3 Calypso Place', 2918578109, 'apiscopo2e@printfriendly.com'),
('Hubey Leyson', '262 7th Street', 5630606816, 'hleyson2f@exblog.jp'),
('Lexy Oloman', '6 Schurz Terrace', 2959545678, 'loloman2g@webnode.com'),
('Corina Addington', '8 Swallow Place', 5215744881, 'caddington2h@nbcnews.com'),
('Lynn Bohlin', '071 Arkansas Drive', 2397455856, 'lbohlin2i@cisco.com'),
('Rozalie Netley', '911 Welch Hill', 1790431874, 'rnetley2j@cpanel.net'),
('Gustie Haward', '98 Schiller Road', 2849299429, 'ghaward2k@nifty.com'),
('Kellina Jannasch', '0 Dryden Drive', 2102728952, 'kjannasch2l@statcounter.com'),
('Webb Menham', '090 Artisan Avenue', 8274722869, 'wmenham2m@cdbaby.com'),
('Willette Bamlett', '9 Gina Road', 3402553302, 'wbamlett2n@goo.ne.jp'),
('Humberto Efford', '45 Dunning Junction', 9781754935, 'hefford2o@tumblr.com'),
('Ervin Sired', '8285 Maywood Center', 2481177451, 'esired2p@istockphoto.com'),
('Kalie Bransdon', '29 Killdeer Street', 7000985964, 'kbransdon2q@tumblr.com'),
('Homere Jaulmes', '7152 Service Court', 4234432363, 'hjaulmes2r@elpais.com');

-- Додавання 100 записів у таблицю Account
INSERT INTO Account (client_id, currency, balance)
VALUES
(94, 'CNY', 43528.08),
(2, 'PLN', 70057.46),
(84, 'IDR', 10408.49),
(63, 'IDR', 24359.08),
(66, 'CNY', 23872.49),
(4, 'CNY', 13118.93),
(77, 'EUR', 14823.45),
(55, 'EUR', 70343.48),
(13, 'EUR', 19114.45),
(86, 'EUR', 22076.26),
(53, 'CAD', 17908.69),
(23, 'AZN', 10755.44),
(41, 'EUR', 89443.56),
(21, 'LRD', 66322.85),
(26, 'EUR', 9719.29),
(72, 'EUR', 21994.64),
(79, 'ARS', 56034.76),
(55, 'MMK', 40876.29),
(99, 'RUB', 56264.31),
(98, 'CHF', 39016.6),
(59, 'CZK', 69522.43),
(61, 'AMD', 9344.32),
(42, 'PHP', 22571.99),
(57, 'CNY', 51859.63),
(54, 'EUR', 96739.67),
(87, 'UGX', 57067.81),
(69, 'CNY', 10025.42),
(39, 'CNY', 37519.63),
(50, 'IDR', 56988.24),
(15, 'MXN', 93272.48),
(53, 'MMK', 55808.06),
(99, 'CNY', 1085.78),
(45, 'SOS', 77687.98),
(32, 'IDR', 82477.83),
(47, 'PEN', 33329.97),
(14, 'PHP', 28236.46),
(20, 'EUR', 78327.2),
(94, 'EGP', 53528.58),
(46, 'PEN', 23500.23),
(74, 'EUR', 48683.09),
(97, 'KZT', 77335.13),
(19, 'SEK', 21555.56),
(53, 'EUR', 25025.32),
(44, 'ARS', 37388.66),
(20, 'CNY', 6817.12),
(72, 'RUB', 99521.08),
(97, 'IDR', 97404.01),
(42, 'CNY', 87509.82),
(1, 'USD', 5192.23),
(10, 'IDR', 36318.75),
(48, 'EUR', 59653.59),
(8, 'MYR', 83910.9),
(63, 'MGA', 91530.13),
(89, 'COP', 33373.92),
(97, 'RUB', 99288.67),
(49, 'EUR', 28946.41),
(40, 'CNY', 51922.84),
(40, 'USD', 57318.02),
(35, 'USD', 79483.32),
(5, 'SEK', 36507.43),
(30, 'CNY', 47165.48),
(65, 'RUB', 15434.15),
(99, 'IDR', 21760.96),
(96, 'CNY', 29680.39),
(34, 'HUF', 97785.04),
(23, 'IDR', 88266.1),
(22, 'EUR', 84202.83),
(95, 'PLN', 69049.02),
(83, 'EUR', 2218.18),
(55, 'RUB', 50674.15),
(38, 'BRL', 85851.28),
(54, 'USD', 13080.64),
(88, 'RUB', 60437.07),
(15, 'BAM', 85863.36),
(71, 'PHP', 16082.35),
(11, 'IDR', 36926.41),
(97, 'NPR', 87067.73),
(13, 'VND', 60297.53),
(41, 'IDR', 47524.59),
(15, 'PHP', 34683.01),
(8, 'SEK', 42318.99),
(65, 'CNY', 34599.56),
(33, 'CNY', 48970.97),
(81, 'MNT', 78497.44),
(76, 'BYR', 1074.55),
(32, 'PHP', 64153.61),
(45, 'ZAR', 34155.86),
(74, 'PKR', 99873.17),
(63, 'IDR', 40970.65),
(6, 'CNY', 74149.43),
(60, 'PHP', 75180.94),
(45, 'PEN', 66832.29),
(98, 'CZK', 41941.97),
(100, 'IDR', 51998.98),
(89, 'PHP', 10486.79),
(48, 'HRK', 55834.1),
(61, 'SYP', 80526.64),
(60, 'CHF', 6043.88),
(95, 'UAH', 6972.68),
(29, 'IDR', 5470.24);

-- Додавання 100 записів у таблицю CurrencyRate
INSERT INTO CurrencyRate (currency_from, currency_to, rate)
VALUES
('EUR', 'ANY', 75661.42),
('IDR', 'SUR', 27377.46),
('IDR', 'DNY', 90806.96),
('CNY', 'FBP', 90144.41),
('EUR', 'GPY', 32487.38),
('CNY', 'HUR', 25607.72),
('EUR', 'JNY', 42751.64),
('SLL', 'KUR', 92304.02),
('EUR', 'LNY', 13.99),
('NZD', 'QUR', 20629.85),
('IDR', 'WTR', 53149.84),
('CNY', 'END', 80723.81),
('CAD', 'RNY', 4309.72),
('VND', 'TMD', 59471.55),
('KMF', 'YAH', 1082.03),
('CNY', 'UCD', 4754.16),
('JPY', 'INT', 70093.89),
('IDR', 'OAD', 4997.36),
('CNY', 'PUB', 47749.69),
('BGN', 'ZDR', 38135.74),
('IDR', 'XHP', 83343.17),
('IRR', 'CMD', 7956.05),
('BRL', 'VRL', 18348.84),
('EUR', 'BNY', 63589.8),
('AFN', 'NKR', 3.22),
('EUR', 'MRS', 93439.53),
('CNY', 'GQF', 70433.19),
('USD', 'PWR', 62817.32),
('CNY', 'PEN', 5733.75),
('ILS', 'CRP', 6909.26),
('JPY', 'PTP', 67447.49),
('CNY', 'UYD', 57464.19),
('CNY', 'MUD', 4938.73),
('CNY', 'EIR', 59.58),
('NIO', 'TOB', 76382.22),
('EUR', 'MPN', 86397.88),
('CNY', 'CAY', 151.01),
('IDR', 'CSY', 96135.36),
('HNL', 'JDY', 81497.4),
('BRL', 'UFH', 7923.43),
('EUR', 'CGK', 95623.02),
('IDR', 'CHK', 41709.04),
('CNY', 'EJR', 29808.76),
('USD', 'AKS', 64348.45),
('SEK', 'CLY', 73389.78),
('VND', 'PZP', 70347.54),
('BAM', 'ZXR', 39310.24),
('CNY', 'JCY', 7631.4),
('PHP', 'PVB', 47553.36),
('ZAR', 'SBK', 4339.85),
('CNY', 'RNB', 19212.4),
('PHP', 'PMN', 0.52),
('VND', 'CNQ', 12803.82),
('USD', 'BRW', 58513.06),
('HRK', 'USE', 48710.36),
('PKR', 'CVR', 93373.01),
('EUR', 'RUT', 57694.37),
('MNT', 'EUY', 37883.47),
('EUR', 'EUU', 56002.26),
('IRR', 'CNI', 34558.65),
('BRL', 'PKO', 44057.33),
('CZK', 'PHP', 85390.21),
('MUR', 'SEA', 66655.41),
('IDR', 'IDS', 8934.13),
('BDT', 'IND', 11341.61),
('PLN', 'ZMF', 3855.13),
('CNY', 'BRG', 28838.75),
('UAH', 'AZH', 749.07),
('SEK', 'DOJ', 91294.59),
('UYU', 'CNK', 87299.69),
('NOK', 'EUL', 2268.95),
('NGN', 'RSZ', 57784.46),
('USD', 'IDX', 54574.05),
('BRL', 'COC', 12402.21),
('THB', 'THV', 46780.59),
('PAB', 'PLB', 44012.3),
('SYP', 'PLN', 85613.88),
('SEK', 'TZM', 0.49),
('QNY', 'CAD', 68349.91),
('WHP', 'IDR', 46228.57),
('EZS', 'PHP', 65975.34),
('RND', 'PLN', 67590.18),
('TAH', 'BRL', 69918.59),
('YRW', 'IDR', 29047.54),
('USD', 'BRL', 18952.36),
('IDR', 'BAM', 17519.29),
('OAB', 'EUR', 8539.29),
('PMD', 'JPY', 82532.56),
('ANY', 'PLN', 27351.95),
('SUR', 'YER', 12346.79),
('DDT', 'COP', 73176.55),
('FUR', 'ARS', 56584.68),
('GDF', 'PHP', 4076.19),
('HZT', 'EUR', 72019.59),
('JLN', 'JPY', 27451.4),
('KRL', 'CNY', 9353.82),
('LNY', 'CNY', 83609.53),
('ZGX', 'BTN', 45135.98),
('XZK', 'IDR', 97200.09),
('PHP', 'PKR', 39365.14);

-- Додавання записів у таблицю Transactions типу 'Interest' для кожного раунку для нарахування відсотків в Interest
INSERT INTO Transactions (client_id, account_from_id, account_to_id, currency_rate_id, transaction_type, amount, currency)
SELECT 
	a_to.client_id,                      -- Беремо client_id з таблиці Account
	NULL AS account_from_id,             -- Відсотки нараховуються без списання з іншого рахунку
	a_to.account_id AS account_to_id,    -- Нараховуємо на кожен рахунок
	NULL AS currency_rate_id,            -- Поле залишаємо NULL, якщо курс не потрібен
	'Interest' AS transaction_type,      -- Тип транзакції
	a_to.balance * 0.1 AS amount,        -- 10% від балансу
	a_to.currency AS currency            -- Валюта рахунку
FROM 
	Account a_to;                        -- Виконуємо нарахування для всіх рахунків

-- Додавання записів у таблицю Interest
INSERT INTO Interest (account_id, transaction_id, interest_rate, amount)
SELECT 
	t.account_to_id AS account_id,       -- Рахунок отримувача (з account_to_id транзакції)
	t.transaction_id AS transaction_id,  -- ID транзакції
	0.10 AS interest_rate,               -- Ставка відсотків 10%
	t.amount AS amount                   -- Сума транзакції
FROM 
	Transactions t
WHERE 
	t.transaction_type = 'Interest';     -- Враховуємо лише транзакції типу "Interest"
