-- CIEĽ:  Pripraviť surové dáta do konzistentnej a spoľahlivej podoby pre následnú RFM analýzu a segmentáciu zákazníkov.

-- POSTUP PRI ČISTENÍ DÁT: Pozrela som na každý stĺpec zvlášť a riešila nasledujúce okruhy problémov: 
-- 1. Odstránenie duplicít 
-- 2. Štandardizácia dát a logická kontrola dát (napr. rozdiel v zle napísaných slovách, kontrola jednotného zápisu údaju, kontrola správnych dátových typov, ak stĺpce medzi sebou súvisia, kontrola správnosti ich prepojenia)
-- 3. Kontrola Null hodnôt v celej tabuľke
-- 4. Odstránenie stĺpcov alebo riadkov, ktoré sú nepotrebné

-- dataset je zo stránky Kaggle, link: https://www.kaggle.com/datasets/sahilprajapati143/retail-analysis-large-dataset
-- súbor som vložila v csv formáte, bez predošlého čistenia a úpravy dát

CREATE DATABASE Retail_customer;
USE Retail_customer;

SELECT * FROM new_retail_data;

-- vytvorenie druhej tabuľky, aby mi ostala pôvodná ako kontrolná/záložná
SELECT *
INTO retail_data
FROM new_retail_data;

SELECT * FROM retail_data;

-- 1. KONTROLA DUPLIKÁTOV 
SELECT *, ROW_NUMBER () 
OVER (PARTITION BY Transaction_ID,Customer_ID,  Name, Email, Phone, Address, City, State, Zipcode, Country, Age, 
Gender, Income, Customer_Segment, Date, Year, Month, Time, Amount, Total_Amount, Product_Category, Product_Brand, 
Product_Type, Feedback, Shipping_Method, Payment_Method, Order_Status, Ratings, products
ORDER BY Transaction_ID ASC) AS row_num
FROM retail_data;

WITH duplicate_cte AS
(SELECT *, ROW_NUMBER () 
OVER (PARTITION BY Transaction_ID,Customer_ID,  Name, Email, Phone, Address, City, State, Zipcode, Country, Age, 
Gender, Income, Customer_Segment, Date, Year, Month, Time, Amount, Total_Amount, Product_Category, Product_Brand, 
Product_Type, Feedback, Shipping_Method, Payment_Method, Order_Status, Ratings, products
ORDER BY Transaction_ID ASC) AS row_num
FROM retail_data
)
SELECT *
FROM duplicate_cte
WHERE row_num > 1;

-- zistené 4 duplicitné riadky, kontrola
SELECT * FROM retail_data
WHERE Transaction_ID = '3200766' OR Transaction_ID = '4476510' OR Transaction_ID = '4942326' OR Transaction_ID = '5340129'
ORDER BY Transaction_ID;

-- vymazanie 4 duplikátov
WITH duplicate_cte AS
(SELECT *, ROW_NUMBER () 
OVER (PARTITION BY Transaction_ID,Customer_ID,  Name, Email, Phone, Address, City, State, Zipcode, Country, Age, 
Gender, Income, Customer_Segment, Date, Year, Month, Time, Amount, Total_Amount, Product_Category, Product_Brand, 
Product_Type, Feedback, Shipping_Method, Payment_Method, Order_Status, Ratings, products
ORDER BY Transaction_ID ASC) AS row_num
FROM retail_data
)
DELETE
FROM duplicate_cte
WHERE row_num > 1;

