
USE Retail_customer;

-- ZÁKLADNÁ EXPLORÁCIA DÁT zameraná na zákazníkov celkovo

-- za aké dlhé obdobie máme dáta - 1.3.2023 do 29.2. 2024 (rok)
SELECT MAX(date) AS maximum_date, MIN (date) AS minimum_date
FROM retail_data;

-- ko¾ko zákazníkov za toto obdobie firma mala = 294 423
SELECT COUNT(DISTINCT Customer_ID) as count_customers
FROM retail_data;

-- ako zastúpené sú jednotlivé zákaznícké segmenty - Regular (142 900 zák.) 48,57 %, New (88 822 zák.) 30,19 % a Premium (62 492 zák.) 21,24 %, 
SELECT
COUNT (DISTINCT Customer_ID) AS count_customers, Customer_Segment,
ROUND ((COUNT(Customer_Segment) * 100.0 / (SELECT COUNT(*) FROM retail_data WHERE Customer_Segment IS NOT NULL)), 2) AS Customer_Segment_percentage
FROM retail_data
WHERE Customer_Segment IS NOT NULL
GROUP BY Customer_Segment
ORDER BY count_customers DESC;

-- aké má firma ohlasy (feedback) od zákazníkov = Excellent (98 446) 33,46 %, Good (92 909) 31,58 %, Average (60 956) 20,72 % a Bad (41 932) 14,25 %
SELECT Feedback, 
COUNT(Feedback) AS count_feedback,
ROUND ((COUNT(Feedback) * 100.0 / (SELECT COUNT(*) FROM retail_data WHERE Feedback IS NOT NULL)), 2) AS Feedback_percentage
FROM retail_data
WHERE Feedback IS NOT NULL
GROUP BY Feedback
ORDER BY COUNT(Feedback) DESC;

-- aké sú najob¾úbenejšie doruèovacie metódy = Same-Day (101 587) 34,54 %, Express (99 784) 33,93 %, Standard (92 725) 31,53 %
SELECT Shipping_Method, 
COUNT(Shipping_Method) AS count_Shipping_Method, 
ROUND((COUNT(Shipping_Method) * 100.0 / (SELECT COUNT(*) FROM retail_data WHERE Shipping_Method IS NOT NULL)), 2) AS shipping_method_percentage
FROM retail_data
WHERE Shipping_Method IS NOT NULL
GROUP BY Shipping_Method
ORDER BY COUNT(Shipping_Method) DESC;

-- ZÁKLADNÉ DEMOGRAFICKÉ ÚDAJE o zákazníkoch

-- 1.PRÍJEM - ludia so stredným príjmom (127 077), nízkym (93 671), vysokým (73 392)
SELECT Income, COUNT(DISTINCT Customer_ID) AS customer_count
FROM retail_data
WHERE Income IS NOT NULL
GROUP BY Income
ORDER BY Income DESC;

-- 2. VEK - pre jednoduchšiu interpretáciu boli zákazníci zaradení do vekových skupín
-- zákazníci sú najèastejšie mladí ludia 173 930 (18-35r.), potom ludia v strednom veku 82 529 (36-55r.) a starí ludia 37 794 (nad 56r.)
SELECT 
COUNT(DISTINCT CASE WHEN Age BETWEEN 18 AND 35 THEN Customer_ID END) AS Customers_18_35,
COUNT(DISTINCT CASE WHEN Age BETWEEN 36 AND 55 THEN Customer_ID END) AS Customers_36_55,
COUNT(DISTINCT CASE WHEN Age >= 56 THEN Customer_ID END) AS Customers_56_max
FROM retail_data
WHERE Age IS NOT NULL;

-- 3. POHLAVIE - väèšinou muži - 182 873 z., ženy = 111 243 z.
SELECT Gender, COUNT(DISTINCT Customer_ID) AS customer_count
FROM retail_data
WHERE Gender IS NOT NULL
GROUP BY Gender
ORDER BY Gender DESC;

