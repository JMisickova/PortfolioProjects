
USE Retail_customer;

-- Z¡KLADN¡ EXPLOR¡CIA D¡T zameran· na z·kaznÌkov celkovo

-- za akÈ dlhÈ obdobie m·me d·ta - 1.3.2023 do 29.2. 2024 (rok)
SELECT MAX(date) AS maximum_date, MIN (date) AS minimum_date
FROM retail_data;

-- koæko z·kaznÌkov za toto obdobie firma mala = 294 423
SELECT COUNT(DISTINCT Customer_ID) as count_customers
FROM retail_data;

-- ako zast˙penÈ s˙ jednotlivÈ z·kaznÌckÈ segmenty - Regular (142 900 z·k.) 48,57 %, New (88 822 z·k.) 30,19 % a Premium (62 492 z·k.) 21,24 %, 
SELECT
COUNT (DISTINCT Customer_ID) AS count_customers, Customer_Segment,
ROUND ((COUNT(Customer_Segment) * 100.0 / (SELECT COUNT(*) FROM retail_data WHERE Customer_Segment IS NOT NULL)), 2) AS Customer_Segment_percentage
FROM retail_data
WHERE Customer_Segment IS NOT NULL
GROUP BY Customer_Segment
ORDER BY count_customers DESC;

-- akÈ m· firma ohlasy (feedback) od z·kaznÌkov = Excellent (98 446) 33,46 %, Good (92 909) 31,58 %, Average (60 956) 20,72 % a Bad (41 932) 14,25 %
SELECT Feedback, 
COUNT(Feedback) AS count_feedback,
ROUND ((COUNT(Feedback) * 100.0 / (SELECT COUNT(*) FROM retail_data WHERE Feedback IS NOT NULL)), 2) AS Feedback_percentage
FROM retail_data
WHERE Feedback IS NOT NULL
GROUP BY Feedback
ORDER BY COUNT(Feedback) DESC;

-- akÈ s˙ najobæ˙benejöie doruËovacie metÛdy = Same-Day (101 587) 34,54 %, Express (99 784) 33,93 %, Standard (92 725) 31,53 %
SELECT Shipping_Method, 
COUNT(Shipping_Method) AS count_Shipping_Method, 
ROUND((COUNT(Shipping_Method) * 100.0 / (SELECT COUNT(*) FROM retail_data WHERE Shipping_Method IS NOT NULL)), 2) AS shipping_method_percentage
FROM retail_data
WHERE Shipping_Method IS NOT NULL
GROUP BY Shipping_Method
ORDER BY COUNT(Shipping_Method) DESC;

-- Z¡KLADN… DEMOGRAFICK… ⁄DAJE o z·kaznÌkoch

-- 1.PRÕJEM - æudia so stredn˝m prÌjmom (127 077), nÌzkym (93 671), vysok˝m (73 392)
SELECT Income, COUNT(DISTINCT Customer_ID) AS customer_count
FROM retail_data
WHERE Income IS NOT NULL
GROUP BY Income
ORDER BY Income DESC;

-- 2. VEK - pre jednoduchöiu interpret·ciu boli z·kaznÌci zaradenÌ do vekov˝ch skupÌn
-- z·kaznÌci s˙ najËastejöie mladÌ æudia 173 930 (18-35r.), potom æudia v strednom veku 82 529 (36-55r.) a starÌ æudia 37 794 (nad 56r.)
SELECT 
COUNT(DISTINCT CASE WHEN Age BETWEEN 18 AND 35 THEN Customer_ID END) AS Customers_18_35,
COUNT(DISTINCT CASE WHEN Age BETWEEN 36 AND 55 THEN Customer_ID END) AS Customers_36_55,
COUNT(DISTINCT CASE WHEN Age >= 56 THEN Customer_ID END) AS Customers_56_max
FROM retail_data
WHERE Age IS NOT NULL;