-- 2. KONTROLA NULL hodnôt - kedže máme všetky dáta ako VARCHAR a dáta neobsahovali Null hodnoty, prevediem všetky potrebné hodnoty, v každom stĺpci na NULL
UPDATE retail_data
SET 
Transaction_ID = NULLIF(NULLIF(Transaction_ID, ''), '0'),
Customer_ID = NULLIF(NULLIF(Customer_ID, ''), '0'),
Name = NULLIF(NULLIF(Name, ''), '0'),
Email = NULLIF(NULLIF(Email, ''), '0'),
Phone = NULLIF(NULLIF(Phone, ''), '0'),
Address = NULLIF(NULLIF(Address, ''), '0'),
City = NULLIF(NULLIF(City, ''), '0'),
State = NULLIF(NULLIF(State, ''), '0'),
Zipcode = NULLIF(NULLIF(Zipcode, ''), '0'),
Country = NULLIF(NULLIF(Country, ''), '0'),
Age = NULLIF(NULLIF(Age, ''), '0'),
Gender = NULLIF(NULLIF(Gender, ''), '0'),
Income = NULLIF(NULLIF(Income, ''), '0'),
Customer_Segment = NULLIF(NULLIF(Customer_Segment, ''), '0'),
Date = NULLIF(NULLIF(Date, ''), '0'),
Year = NULLIF(NULLIF(Year, ''), '0'),
Month = NULLIF(NULLIF(Month, ''), '0'),
Time = NULLIF(NULLIF(Time, ''), '0'),
Amount = NULLIF(NULLIF(Amount, ''), '0'),
Total_Amount = NULLIF(NULLIF(Total_Amount, ''), '0'),
Product_Category = NULLIF(NULLIF(Product_Category, ''), '0'),
Product_Brand = NULLIF(NULLIF(Product_Brand, ''), '0'),
Product_Type = NULLIF(NULLIF(Product_Type, ''), '0'),
Feedback = NULLIF(NULLIF(Feedback, ''), '0'),
Shipping_Method = NULLIF(NULLIF(Shipping_Method, ''), '0'),
Payment_Method = NULLIF(NULLIF(Payment_Method, ''), '0'),
Order_Status = NULLIF(NULLIF(Order_Status, ''), '0'),
Ratings = NULLIF(NULLIF(Ratings, ''), '0'),
products = NULLIF(NULLIF(products, ''), '0')
WHERE 
Transaction_ID IS NULL OR Transaction_ID = '' OR Transaction_ID = '0'
OR Customer_ID IS NULL OR Customer_ID = '' OR Customer_ID = '0'
OR Name IS NULL OR Name = '' OR Name = '0'
OR Email IS NULL OR Email = '' OR Email = '0'
OR Phone IS NULL OR Phone = '' OR Phone = '0'
OR Address IS NULL OR Address = '' OR Address = '0'
OR City IS NULL OR City = '' OR City = '0'
OR State IS NULL OR State = '' OR State = '0'
OR Zipcode IS NULL OR Zipcode = '' OR Zipcode = '0'
OR Country IS NULL OR Country = '' OR Country = '0'
OR Age IS NULL OR Age = '' OR Age = '0'
OR Gender IS NULL OR Gender = '' OR Gender = '0'
OR Income IS NULL OR Income = '' OR Income = '0'
OR Customer_Segment IS NULL OR Customer_Segment = '' OR Customer_Segment = '0'
OR Date IS NULL OR Date = '' OR Date = '0'
OR Year IS NULL OR Year = '' OR Year = '0'
OR Total_Amount IS NULL OR Total_Amount = '' OR Total_Amount = '0'
OR Product_Category IS NULL OR Product_Category = '' OR Product_Category = '0'
OR Product_Brand IS NULL OR Product_Brand = '' OR Product_Brand = '0'
OR Product_Type IS NULL OR Product_Type = '' OR Product_Type = '0'
OR Feedback IS NULL OR Feedback = '' OR Feedback = '0'
OR Shipping_Method IS NULL OR Shipping_Method = '' OR Shipping_Method = '0'
OR Payment_Method IS NULL OR Payment_Method = '' OR Payment_Method = '0'
OR Order_Status IS NULL OR Order_Status = '' OR Order_Status = '0'
OR Ratings IS NULL OR Ratings = '' OR Ratings = '0'
OR products IS NULL OR products = '' OR products = '0';

-- 3. ŠTANDARDIZÁCIA A VALIDÁCIA DÁT

-- kontrola priestoru pred a za slovom
SELECT * FROM retail_data;

UPDATE retail_data
SET Name = (TRIM(Name)), 
Email = (TRIM(Email)),
Phone = (TRIM(Phone)),
Address = (TRIM(Address)),
City = (TRIM(City)),
State = (TRIM(State)),
Zipcode = (TRIM(Zipcode)),
Country = (TRIM(Country)),
Age = (TRIM(Age)),
Gender = (TRIM(Gender)),
Income = (TRIM(Income)),
Customer_Segment = (TRIM(Customer_Segment)),
Month = (TRIM(Month)),
Product_Category = (TRIM(Product_Category)),
Product_Brand = (TRIM(Product_Brand)),
Product_Type = (TRIM(Product_Type)),
Feedback = (TRIM(Feedback)),
Shipping_Method = (TRIM(Shipping_Method)),
Order_Status = (TRIM(Order_Status)),
products = (TRIM(products));