-- 4. KRAJINA - USA (93 081 zák.), UK (61 552 zák.), Nemecko (51 427 zák.), Kanada (44 026 zák.), Austrália (44 072)
SELECT Country, COUNT(DISTINCT Customer_ID) AS customer_count
FROM retail_data
WHERE Country IS NOT NULL
GROUP BY Country
ORDER BY Country DESC;

-- ANALÝZA NA ZÁKLADE BIZNIS OTÁZKY A HYPOTÉZ
-- potreba vypoèítania RFM skóre na zistenie TOP zákazníkov firmy a ich charakteristiky

-- vypocet Recency - Ko¾ko dní uplynulo od posledného nákupu zákazníka po najnovší dátum v datasete
SELECT Customer_ID, DATEDIFF (DAY, MAX(date), 
(SELECT MAX(date) FROM retail_data)) AS recency_days
FROM retail_data
WHERE Customer_ID IS NOT NULL
GROUP BY Customer_ID;

-- výpoèet Frequency - ko¾kokrát zákazník nakúpil
SELECT Customer_ID, COUNT(DISTINCT Transaction_ID) AS frequency
FROM retail_data
WHERE Customer_ID IS NOT NULL
GROUP BY Customer_ID;

-- Výpocet Monetary - kolko zákazník celkovo minul
SELECT Customer_ID,SUM(Total_Amount) AS monetary
FROM retail_data
WHERE Customer_ID IS NOT NULL
GROUP BY Customer_ID;

-- prepojenie R+F+M
SELECT Customer_ID,
DATEDIFF(DAY, MAX(date), (SELECT MAX(date) FROM retail_data)) AS recency,
COUNT(DISTINCT Transaction_ID) AS frequency,
SUM(Total_Amount) AS monetary
FROM retail_data 
WHERE Customer_ID IS NOT NULL
GROUP BY Customer_ID;

-- vytvorenie zákaznického skóre (1-5) 
WITH rfm_cte AS
(
SELECT Customer_ID,
DATEDIFF(DAY, MAX(date), (SELECT MAX(date) FROM retail_data)) AS recency_days,
COUNT(DISTINCT Transaction_ID) AS frequency,
SUM(Total_Amount) AS monetary
FROM retail_data 
WHERE Customer_ID IS NOT NULL
GROUP BY Customer_ID
)
SELECT recency_days,
NTILE (5) OVER (ORDER BY recency_days ASC) AS score_recency,
frequency,
NTILE (5) OVER (ORDER BY frequency DESC) AS score_frequency,
monetary,
NTILE (5) OVER (ORDER BY monetary DESC) AS score_monetary
FROM rfm_cte;

-- predpríprava temporary table s rfm údajmi
WITH rfm_cte AS
(
SELECT Customer_ID,
DATEDIFF(DAY, MAX(date), (SELECT MAX(date) FROM retail_data)) AS recency_days,
COUNT(DISTINCT Transaction_ID) AS frequency,
SUM(Total_Amount) AS monetary
FROM retail_data 
WHERE Customer_ID IS NOT NULL
GROUP BY Customer_ID
),
score_rfm AS
(
SELECT Customer_ID, recency_days,
NTILE (5) OVER (ORDER BY recency_days ASC) AS score_recency,
frequency,
NTILE (5) OVER (ORDER BY frequency DESC) AS score_frequency,
monetary,
NTILE (5) OVER (ORDER BY monetary DESC) AS score_monetary
FROM rfm_cte
) 
SELECT Customer_ID, score_recency, score_frequency, score_monetary
FROM score_rfm;

-- vytvorenie Temporary table s RFM tak, aby som s výsledky mohla jednoducho dalej analyzovat
CREATE TABLE #temp_rfm
(Customer_ID varchar (50),
score_recency INT NOT NULL,
score_frequency INT NOT NULL,
score_monetary INT NOT NULL);