-- 3. POHLAVIE - v‰Ëöinou muûi - 182 873 z., ûeny = 111 243 z.
SELECT Gender, COUNT(DISTINCT Customer_ID) AS customer_count
FROM retail_data
WHERE Gender IS NOT NULL
GROUP BY Gender
ORDER BY Gender DESC;

-- 4. KRAJINA - USA (93 081 z·k.), UK (61 552 z·k.), Nemecko (51 427 z·k.), Kanada (44 026 z·k.), Austr·lia (44 072)
SELECT Country, COUNT(DISTINCT Customer_ID) AS customer_count
FROM retail_data
WHERE Country IS NOT NULL
GROUP BY Country
ORDER BY Country DESC;

-- ANAL›ZA NA Z¡KLADE BIZNIS OT¡ZKY A HYPOT…Z
-- potreba vypoËÌtania RFM skÛre na zistenie TOP z·kaznÌkov firmy a ich charakteristiky

-- vypoËet Recency - Koæko dnÌ uplynulo od poslednÈho n·kupu z·kaznÌka po najnovöÌ d·tum v datasete
SELECT Customer_ID, DATEDIFF (DAY, MAX(date), 
(SELECT MAX(date) FROM retail_data)) AS recency_days
FROM retail_data
WHERE Customer_ID IS NOT NULL
GROUP BY Customer_ID;

-- v˝poËet Frequency - koækokr·t z·kaznÌk nak˙pil
SELECT Customer_ID, COUNT(DISTINCT Transaction_ID) AS frequency
FROM retail_data
WHERE Customer_ID IS NOT NULL
GROUP BY Customer_ID;

-- V˝poËet Monetary - koæko z·kaznÌk celkovo minul
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

-- vytvorenie z·kaznickÈho skÛre (1-5) 
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

-- predprÌprava temporary table s rfm ˙dajmi
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

-- vytvorenie Temporary table s RFM tak, aby som s v˝sledky mohla jednoducho Ôalej analyzovaù
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

-- kontrola tabuæky a kontrola, Ëi sa v nej nach·dzaj˙ 0 (pre bud˙cu anal˝zu)
SELECT * FROM #temp_rfm;

SELECT * FROM #temp_rfm
WHERE score_frequency = 0 
OR score_monetary = 0 
OR score_recency = 0;

-- doplnenie tabuæky o identifik·ciu skupÌn z·kaznÌkov
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

-- PoËet z·kaznÌkov v jednotliv˝ch skupin·ch
SELECT COUNT(*) AS count_customers, rfm_segment
FROM #temp_rfm 
GROUP BY rfm_segment;

-- kontrola, Ëi sa ËÌslo zhoduje s poËtom z·kaznÌkov v datab·ze = kaûd˝ z·kaznÌk m· v tabuæke #temp_rfm unik·tne Customer_ID, DISTINCT uû nemusÌm pouûÌvaù
SELECT DISTINCT Customer_ID
FROM retail_data;

-- Biznisov· ot·zka:ÑKtorÌ z·kaznÌci maj˙ najvyööiu hodnotu pre firmu a ako sa lÌöia od ostatn˝ch?ì
-- identifik·cia najloal·jnejöÌch / najziskovejöÌch z·kaznÌkov = tzv. "Champions"
-- poËet Champions = 46 934 z·k.
Select COUNT(*) as Champions_Count
FROM #temp_rfm
WHERE rfm_segment = 'Champions';