-- kontrola, či sú dáta rovnako zapísané, či ich netreba zjednotiť 
-- produkty sú v datasete zapísané štýlom značka + typ (bez konkrétneho upresnenia napr. kód) alebo len značka (bez typu) 
-- dáta som nechala zapísané takto (nech je pri značke vo väčšine prípadov aspoň typ produktu), no pre konkrétnejšie výsledky by bolo dobré doplniť typy zakúpených produktov z inej tabuľky (pri práci s reálnymi dátami)
-- príklad: Produkt iPhone je v celom datasete zapísaný len ako iPhone (bez zápisu s typom, ktorý by sme vedeli doplniť všade)
SELECT * FROM retail_data;

SELECT DISTINCT Product_Type
FROM retail_data
ORDER BY 1;

SELECT products
FROM retail_data
Where products like '%iPhone%';

SELECT products
FROM retail_data
Where products like '%LG%';

-- ZMENA DÁTOVÝCH TYPOV

-- Transaction_ID na z Varchar na INT + použitie funkcie LEFT (pôvodne boli čísla zapísané ako napr: 8969598.0)

SELECT * FROM retail_data;

SELECT Transaction_ID
FROM retail_data
WHERE TRY_CONVERT(int, Transaction_ID) IS NULL
AND Transaction_ID IS NOT NULL;

SELECT Transaction_ID, LEFT(Transaction_ID, 7) AS Transaction_ID_num
FROM retail_data;

UPDATE retail_data
SET Transaction_ID  = LEFT(Transaction_ID, 7);

ALTER TABLE retail_data
ALTER COLUMN Transaction_ID INT NULL;

-- zmena Customer_ID 
SELECT Customer_ID
FROM retail_data
WHERE TRY_CONVERT(int, Customer_ID) IS NULL
AND Customer_ID IS NOT NULL;

SELECT Customer_ID, LEFT(Customer_ID, 5) AS Customer_ID_num
FROM retail_data;

UPDATE retail_data
SET Customer_ID  = LEFT(Customer_ID, 5);

ALTER TABLE retail_data
ALTER COLUMN Transaction_ID INT NULL;

-- Phone (na INT) 
SELECT Phone
FROM retail_data
WHERE TRY_CONVERT(int, Phone) IS NULL
AND Phone IS NOT NULL;

SELECT Phone, LEFT(Phone, 10) AS Phone_num
FROM retail_data;

UPDATE retail_data
SET Phone  = LEFT(Phone, 10);

ALTER TABLE retail_data
ALTER COLUMN Phone BIGINT NULL;

-- Zipcode (na INT)
SELECT Zipcode
FROM retail_data
WHERE TRY_CONVERT(int, Zipcode) IS NULL
AND Zipcode IS NOT NULL;

-- zmena 5-miestnych zipcode na 3 miestne
WITH zipcode_cte AS
(
SELECT Zipcode, LEN(Zipcode) as lenght_zipcode
FROM retail_data
WHERE Zipcode IS NOT NULL 
GROUP BY Zipcode
)
UPDATE retail_data
SET Zipcode = LEFT(retail_data.Zipcode, 3)
FROM retail_data
INNER JOIN zipcode_cte 
ON retail_data.Zipcode = zipcode_cte.Zipcode
WHERE zipcode_cte.lenght_zipcode = 5;

-- zmena 6-miestnych zipcode na 4 miestne
WITH zipcode_cte AS
(
SELECT Zipcode, LEN(Zipcode) as lenght_zipcode
FROM retail_data
WHERE Zipcode IS NOT NULL 
GROUP BY Zipcode
)
UPDATE retail_data
SET Zipcode = LEFT(retail_data.Zipcode, 4)
FROM retail_data
INNER JOIN zipcode_cte 
ON retail_data.Zipcode = zipcode_cte.Zipcode
WHERE zipcode_cte.lenght_zipcode = 6;

-- Zmena 7 miestnych na 5 miestne
WITH zipcode_cte AS
(
SELECT Zipcode, LEN(Zipcode) as lenght_zipcode
FROM retail_data
WHERE Zipcode IS NOT NULL 
GROUP BY Zipcode
)
UPDATE retail_data
SET Zipcode = LEFT(retail_data.Zipcode, 5)
FROM retail_data
INNER JOIN zipcode_cte 
ON retail_data.Zipcode = zipcode_cte.Zipcode
WHERE zipcode_cte.lenght_zipcode = 7;