WITH rfm_cte AS
(
SELECT Customer_ID,
DATEDIFF(DAY, MAX(date), (SELECT MAX(date) FROM retail_data)) AS recency_days,
COUNT(DISTINCT Transaction_ID) AS frequency,
SUM(Total_Amount) AS monetary
FROM retail_data 
WHERE Customer_ID IS NOT NULL
GROUP BY Customer_ID
),
score_rfm AS
(
SELECT Customer_ID, recency_days,
NTILE (5) OVER (ORDER BY recency_days ASC) AS score_recency,
frequency,
NTILE (5) OVER (ORDER BY frequency DESC) AS score_frequency,
monetary,
NTILE (5) OVER (ORDER BY monetary DESC) AS score_monetary
FROM rfm_cte
) 
INSERT INTO #temp_rfm (Customer_ID, score_recency, score_frequency, score_monetary)
SELECT Customer_ID, score_recency, score_frequency, score_monetary
FROM score_rfm;

-- kontrola tabulky a kontrola, ci sa v nej nachádzajú 0 (pre budúcu analýzu)
SELECT * FROM #temp_rfm;

SELECT * FROM #temp_rfm
WHERE score_frequency = 0 
OR score_monetary = 0 
OR score_recency = 0;

-- doplnenie tabu¾ky o identifikáciu skupín zákazníkov
ALTER TABLE #temp_rfm
ADD rfm_segment VARCHAR (20);

UPDATE #temp_rfm
SET rfm_segment = CASE
WHEN score_recency BETWEEN 1 AND 2 AND score_frequency BETWEEN 1 AND 2 AND score_monetary BETWEEN 1 AND 2 THEN 'Champions'
WHEN score_recency BETWEEN 1 AND 3 AND score_frequency BETWEEN 1 AND 2 THEN 'Loyal Customers'
WHEN score_recency BETWEEN 1 AND 2 AND score_frequency BETWEEN 3 AND 4 THEN 'Potential Loyalist'
WHEN score_recency BETWEEN 1 AND 2 AND score_frequency BETWEEN 4 AND 5 THEN 'Recent Customers'
WHEN score_monetary BETWEEN 1 AND 2 THEN 'Big Spenders'
WHEN score_recency BETWEEN 3 AND 4 AND score_frequency BETWEEN 1 AND 3 AND score_monetary BETWEEN 1 AND 3 THEN 'At Risk'
WHEN score_recency BETWEEN 3 AND 4 AND score_frequency BETWEEN 3 AND 4 AND score_monetary BETWEEN 3 AND 4 THEN 'Need Attention'
WHEN score_recency = 5 AND score_frequency BETWEEN 4 AND 5 AND score_monetary BETWEEN 4 AND 5 THEN 'Lost' 
ELSE 'Others'
END 
FROM #temp_rfm;

SELECT * FROM #temp_rfm;

-- Poèet zákazníkov v jednotlivých skupinách
SELECT COUNT(*) AS count_customers, rfm_segment
FROM #temp_rfm 
GROUP BY rfm_segment;

-- kontrola, ci sa èíslo zhoduje s poctom zákazníkov v databáze = každý zákazník má v tabu¾ke #temp_rfm unikátne Customer_ID, DISTINCT už nemusím používat
SELECT DISTINCT Customer_ID
FROM retail_data;

-- Biznisová otázka:„Ktorí zákazníci majú najvyššiu hodnotu pre firmu a ako sa líšia od ostatných?“
-- identifikácia najloalájnejších / najziskovejších zákazníkov = tzv. "Champions"
-- poèet Champions = 46 934 zák.
Select COUNT(*) as Champions_Count
FROM #temp_rfm
WHERE rfm_segment = 'Champions';