-- PRÕJEM Champions - Medium 20 191 (43,02 %), Low 14 997 (31,95%), High 11 694 (24,92%)
SELECT Income, COUNT(t.Customer_ID) AS Champions_Income_Count, 
ROUND ((COUNT(t.Customer_ID) * 100.0 / (SELECT COUNT(Customer_ID) FROM #temp_rfm WHERE rfm_segment = 'Champions')), 2) AS Champions_Income_percentage
FROM #temp_rfm AS t
INNER JOIN retail_data AS r
ON r.Customer_ID = t.Customer_ID 
WHERE rfm_segment = 'Champions'
AND Income IS NOT NULL
GROUP BY Income
ORDER BY Income DESC;

-- POHLAVIE Champions = 29 121 muûov (62,05 %), 17 759 ûien (37,84)
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
-- Priemern˝ vek v Champions je 35 rokov a modus (najËastejöÌ vek Champion z·kaznÌka) je 20 (20-roËn˝ch m·me aû 5441 z.)
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

-- DORU»OVACIA MET”DA Champions = Same-Day (16 185) 34,48 %, Express (15 894) 33,86 %, Standard (14 803) 31,54 %
SELECT Shipping_Method, COUNT(t.Customer_ID) AS Champions_Shipping_Count, 
ROUND ((COUNT(t.Customer_ID) * 100.0 / (SELECT COUNT(Customer_ID) FROM #temp_rfm WHERE rfm_segment = 'Champions')), 2) AS Champions_Shipping_percentage
FROM #temp_rfm AS t
INNER JOIN retail_data AS r
ON r.Customer_ID = t.Customer_ID 
WHERE rfm_segment = 'Champions'
AND Shipping_Method IS NOT NULL
GROUP BY Shipping_Method
ORDER BY Champions_Shipping_Count DESC;

-- TOTAL REVENUE (celkov˝ v˝nos) Champions / v porovnanÌ s ostatn˝mi = Champions tvoria aû 30 % z celkov˝ch trûieb firmy za rok, ale predbiehaj˙ ich Big Spenders, ktorÌ tvoria 45% celkov˝ch trûieb
-- Spolu teda tieto skupiny z·kaznÌkov tvoria aû 75% celkov˝ch trûieb firmy
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

-- porovnanie obæubenej doruËovacej metÛdy s ostatn˝mi: Same-Day 101 587 (41,05 %), Express 99 784 (40,32 %), Standard 92 725 (37,47 %) (bez v‡aznÈho rozdielu v porovnanÌ s Champions)
SELECT Shipping_Method, COUNT(DISTINCT r.Customer_ID) AS Others_Shipping_Count,
ROUND ((COUNT(t.Customer_ID) * 100.0 / (SELECT COUNT(Customer_ID) FROM #temp_rfm WHERE rfm_segment <> 'Champions')), 2) AS Others_Shipping_percentage
FROM #temp_rfm AS t
INNER JOIN retail_data AS r
ON t.Customer_ID = r.Customer_ID
WHERE CONCAT(score_recency, score_frequency, score_monetary) <> 'Champions'
AND Shipping_Method IS NOT NULL
GROUP BY Shipping_Method
ORDER BY Others_Shipping_Count DESC

-- Obæ˙benÈ KATEG”RIE produktov Champions: Elektronika (23,64 %), Potraviny (22,43 %), Dekor·cie (18,08 %), Knihy (17,97 %), ObleËenie (17,79 %)
SELECT Product_Category, COUNT(t.Customer_ID) AS Champions_product_category_Count, 
ROUND ((COUNT(t.Customer_ID) * 100.0 / (SELECT COUNT(Customer_ID) FROM #temp_rfm WHERE rfm_segment = 'Champions')), 2) AS Champions_product_category_percentage
FROM #temp_rfm AS t
INNER JOIN retail_data AS r
ON r.Customer_ID = t.Customer_ID 
WHERE rfm_segment = 'Champions'
AND Product_Category IS NOT NULL
GROUP BY Product_Category
ORDER BY Champions_product_category_Count DESC;

-- Obæ˙benÈ KATEG”RIE produktov OstatnÌ: Elektronika (23,61 %), Potraviny (22,05 %), ObleËenie (18,17 %), Knihy (18,08 %) Dekor·cie (18,00 %)
SELECT Product_Category, COUNT(t.Customer_ID) AS Others_product_category_Count, 
ROUND ((COUNT(t.Customer_ID) * 100.0 / (SELECT COUNT(Customer_ID) FROM #temp_rfm WHERE rfm_segment <> 'Champions')), 2) AS Others_product_category_percentage
FROM #temp_rfm AS t
INNER JOIN retail_data AS r
ON r.Customer_ID = t.Customer_ID 
WHERE rfm_segment <> 'Champions'
AND Product_Category IS NOT NULL
GROUP BY Product_Category
ORDER BY Others_product_category_Count DESC;

-- NAJOBº⁄BENEJäIE PRODUKTY z kategÛrie elektronika Champions: Motorola Moto, iPhone, Samsung Galaxy, Huawei P, LG G, OnePlus, Google Pixel, Nokia, Sony Xperia, Xiaomi Mi
-- pri ËistenÌ d·t som zistila, ûe produkty s˙ v datasete zapÌsanÈ öt˝lom znaËka + typ (bez konkrÈtneho upresnenia napr. kÛd) alebo len znaËka (bez typu) 
-- d·ta som nechala zapÌsanÈ takto, no pre konkrÈtnejöie v˝sledky by bolo dobrÈ doplniù konkrÈtne typy zak˙pen˝ch produktov z inej tabuæky (pri pr·ci s re·lnymi d·tami)
SELECT TOP 10 products, COUNT(t.Customer_ID) AS Champions_Products_Count
FROM retail_data AS r
INNER JOIN #temp_rfm AS t
ON r.Customer_ID = t.Customer_ID 
WHERE rfm_segment = 'Champions'
AND Product_Category = 'Electronics'
AND products IS NOT NULL
GROUP BY products
ORDER BY Champions_Products_Count DESC;

-- NAJOBº⁄BENEJäIE PRODUKTY z kategÛrie elektronika OstatnÈ kategÛrie: Motorola Moto, Google Pixel, Xiaomi Mi, Samsung Galaxy, OnePlus, Sony Xperia, Huawei P, iPhone, LG G, Nokia
SELECT TOP 10 products, COUNT(t.Customer_ID) AS Others_Products_Count
FROM retail_data AS r
INNER JOIN #temp_rfm AS t
ON r.Customer_ID = t.Customer_ID 
WHERE rfm_segment <> 'Champions'
AND Product_Category = 'Electronics'
AND products IS NOT NULL
GROUP BY products
ORDER BY Others_Products_Count DESC;

-- NAJOBº⁄BENEJäIE ZNA»KY Champions
-- rozdiely by mohli byù v drahöÌch znaËk·ch, ktorÈ nakupuj˙ TOP z·kaznÌci
-- TOP 10: Pepsi, Coca-Cola, Samsung, Home Depot, Sony, Bed Bath & Beyond, HarperCollins, Apple, Nike, Nestle
-- na rozdiel od ostatn˝ch vidÌme, ûe Ëastejöie nakupuj˙ z kategÛrie dekor·cii znaËku Home Depot, z potravÌn ide o znaËky Pepsi a Coca Cola a z ich TOP kategÛrie elektroniky Sony a Apple
SELECT TOP 10 Product_Brand, COUNT(t.Customer_ID) AS Champions_Brands_Count
FROM retail_data AS r
INNER JOIN #temp_rfm AS t
ON r.Customer_ID = t.Customer_ID 
WHERE rfm_segment = 'Champions'
AND Product_Brand IS NOT NULL
GROUP BY Product_Brand
ORDER BY Champions_Brands_Count DESC;

--- NAJOBº⁄BENEJäIE ZNA»KY OstatnÈ kategÛrie:Pepsi, Zara, Samsung, HarperCollins, Coca-Cola, Adidas, Sony, Bed Bath & Beyond, Penguin Books, Random House
SELECT TOP 10 Product_Brand, COUNT(t.Customer_ID) AS Champions_Brands_Count
FROM retail_data AS r
INNER JOIN #temp_rfm AS t
ON r.Customer_ID = t.Customer_ID 
WHERE rfm_segment <> 'Champions'
AND Product_Brand IS NOT NULL
GROUP BY Product_Brand
ORDER BY Champions_Brands_Count DESC;

-- HYPOT…ZA 1: Z·kaznÌci s vyööÌmi prÌjmami (Income) nakupuj˙ Ëastejöie, pravidelnejöie a utr·caj˙ viac. 
-- High Income skupina m· vöetky tri ukazovatele na priemern˝ch hodnot·ch - 3,3,3 
-- najËastejöie, najpravidelnejöie a najviac utr·caj˙ nÌzkoprÌjmovÈ skpiny (priemernÈ skÛre za kategÛrie je 2,2,2
-- æudia so stredn˝m prÌjmom utr·caj˙ trochu menej ako æudia s nÌzkym prÌjmom, ale rovnako Ëasto a pravidelne (2,2,3)
-- HypotÈza sa nepotvrdila, najvyööie skÛre vo vöetk˝ch segmentoch maj˙ z·kaznÌci s nÌzkym prÌjmom
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

-- anal˝za prÌjmov˝ch skupÌn na z·klade typov z·kaznÌkov v RFM modeli
SELECT Income,rfm_segment,COUNT(*) AS customers
FROM retail_data r
JOIN #temp_rfm t 
ON r.Customer_ID = t.Customer_ID
WHERE Income IS NOT NULL
GROUP BY Income, t.rfm_segment
ORDER BY Income, customers DESC;

-- H2: NiektorÈ vekovÈ skupiny (Age) maj˙ vyööÌ priemern˝ poËet n·kupov a vyööiu hodnotu n·kupov.
-- Najv‰Ëöiu priemern˙ frekvenciu n·kupov a najvyööiu priemern˙ hodnotu n·kupov m· skupina æudÌ vo veku od 36-55 (skÛre monetary 2 a frequency 2). 
-- 18-35 roËnÌ nakupuj˙ rovnako frekventovane, ale maj˙ niûöiu priemern˙ hodnotu n·kupov (monetary skÛre 3) ako skupina æudÌ vo veku od 36-55.
-- Najstaröia skupina z·kaznÌkov, vo veku od 56 rokov, m· stredn˙ frekvenciu n·kupov ako 36-55 roËnÌ (skÛre 3), ale v priemere maj˙ rovnak˙ hodnotu n·kupov (skÛre 2).
-- Z·ver: ¡no, Najvyööiu frekvenciu a hodnotu n·kupov pozorujeme u æud˙ vo veku od 36-55 rokov. 
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

-- anal˝za vekov˝ch skupÌn na z·klade typov z·kaznÌkov v RFM modeli
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

--- H3: Z·kaznÌci v urËit˝ch mest·ch/krajin·ch generuj˙ vyööie trûby.
--- zistenie, v ktor˝ch krajin·ch je najviac z·kaznÌkov, ktorÌ gene‡uj˙ najvyööie trûby + poËty: 1. USA, 2. UK, 3. Nemecko, 4. Kanada, 5. Austr·lia
--- Potvrdenie hypotÈzy: ¡no, z·kaznÌci v USA (31%), UK (21%) a Nemecku (17%) generuj˙ v˝znamne vyööie trûby ñ spolu tvoria takmer 70 % celkov˝ch trûieb firmy.
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

--- pozrieme sa na USA (ako TOP odoberateæa) = najdrahöie objedn·vky s˙ v Connecticut (23% z USA), Maine (13%), Georgia (10%) = spolu 46 %
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

--- Pozrieme sa eöte na z·kaznÌkov v USA podæa miest - najviac Chicago (23%), San Francisco (12%), Boston (9%), New York (5,8%, Fort Worth (5,4%)
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

--- pozrieme sa na UK (druhÈho TOP) - nepomerne najvyööie trûby v meste Portsmouth (32%),ostatnÈ mest· -  Plymouth, Birmingham, Nottingham, Liverpool len okolo 3%
-- Ot·zka na bud˙cu anal˝zu: PreËo m· Portsmouth nepomerne vyööie trûby ako ostatnÈ mest·? Je nieËo, Ëo by sme moli aplikovaù v in˝ch mest·ch, aby sa zv˝öili trûby aj v nich?
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