ALTER TABLE retail_data
ALTER COLUMN Zipcode INT NULL;

-- Age (na INT)
select age from retail_data;

WITH count_cte AS
(
SELECT age, LEN(age) as lenght_age
FROM retail_data
WHERE age IS NOT NULL 
GROUP BY age
)
SELECT COUNT (lenght_age)
FROM count_cte;

WITH count_cte AS
(
SELECT age, LEN(age) AS lenght_age
FROM retail_data
WHERE age IS NOT NULL 
GROUP BY age
)
UPDATE retail_data
SET age = LEFT(retail_data.age, 2)
FROM retail_data
INNER JOIN count_cte ON retail_data.age = count_cte.age
WHERE count_cte.lenght_age = 4;

-- kontrola, či sa v age už nenachádzajú iné textové hodnoty, keď nie, tak update dátového typu
SELECT age
FROM retail_data
WHERE TRY_CONVERT(int, age) IS NULL
AND age IS NOT NULL;

ALTER TABLE retail_data
ALTER COLUMN age INT NULL;

-- Date (na DATE), najprv vytvorenie nového stĺpca a vloženia dát, potom vymazanie starého stl. a premenovanie nového
SELECT [date],
TRY_PARSE([date] AS date USING 'en-US') AS converted_date
FROM retail_data;

ALTER TABLE retail_data
ADD date_tmp DATE;

UPDATE retail_data
SET date_tmp = TRY_PARSE([date] AS date USING 'en-US');

ALTER TABLE retail_data
DROP COLUMN [date];

EXEC sp_rename 'retail_data.date_tmp', 'date', 'COLUMN';

--Year (na INT)
WITH year_cte AS
(
SELECT [Year], LEN([Year]) as lenght_year
FROM retail_data
WHERE [Year] IS NOT NULL 
GROUP BY [Year]
)
UPDATE retail_data
SET [Year] = LEFT(retail_data.[Year], 4)
FROM retail_data
INNER JOIN year_cte 
ON retail_data.year = year_cte.year
WHERE year_cte.lenght_year = 6;

SELECT [Year]
FROM retail_data
WHERE TRY_CONVERT(int, [Year]) IS NULL
AND [Year] IS NOT NULL;

ALTER TABLE retail_data
ALTER COLUMN [Year] INT NULL;

-- Time (na Time)
SELECT * FROM retail_data;

ALTER TABLE retail_data
ALTER COLUMN [Time] TIME;

-- Total_Purchases (na INT)
WITH Total_Purchases_cte AS
(
SELECT Total_Purchases, LEN(Total_Purchases) as lenght_Total_Purchases
FROM retail_data
WHERE Total_Purchases IS NOT NULL 
GROUP BY Total_Purchases
)
UPDATE retail_data
SET Total_Purchases = LEFT(retail_data.Total_Purchases, 1)
FROM retail_data
INNER JOIN Total_Purchases_cte
ON retail_data.Total_Purchases = retail_data.Total_Purchases
WHERE Total_Purchases_cte.lenght_Total_Purchases = 3;

ALTER TABLE retail_data
ALTER COLUMN Total_Purchases INT NULL;

SELECT Total_Purchases 
FROM retail_data 
WHERE Total_Purchases = 0;

SELECT Total_Purchases 
FROM retail_data
WHERE TRY_CONVERT(int, Total_Purchases ) IS NULL
AND Total_Purchases  IS NOT NULL;

-- Amount (na DECIMAL)
SELECT Amount
FROM retail_data
WHERE TRY_CONVERT(DECIMAL, Amount ) IS NULL
AND Amount  IS NOT NULL;

ALTER TABLE retail_data
ALTER COLUMN Amount DECIMAL(20,3);

SELECT Amount FROM retail_data;

-- Total_Amount (na DECIMAL)
SELECT Total_Amount
FROM retail_data
WHERE TRY_CONVERT(DECIMAL, Total_Amount ) IS NULL
AND Total_Amount IS NOT NULL;

ALTER TABLE retail_data
ALTER COLUMN Total_Amount DECIMAL(20,3);

SELECT Total_Amount FROM retail_data;