-- PRÍJEM Champions - Medium 20 191 (43,02 %), Low 14 997 (31,95%), High 11 694 (24,92%)
SELECT Income, COUNT(t.Customer_ID) AS Champions_Income_Count, 
ROUND ((COUNT(t.Customer_ID) * 100.0 / (SELECT COUNT(Customer_ID) FROM #temp_rfm WHERE rfm_segment = 'Champions')), 2) AS Champions_Income_percentage
FROM #temp_rfm AS t
INNER JOIN retail_data AS r
ON r.Customer_ID = t.Customer_ID 
WHERE rfm_segment = 'Champions'
AND Income IS NOT NULL
GROUP BY Income
ORDER BY Income DESC;

-- POHLAVIE Champions = 29 121 mužov (62,05 %), 17 759 žien (37,84)
SELECT Gender, COUNT(t.Customer_ID) AS Champions_Income_Count, 
ROUND ((COUNT(t.Customer_ID) * 100.0 / (SELECT COUNT(Customer_ID) FROM #temp_rfm WHERE rfm_segment = 'Champions')), 2) AS Champions_Income_percentage
FROM #temp_rfm AS t
INNER JOIN retail_data AS r
ON r.Customer_ID = t.Customer_ID 
WHERE rfm_segment = 'Champions'
AND Gender IS NOT NULL
GROUP BY Gender
ORDER BY Gender DESC;

-- VEK Champions = 27 610 z. v skupine 18-35 rokov, 13 208 v skupine 36-55, 6090 v skupine 56+
-- Priemerný vek v Champions je 35 rokov a modus (najèastejší vek Champion zákazníka) je 20 (20-roèných máme až 5441 z.)
SELECT 
COUNT(DISTINCT CASE WHEN Age BETWEEN 18 AND 35 THEN r.Customer_ID END) AS Customers_18_35,
COUNT(DISTINCT CASE WHEN Age BETWEEN 36 AND 55 THEN r.Customer_ID END) AS Customers_36_55,
COUNT(DISTINCT CASE WHEN Age >= 56 THEN r.Customer_ID END) AS Customers_56_max
FROM retail_data AS r
INNER JOIN #temp_rfm AS t
ON r.Customer_ID = t.Customer_ID 
WHERE Age IS NOT NULL
AND rfm_segment = 'Champions';

SELECT AVG(Age)
FROM retail_data AS r
INNER JOIN #temp_rfm AS t
ON r.Customer_ID = t.Customer_ID 
WHERE Age IS NOT NULL
AND r.Customer_ID IS NOT NULL
AND rfm_segment = 'Champions';

SELECT TOP 1 WITH TIES Age, COUNT(DISTINCT r.Customer_ID) AS age_count
FROM retail_data AS r
INNER JOIN #temp_rfm AS t
ON r.Customer_ID = t.Customer_ID 
WHERE rfm_segment = 'Champions'
AND Age IS NOT NULL
GROUP BY Age
ORDER BY age_count DESC;

-- DORUCOVACIA METÓDA Champions = Same-Day (16 185) 34,48 %, Express (15 894) 33,86 %, Standard (14 803) 31,54 %
SELECT Shipping_Method, COUNT(t.Customer_ID) AS Champions_Shipping_Count, 
ROUND ((COUNT(t.Customer_ID) * 100.0 / (SELECT COUNT(Customer_ID) FROM #temp_rfm WHERE rfm_segment = 'Champions')), 2) AS Champions_Shipping_percentage
FROM #temp_rfm AS t
INNER JOIN retail_data AS r
ON r.Customer_ID = t.Customer_ID 
WHERE rfm_segment = 'Champions'
AND Shipping_Method IS NOT NULL
GROUP BY Shipping_Method
ORDER BY Champions_Shipping_Count DESC;

-- TOTAL REVENUE (celkový výnos) Champions / v porovnaní s ostatnými = Champions tvoria až 30 % z celkových tržieb firmy za rok, ale predbiehajú ich Big Spenders, ktorí tvoria 45% celkových tržieb
-- Spolu teda tieto skupiny zákazníkov tvoria až 75% celkových tržieb firmy
SELECT 
r.rfm_segment,
COUNT(DISTINCT r.Customer_ID) AS customer_count,
SUM(t.Total_Amount) AS total_revenue,
SUM(t.Total_Amount) / COUNT(DISTINCT r.Customer_ID) AS avg_revenue_per_customer,
AVG(t.Total_Amount) AS avg_transaction_value
FROM rfm_view2 r
JOIN retail_data t 
ON r.Customer_ID = t.Customer_ID
GROUP BY r.rfm_segment
ORDER BY total_revenue DESC;

WITH segment_stats AS (
SELECT 
 r.rfm_segment,
COUNT(DISTINCT r.Customer_ID) AS customer_count,
SUM(t.Total_Amount) AS total_revenue,
SUM(t.Total_Amount) / COUNT(DISTINCT r.Customer_ID) AS avg_revenue_per_customer,
AVG(t.Total_Amount) AS avg_transaction_value
FROM rfm_view2 r
JOIN retail_data t 
ON r.Customer_ID = t.Customer_ID
GROUP BY r.rfm_segment
)
SELECT 
rfm_segment,
customer_count,
total_revenue,
avg_revenue_per_customer,
avg_transaction_value,
ROUND(total_revenue * 100.0 / SUM(total_revenue) OVER (), 2) AS revenue_percentage
FROM segment_stats
ORDER BY total_revenue DESC;

-- porovnanie oblubenej dorucovacej metódy s ostatnými: Same-Day 101 587 (41,05 %), Express 99 784 (40,32 %), Standard 92 725 (37,47 %) (bez vyrazného rozdielu v porovnaní s Champions)
SELECT Shipping_Method, COUNT(DISTINCT r.Customer_ID) AS Others_Shipping_Count,
ROUND ((COUNT(t.Customer_ID) * 100.0 / (SELECT COUNT(Customer_ID) FROM #temp_rfm WHERE rfm_segment <> 'Champions')), 2) AS Others_Shipping_percentage
FROM #temp_rfm AS t
INNER JOIN retail_data AS r
ON t.Customer_ID = r.Customer_ID
WHERE CONCAT(score_recency, score_frequency, score_monetary) <> 'Champions'
AND Shipping_Method IS NOT NULL
GROUP BY Shipping_Method
ORDER BY Others_Shipping_Count DESC

-- Ob¾úbené KATEGÓRIE produktov Champions: Elektronika (23,64 %), Potraviny (22,43 %), Dekorácie (18,08 %), Knihy (17,97 %), Obleèenie (17,79 %)
SELECT Product_Category, COUNT(t.Customer_ID) AS Champions_product_category_Count, 
ROUND ((COUNT(t.Customer_ID) * 100.0 / (SELECT COUNT(Customer_ID) FROM #temp_rfm WHERE rfm_segment = 'Champions')), 2) AS Champions_product_category_percentage
FROM #temp_rfm AS t
INNER JOIN retail_data AS r
ON r.Customer_ID = t.Customer_ID 
WHERE rfm_segment = 'Champions'
AND Product_Category IS NOT NULL
GROUP BY Product_Category
ORDER BY Champions_product_category_Count DESC;

-- Oblúbené KATEGÓRIE produktov Ostatní: Elektronika (23,61 %), Potraviny (22,05 %), Oblecenie (18,17 %), Knihy (18,08 %) Dekorácie (18,00 %)
SELECT Product_Category, COUNT(t.Customer_ID) AS Others_product_category_Count, 
ROUND ((COUNT(t.Customer_ID) * 100.0 / (SELECT COUNT(Customer_ID) FROM #temp_rfm WHERE rfm_segment <> 'Champions')), 2) AS Others_product_category_percentage
FROM #temp_rfm AS t
INNER JOIN retail_data AS r
ON r.Customer_ID = t.Customer_ID 
WHERE rfm_segment <> 'Champions'
AND Product_Category IS NOT NULL
GROUP BY Product_Category
ORDER BY Others_product_category_Count DESC;

-- NAJOBLÚBENEJŠIE PRODUKTY z kategórie elektronika Champions: Motorola Moto, iPhone, Samsung Galaxy, Huawei P, LG G, OnePlus, Google Pixel, Nokia, Sony Xperia, Xiaomi Mi
-- pri èistení dát som zistila, že produkty sú v datasete zapísané štýlom znaèka + typ (bez konkrétneho upresnenia napr. kód) alebo len znaèka (bez typu) 
-- dáta som nechala zapísané takto, no pre konkrétnejšie výsledky by bolo dobré doplni konkrétne typy zakúpených produktov z inej tabu¾ky (pri práci s reálnymi dátami)
SELECT TOP 10 products, COUNT(t.Customer_ID) AS Champions_Products_Count
FROM retail_data AS r
INNER JOIN #temp_rfm AS t
ON r.Customer_ID = t.Customer_ID 
WHERE rfm_segment = 'Champions'
AND Product_Category = 'Electronics'
AND products IS NOT NULL
GROUP BY products
ORDER BY Champions_Products_Count DESC;

-- NAJOBLÚBENEJŠIE PRODUKTY z kategórie elektronika Ostatné kategórie: Motorola Moto, Google Pixel, Xiaomi Mi, Samsung Galaxy, OnePlus, Sony Xperia, Huawei P, iPhone, LG G, Nokia
SELECT TOP 10 products, COUNT(t.Customer_ID) AS Others_Products_Count
FROM retail_data AS r
INNER JOIN #temp_rfm AS t
ON r.Customer_ID = t.Customer_ID 
WHERE rfm_segment <> 'Champions'
AND Product_Category = 'Electronics'
AND products IS NOT NULL
GROUP BY products
ORDER BY Others_Products_Count DESC;

-- NAJOBLÚBENEJŠIE ZNAÈKY Champions
-- rozdiely by mohli by v drahších znaèkách, ktoré nakupujú TOP zákazníci
-- TOP 10: Pepsi, Coca-Cola, Samsung, Home Depot, Sony, Bed Bath & Beyond, HarperCollins, Apple, Nike, Nestle
-- na rozdiel od ostatných vidíme, že èastejšie nakupujú z kategórie dekorácii znaèku Home Depot, z potravín ide o znaèky Pepsi a Coca Cola a z ich TOP kategórie elektroniky Sony a Apple
SELECT TOP 10 Product_Brand, COUNT(t.Customer_ID) AS Champions_Brands_Count
FROM retail_data AS r
INNER JOIN #temp_rfm AS t
ON r.Customer_ID = t.Customer_ID 
WHERE rfm_segment = 'Champions'
AND Product_Brand IS NOT NULL
GROUP BY Product_Brand
ORDER BY Champions_Brands_Count DESC;

--- NAJOBLÚBENEJŠIE ZNAÈKY Ostatné kategórie:Pepsi, Zara, Samsung, HarperCollins, Coca-Cola, Adidas, Sony, Bed Bath & Beyond, Penguin Books, Random House
SELECT TOP 10 Product_Brand, COUNT(t.Customer_ID) AS Champions_Brands_Count
FROM retail_data AS r
INNER JOIN #temp_rfm AS t
ON r.Customer_ID = t.Customer_ID 
WHERE rfm_segment <> 'Champions'
AND Product_Brand IS NOT NULL
GROUP BY Product_Brand
ORDER BY Champions_Brands_Count DESC;

-- HYPOTÉZA 1: Zákazníci s vyššími príjmami (Income) nakupujú castejšie, pravidelnejšie a utrácajú viac. 
-- High Income skupina má všetky tri ukazovatele na priemerných hodnotách - 3,3,3 
-- najèastejšie, najpravidelnejšie a najviac utrácajú nízkopríjmové skpiny (priemerné skóre za kategórie je 2,2,2
-- ¾udia so stredným príjmom utrácajú trochu menej ako ¾udia s nízkym príjmom, ale rovnako èasto a pravidelne (2,2,3)
-- Hypotéza sa nepotvrdila, najvyššie skóre vo všetkých segmentoch majú zákazníci s nízkym príjmom
SELECT Income,
AVG(score_frequency) AS avg_frequency,
AVG(score_recency) AS avg_recency,
AVG(score_monetary) AS avg_monetary,
COUNT(DISTINCT t.Customer_ID) AS customers
FROM retail_data AS r
JOIN #temp_rfm AS t 
ON r.Customer_ID = t.Customer_ID
WHERE Income IS NOT NULL
GROUP BY Income
ORDER BY Income;

-- analýza príjmových skupín na základe typov zákazníkov v RFM modeli
SELECT Income,rfm_segment,COUNT(*) AS customers
FROM retail_data r
JOIN #temp_rfm t 
ON r.Customer_ID = t.Customer_ID
WHERE Income IS NOT NULL
GROUP BY Income, t.rfm_segment
ORDER BY Income, customers DESC;

-- H2: Niektoré vekové skupiny (Age) majú vyšší priemerný poèet nákupov a vyššiu hodnotu nákupov.
-- Najväèšiu priemernú frekvenciu nákupov a najvyššiu priemernú hodnotu nákupov má skupina ¾udí vo veku od 36-55 (skóre monetary 2 a frequency 2). 
-- 18-35 roèní nakupujú rovnako frekventovane, ale majú nižšiu priemernú hodnotu nákupov (monetary skóre 3) ako skupina ¾udí vo veku od 36-55.
-- Najstaršia skupina zákazníkov, vo veku od 56 rokov, má strednú frekvenciu nákupov ako 36-55 roèní (skóre 3), ale v priemere majú rovnakú hodnotu nákupov (skóre 2).
-- Záver: Áno, Najvyššiu frekvenciu a hodnotu nákupov pozorujeme u ¾udú vo veku od 36-55 rokov. 
SELECT 
CASE 
WHEN Age BETWEEN 18 AND 35 THEN '18-35'
WHEN Age BETWEEN 36 AND 55 THEN '36-55'
WHEN Age >= 56 THEN '56+'
END AS age_group,
COUNT(t.Customer_ID) AS customers,
AVG(score_frequency) AS avg_frequency,
AVG(score_recency) AS avg_recency,
AVG(score_monetary) AS avg_monetary
FROM retail_data AS r
JOIN #temp_rfm AS t 
ON r.Customer_ID = t.Customer_ID
WHERE Age IS NOT NULL
GROUP BY 
CASE 
WHEN Age BETWEEN 18 AND 35 THEN '18-35'
WHEN Age BETWEEN 36 AND 55 THEN '36-55'
WHEN Age >= 56 THEN '56+'
END
ORDER BY avg_monetary DESC;

-- analýza vekových skupín na základe typov zákazníkov v RFM modeli
SELECT 
CASE 
WHEN Age BETWEEN 18 AND 35 THEN '18-35'
WHEN Age BETWEEN 36 AND 55 THEN '36-55'
WHEN Age >= 56 THEN '56+'
END AS age_group,
rfm_segment,
COUNT(t.Customer_ID) AS customers_in_segment 
FROM retail_data AS r
JOIN #temp_rfm AS t 
ON r.Customer_ID = t.Customer_ID
WHERE r.Age IS NOT NULL
GROUP BY 
CASE 
WHEN r.Age BETWEEN 18 AND 35 THEN '18-35'
WHEN r.Age BETWEEN 36 AND 55 THEN '36-55'
WHEN r.Age >= 56 THEN '56+'
END,rfm_segment
ORDER BY age_group ASC;

--- H3: Zákazníci v urcitých mestách/krajinách generujú vyššie tržby.
--- zistenie, v ktorých krajinách je najviac zákazníkov, ktorí geneàujú najvyššie tržby + poèty: 1. USA, 2. UK, 3. Nemecko, 4. Kanada, 5. Austrália
--- Potvrdenie hypotézy: Áno, zákazníci v USA (31%), UK (21%) a Nemecku (17%) generujú významne vyššie tržby – spolu tvoria takmer 70 % celkových tržieb firmy.
WITH country_revenue AS 
(
SELECT Country,
COUNT(DISTINCT t.Customer_ID) AS customer_count,
SUM(t.score_monetary) AS total_revenue
FROM #temp_rfm t
JOIN retail_data r 
ON t.Customer_ID = r.Customer_ID
WHERE Country IS NOT NULL
GROUP BY Country
),
with_percentage AS 
(
SELECT Country,customer_count,total_revenue, SUM(total_revenue) OVER () AS overall_revenue
FROM country_revenue
)
SELECT Country,customer_count,total_revenue, (total_revenue * 100.0 / overall_revenue) AS revenue_percentage
FROM with_percentage
ORDER BY total_revenue DESC;

--- pozrieme sa na USA (ako TOP odoberate¾a) = najdrahšie objednávky sú v Connecticut (23% z USA), Maine (13%), Georgia (10%) = spolu 46 %
WITH USA_revenue AS 
(
SELECT State,
COUNT(DISTINCT t.Customer_ID) AS customer_count,
SUM(t.score_monetary) AS total_revenue
FROM #temp_rfm t
JOIN retail_data r 
ON t.Customer_ID = r.Customer_ID
WHERE State IS NOT NULL AND
Country = 'USA'
GROUP BY State
),
with_percentage AS 
(
SELECT State, customer_count,total_revenue, SUM(total_revenue) OVER () AS overall_revenue
FROM USA_revenue
)
SELECT State,customer_count,total_revenue, (total_revenue * 100.0 / overall_revenue) AS revenue_percentage
FROM with_percentage
ORDER BY total_revenue DESC;

--- Pozrieme sa ešte na zákazníkov v USA pod¾a miest - najviac Chicago (23%), San Francisco (12%), Boston (9%), New York (5,8%, Fort Worth (5,4%)
WITH USA_city_revenue AS 
(
SELECT City,
COUNT(DISTINCT t.Customer_ID) AS customer_count,
SUM(t.score_monetary) AS total_revenue
FROM #temp_rfm t
JOIN retail_data r 
ON t.Customer_ID = r.Customer_ID
WHERE City IS NOT NULL AND
Country = 'USA'
GROUP BY City
),
with_percentage AS 
(
SELECT City, customer_count,total_revenue, SUM(total_revenue) OVER () AS overall_revenue
FROM USA_city_revenue
)
SELECT City,customer_count,total_revenue, (total_revenue * 100.0 / overall_revenue) AS revenue_percentage
FROM with_percentage
ORDER BY total_revenue DESC;

--- pozrieme sa na UK (druhého TOP) - nepomerne najvyššie tržby v meste Portsmouth (32%),ostatné mestá -  Plymouth, Birmingham, Nottingham, Liverpool len okolo 3%
-- Otázka na budúcu analýzu: Preco má Portsmouth nepomerne vyššie tržby ako ostatné mestá? Je nieco, co by sme moli aplikovat v iných mestách, aby sa zvýšili tržby aj v nich?
WITH UK_city_revenue AS 
(
SELECT City,
COUNT(DISTINCT t.Customer_ID) AS customer_count,
SUM(t.score_monetary) AS total_revenue
FROM #temp_rfm t
JOIN retail_data r 
ON t.Customer_ID = r.Customer_ID
WHERE City IS NOT NULL AND
Country = 'UK'
GROUP BY City
),
with_percentage AS 
(
SELECT City, customer_count,total_revenue, SUM(total_revenue) OVER () AS overall_revenue
FROM UK_city_revenue
)
SELECT City,customer_count,total_revenue, (total_revenue * 100.0 / overall_revenue) AS revenue_percentage
FROM with_percentage
ORDER BY total_revenue DESC;