-- Ratings (na INT)
UPDATE retail_data
SET Ratings = LEFT(Ratings, 1)
WHERE LEN(Ratings) = 3
AND Ratings IS NOT NULL;

ALTER TABLE retail_data
ALTER COLUMN Ratings INT NULL;

--- kontrola, či dáta dávajú zmysel v kontexte:

--- Transaction_ID musú mať unikátne hodnoty - ostatné som vymazala
WITH Duplicates AS (
SELECT *,ROW_NUMBER() OVER (PARTITION BY Transaction_ID ORDER BY (SELECT NULL)) AS rn
FROM retail_data
)
DELETE Duplicates
WHERE rn > 1;

DELETE FROM retail_data 
WHERE Transaction_ID IS NULL;

-- kontrola Transaction_ID
SELECT Transaction_ID, COUNT(*) AS Pocet
FROM retail_data
GROUP BY Transaction_ID
HAVING COUNT(*) > 1;

-- Customer_ID nemusí byť unikátne, ale pre rovnakého zákazníka by mal byť konzistentný (rovnaké meno, mail, telefón)
SELECT Customer_ID, COUNT(DISTINCT Email) AS emails, COUNT(DISTINCT Name) AS names, COUNT(DISTINCT Phone) AS phones
FROM retail_data
GROUP BY Customer_ID
HAVING COUNT(DISTINCT Email) > 1 OR COUNT(DISTINCT Name) > 1 OR COUNT(DISTINCT Phone) > 1;

--- Age — či nie ze záporný alebo príliš vysoký
SELECT MIN(Age) AS min_age, MAX(Age) AS max_age
FROM retail_data;

-- Total_Purchases — nesmie byť záporný
SELECT MIN(Total_Purchases) AS min_Total_Purchases
FROM retail_data;

-- Ratings — musí byť v platnom rozsahu (1–5)
SELECT MIN(Ratings) AS min_Ratings, MAX(Ratings) AS max_Ratings
FROM retail_data;

-- Amount a Total_Amount — musia byť ≥ 0 
SELECT Amount, Total_Amount
FROM retail_data
WHERE Amount < 0
OR Total_Amount < 0;

-- Total_Amount má byť väčší alebo rovný Amount (v príkaze nesmie výjsť žiaden riadok)
SELECT Amount, Total_Amount
FROM retail_data
WHERE Amount > Total_Amount;

-- Total_Amount by mal byť Amount × Total_Purchases = zistila som, že veľa riadkov z pôvodného stĺpca obsahovali chyby, napr. posunutá desatiná čiarka (miesto Total_Amount 890,56 bolo vo výsledku 89,06)
-- preto som manuálne vytvorila nový stĺpec Total_Amount_new, ktorý som po vymazaní starého premenovala na Total_Amount

-- kontrola starého stĺpca
SELECT Amount, Total_Purchases, (Amount * Total_Purchases) AS control_total_amount, Total_Amount
FROM retail_data
WHERE (Amount * Total_Purchases) <> Total_Amount;

ALTER TABLE retail_data 
ADD Total_Amount_new DECIMAL (20,3);

UPDATE retail_data 
SET Total_Amount_new = Amount * Total_Purchases;

ALTER TABLE retail_data 
DROP COLUMN Total_Amount;

EXEC sp_RENAME 'retail_data.Total_Amount_new' , 'Total_Amount', 'COLUMN';

SELECT * FROM retail_data;

-- Kontrola správneho zápisu časových hodnôt (žiaden extrém z minulosti alebo budúcnosti) 
-- + Vytvorenie kombinácie časového údaju do nového stĺpca s názvom DateTime pre jednoduchšiu analýzu

-- všetky dátumy sú za obdobie od 1.3.2023 do 29.2.2024
SELECT MIN([date]) AS start_date, MAX([date]) AS last_date
FROM retail_data;

ALTER TABLE retail_data 
ADD [DateTime] datetime;

UPDATE retail_data
SET [DateTime] = CAST(CAST([Date] AS datetime) + CAST([Time] AS datetime) AS datetime);

SELECT [Date], [Time], [DateTime]
FROM retail_data;

-- kontrola rovnakého zápisu emailov
SELECT Email
FROM retail_data
WHERE Email not like '%@%.%';

-- kontrola potreby odstránenia nepoužiteľných alebo nadbytočných stĺpcov (ponechala som všetky)












