# ETL proces datasetu Northwind
Repozitár obsahuje implementáciu ETL procesu v Snowflake, ktorý spracováva údaje z Northwind datasetu. Hlavným cieľom projektu je analýza správania zákazníkov a ich nákupných preferencií na základe dát o objednávkach, produktoch a zákazníkoch. Výsledný dátový model umožňuje multidimenzionálny pohľad na kľúčové metriky, ako sú tržby, popularita produktov a sezónne trendy, čím podporuje efektívnejšiu vizualizáciu a rozhodovanie.
# 1 Úvod a popis zdrojových dát
Cieľom tohto projektu je vykonať analýzu dát z Northwind databázy, ktorá obsahuje informácie o zákazníkoch, objednávkach, produktoch a zamestnancoch. Analýza sa zameriava na identifikáciu kľúčových obchodných trendov, zákazníckych preferencií a pracovných návykov zamestnancov, pričom tieto poznatky môžu slúžiť na optimalizáciu predajných stratégií a zvýšenie spokojnosti zákazníkov.

Ako prvý krok je potrebné zabezpečiť správne nastavenie používateľskej role, konkrétne training role, a využívať warehouse, ktorý je vytvorený na základe prideleného používateľského mena (KANGAROO). 

#### Príklad kódu:

```sql
USE ROLE TRAINING_ROLE;
CREATE WAREHOUSE IF NOT EXISTS KANGAROO_WH;
USE WAREHOUSE KANGAROO_WH;
```

Po nastavení správnej role a warehouse je ďalším krokom vytvorenie databázy a staging schémy na ukladanie a spracovanie dát.

#### Príklad kódu:

```sql
CREATE DATABASE IF NOT EXISTS KANGAROO_NORTHWIND_DB;
USE KANGAROO_NORTHWIND_DB;
CREATE SCHEMA IF NOT EXISTS KANGAROO_NORTHWIND_DB.STAGING;
USE SCHEMA KANGAROO_NORTHWIND_DB.STAGING
```

Northwind databáza zahŕňa 8 hlavných tabuliek:

- `orderdetails` 
- `products`
- `categories`
- `suppliers`
- `shippers`
- `orders`
- `customers`
- `employees`

Dáta z .sql súboru importujeme do lokálneho serveru MySQL a jednotlivé tabuľky vyexportujeme do .csv súborov. 
# 1.1 Dátová architektúra
Pôvodné dáta v databáze Northwind sú uložené v relačnom databázovom modeli. Tento model je vizualizovaný prostredníctvom entitno-relačného diagramu (ERD), ktorý znázorňuje hlavné entity, ich atribúty a vzájomné vzťahy medzi nimi. Tento diagram poskytuje prehľad o štruktúre a prepojeniach dát v databáze.
<p align="center">
  <img src="Northwind_ERD.png" alt="Obrázok 1 Entitno-relačná schéma Northwind" width="500"/>
  <br>
  <i>Obrázok 1: Entitno-relačná schéma databázy Northwind.</i>
</p>

Hlavné tabuľky zahŕňajú:

Categories (Kategórie): Umožňuje klasifikáciu produktov do rôznych skupín.
- `CategoryId` - Primárny kľúč.
- `CategoryName` - Názov kategórie.
- `Description` - Popis kategórie.

Products (Produkty): Detaily o produktoch predávaných spoločnosťou.
- `ProductId` - Primárny kľúč.
- `ProductName` - Názov produktu.
- `SupplierId` - Vzťah k tabuľke Suppliers.
- `CategoryId` - Vzťah k tabuľke Categories.
- `Unit, Price` - Informácie o balení a cene.

Suppliers (Dodávatelia): Informácie o dodávateľoch.
- `SupplierId` - Primárny kľúč.
- `CompanyName, ContactName, Address, City, Country` - Kontaktné informácie.

Shippers (Prepravcovia): Informácie o prepravovacej spoločnosti.
- `ShipperId` - Primárny kľúč.
- `ShipperName` - Názov prepravcu.
- `Phone` - Telefónne číslo.

Customers (Zákazníci): Informácie o zákazníkoch.
- `CustomerId` - Primárny kľúč.
- `CompanyName, Address, City, Country, Phone` - Kontaktné údaje.

Employees (Zamestnanci): Informácie o zamestnancoch.
- `EmployeeId` - Primárny kľúč.
- `LastName, FirstName, BirthDate, Notes` - Osobné údaje.

Orders (Objednávky): Informácie o oobjednávkach.
- `OrderId` - Primárny kľúč.
- `CustomerId` - Vzťah k tabuľke Customers.
- `EmployeeId` - Vzťah k tabuľke Employees.
- `OrderDate` - Dátum objednávky.
- `ShipperId` - Vzťah k tabuľke Shippers.

OrderDetails (Detaily objednávok): Spojovacia tabuľku medzi objednávkami a produktmi.
- `OrderDetailId` -  Primárny kľúč.
- `OrderId` - Vzťah k tabuľke Orders.
- `ProductId` - Vzťah k tabuľke Products.
- `Quantity` - Počet objednaných kusov.

Aby sme si overili, či sa tabuľky vytvorili správne použijeme príkaz `SHOW TABLES`.

# 2 Dimenzionálny model
Na základe entito-relačnej schemy bol navrhnuty hviezdicový model (star scheme), ktorý slúži na efektívne organizovanie a analyzovanie dát.
Faktová tabuľka `fact_orderdetails` bola zvolená ako centrálny bod, pretože obsahuje detailné transakčné údaje o objednávkach, ktoré sú kľúčové pre analýzu.

Keďže sa jedná o hviezdicový model, je potrebné určiť dimenzionálne tabuľky, ktoré sú následovné:
- `dim_products`: Obsahuje informácie o produktoch, ich cenách, kategóriách a dodávateľoch, vrátane kategorizácie cien (nízka, stredná, vysoká).
- `dim_customers`: Uchováva údaje zákazníkov ako meno, kontaktné údaje, mesto, krajinu a psč.
- `dim_employees`:  Zaznamenáva informácie o zamestnancoch ako sú mená, dátumy narodenia a vekové skupiny.
- `dim_shippers`: Obsahuje údaje o prepravcoch ako názov prepravcu a telefónne číslo.
- `dim_time`: Poskytuje časové údaje o objednávkach, vrátane dňa, mesiaca, roka, sezóny a dňa v týždni.

<p align="center">
  <img src="Northwind_starscheme.png" alt="Obrázok 2 Schéma hviezdy pre Northwind" width="500"/>
  <br>
  <i>Obrázok 2 Schéma hviezdy pre Northwind.</i>
</p>

Po výbere faktovej tabuľky a dimenzionálnych tabuliek je ich štruktúra vytvorená v programe Workbench, čo zebezpečuje lepšie pochopenie a jednoduchšiu implementáciu.


# 3 ETL proces v Snowflake

ETL proces zahŕňa tri kľúčové kroky: extrakciu (Extract), transformáciu (Transform) a načítanie (Load). V prostredí Snowflake bol tento proces implementovaný na spracovanie zdrojových dát zo staging vrstvy, pričom výsledkom je viacdimenzionálny model optimalizovaný pre analýzu a vizualizáciu.

## 3.1 Extrahovanie dát z tabuliek (EXTRACT)

Aby sa dáta z databázy Northwind mohli v Snowflake využivať je potrebné vytvoriť dočasné stage uložisko pomenované `my_stage`. V Snowflake následne tento stage nájdeme v sekci Add data -> Load files into a Stage. Aby sme tabuľky (.csv), nahrali do správneho stage, je potrebné vybrat našu vytovorenú databázu, schému a stage následovne: `KANGAROO_NORTHWIND_DB.STAGING` a vyberie sa `MY_STAGE`.

#### Príklad kódu:

```sql
CREATE OR REPLACE STAGE my_stage;
```
Do stage boli následne nahrané súbory obsahujúce údaje o rôznych entitách, ako sú kategórie, zákazníci, zamestnanci, objednávky, detaily objednávok, produkty, dodávatelia a prepravcovia. 
Dáta, ktoré boli nahraté do stage, boli následne naimportované do staging tabuliek prostredníctvom príkazu `COPY INTO`.

#### Príklad kódu:

```sql
COPY INTO products_staging
FROM @my_stage/products.csv
FILE_FORMAT = (TYPE = 'CSV' FIELD_OPTIONALLY_ENCLOSED_BY = '"' SKIP_HEADER = 1);
```
V prípade, že nastane pri importovani chyba, je možno použiť parameter `ON_ERROR = 'CONTINUE'`, ktorý zabezpečí pokračovanie procesu bez prerušenia.

#### Príklad kódu:

```sql
COPY INTO products_staging
FROM @my_stage/products.csv
FILE_FORMAT = (TYPE = 'CSV' FIELD_OPTIONALLY_ENCLOSED_BY = '"' SKIP_HEADER = 1)
ON_ERROR = 'CONTINUE';
```

Následne si overíme doplnené údaje prostredníctvom príkazu `DESCRIBE` a špecifikujeme danú tabuľku.

## 3.2 Transformácia dát do dimenzionálnych tabuliek (TRANSFER)

V kroku transformácie boli dáta upravené do podoby vhodnej na analytické využitie. Boli pripravené dimenzie a faktová tabuľka, ktoré tvoria pevný základ pre rýchle a presné vyhodnocovanie kľúčových ukazovateľov.

Dimenzionálna tabuľka dim_employees rozširuje údaje o zamestnancoch pridaním vekových kategórií (napr. 'Pod 20 rokov', '20-29 rokov', '30-39 rokov', '40-49 rokov', '50 a viac rokov'). Táto tabuľka využíva SCD Typ 1 (pomaly sa meniaca dimenzia), čo znamená, že pri zmene údajov sa veková kategória aktualizuje a starý záznam sa prepíše novým bez uchovávania histórie.

```sql
CREATE OR REPLACE TABLE dim_employees AS
SELECT DISTINCT
    EmployeeId AS employeesId,
    FirstName AS first_name,
    LastName AS last_name,
    BirthDate AS birth_date,
    CASE 
        WHEN DATE_PART(year, CURRENT_DATE) - DATE_PART(year, BirthDate) < 20 THEN 'Pod 20 rokov'
        WHEN DATE_PART(year, CURRENT_DATE) - DATE_PART(year, BirthDate) BETWEEN 20 AND 29 THEN '20-29 rokov'
        WHEN DATE_PART(year, CURRENT_DATE) - DATE_PART(year, BirthDate) BETWEEN 30 AND 39 THEN '30-39 rokov'
        WHEN DATE_PART(year, CURRENT_DATE) - DATE_PART(year, BirthDate) BETWEEN 40 AND 49 THEN '40-49 rokov'
        WHEN DATE_PART(year, CURRENT_DATE) - DATE_PART(year, BirthDate) >= 50 THEN '50 a viac rokov'
        ELSE 'Neznáme'
    END AS age_group
FROM employees_staging;
```

Dimenzionálna tabuľka `dim_products` obsahuje údaje o produktoch vrátane názvu produktu, kategórie, dodávateľa a ceny. Okrem základných informácií pridáva transformáciu kategorizácie cien do skupín – 'Nízka', 'Stredná' a 'Vysoká'. Táto tabuľka je navrhnutá ako SCD Typ 2, čo umožňuje sledovať historické zmeny cien a cenových kategórií v čase pomocou stĺpcov `valid_from` a `valid_to`.

```sql
CREATE OR REPLACE TABLE dim_products AS
SELECT DISTINCT
    ProductId AS productsId,
    ProductName AS product_name,
    COALESCE(CategoryName, 'Neznáma kategória') AS category_name,
    COALESCE(SupplierName, 'Neznámy dodávateľ') AS supplier_name,
    Price AS price,
    CASE 
        WHEN Price < 20 THEN 'Nízka'
        WHEN Price BETWEEN 20 AND 50 THEN 'Stredná'
        WHEN Price > 50 THEN 'Vysoká'
        ELSE 'Neznáme'
    END AS price_category,
    CURRENT_DATE AS valid_from,
    NULL AS valid_to
FROM products_staging
LEFT JOIN categories_staging ON products_staging.CategoryId = categories_staging.CategoryId
LEFT JOIN suppliers_staging ON products_staging.SupplierId = suppliers_staging.SupplierId;
```

Dimenzionálna tabuľka `dim_date` obsahuje dátumové údaje, ktoré sú rozšírené o odvodené informácie, ako sú deň, mesiac, rok, sezóna (Zima, Jar, Leto, Jeseň) a deň v týždni (Pondelok až Nedeľa). Deň v týždni začína pondelkom ako deň 1 a končí nedeľou ako deň 7. Táto tabuľka je typu SCD Typ 0, čo znamená, že údaje v nej sa nemenia po ich vytvorení a zostávajú statické. Tabuľka umožňuje podrobné časové analýzy objednávok na základe sezóny a dní v týždni.

```sql
CREATE OR REPLACE TABLE dim_date AS
SELECT DISTINCT
    ROW_NUMBER() OVER (ORDER BY OrderDate) AS datedId,
    TO_DATE(OrderDate) AS order_date,
    DATE_PART('day', OrderDate) AS den,
    DATE_PART('month', OrderDate) AS mesiac,
    DATE_PART('year', OrderDate) AS rok,
    CASE
        WHEN DATE_PART('month', OrderDate) IN (12, 1, 2) THEN 'Zima'
        WHEN DATE_PART('month', OrderDate) IN (3, 4, 5) THEN 'Jar'
        WHEN DATE_PART('month', OrderDate) IN (6, 7, 8) THEN 'Leto'
        WHEN DATE_PART('month', OrderDate) IN (9, 10, 11) THEN 'Jeseň'
        ELSE 'Neznáme'
    END AS sezona,
    CASE (DATE_PART('dow', OrderDate) + 1)
        WHEN 1 THEN 'Pondelok'
        WHEN 2 THEN 'Utorok'
        WHEN 3 THEN 'Streda'
        WHEN 4 THEN 'Štvrtok'
        WHEN 5 THEN 'Piatok'
        WHEN 6 THEN 'Sobota'
        WHEN 7 THEN 'Nedeľa'
    END AS den_v_tyzdni
FROM orders_staging;
```
Dimenzionálne tabuľky `dim_customers` a `dim_shippers` su taktiež typu SCD 0, pretože ich údaje sú statické a nemenia sa. 

Faktová tabuľka `fact_orderdetails` obsahuje podrobné záznamy o objednávkach a ich položkách. Obsahuje metriky, ako je množstvo objednaných položiek a celková cena vypočítaná na základe ceny produktov a počtu kusov. Tabuľka prepája všetky dimenzionálne tabuľky (dim_customers, dim_employees, dim_products, dim_shippers a dim_date), čím umožňuje analýzu objednávok z rôznych pohľadov, napríklad podľa zákazníkov, produktov, prepravcov alebo časového obdobia.

```sql
CREATE OR REPLACE TABLE fact_orderdetails AS
SELECT
    od.OrderDetailId AS orderdetails_id,
    o.OrderId AS order_id,
    c.customerId AS customer_id,
    e.employeesId AS employee_id,
    p.productsId AS product_id,
    s.shippersId AS shipper_id,
    d.datedId AS date_id,
    od.Quantity AS quantity,
    od.Quantity * p.Price AS total_price
FROM orderdetails_staging od
JOIN orders_staging o ON od.OrderId = o.OrderId
JOIN dim_customers c ON o.CustomerId = c.customerId
JOIN dim_employees e ON o.EmployeeId = e.employeesId
JOIN dim_products p ON od.ProductId = p.productsId
JOIN dim_shippers s ON o.ShipperId = s.shippersId
JOIN dim_date d ON TO_DATE(o.OrderDate) = d.order_date;
```
## 3.3  Načitanie dát do dimenzionálnych tabuliek (LOAD)

V záverečnej fáze procesu ETL boli dáta, po vyčistení a transformácii, nahraté do finálnych tabuliek dátového modelu Northwind. Následne boli staging tabuľky odstránené pomocou nasledujúcich príkazov, čím sa optimalizovalo využitie úložného priestoru v Snowflake.

```sql
DROP TABLE IF EXISTS suppliers_staging;
DROP TABLE IF EXISTS categories_staging;
DROP TABLE IF EXISTS products_staging;
DROP TABLE IF EXISTS customers_staging;
DROP TABLE IF EXISTS employees_staging;
DROP TABLE IF EXISTS shippers_staging;
DROP TABLE IF EXISTS orders_staging;
DROP TABLE IF EXISTS orderdetails_staging;
```

Výsledný dátový model Northwind umožňuje podrobnú analýzu obchodných procesov. Vďaka prepojeniu dimenzionálnych a faktovej tabuľky je možné sledovať predajné trendy podľa zákazníkov, produktov, zamestnancov a časového obdobia.

## 4 Vizualizácia dát

Posledným krokom projektu je vizualizácia dát prostredníctvom dashboardu v Snowflake, ktorý umožňuje zobrazovať interaktívne grafy a tabuľky. Dashboard bol navrhnutý s cieľom poskytnúť ucelený prehľad o obchodných procesoch simulovaných v Northwind databáze. Prostredníctvom grafov a reportov môžu používatelia ľahko analyzovať kľúčové metriky, ako sú objemy predajov, výkonnosť prepravných spoločností a trendy v objednávkach podľa času.

<p align="center">
  <img src="Dashboard_Northwind.png" alt="Obrázok 3 Dashboard Northwind predajov" width="800"/>
  <br>
  <i>Obrázok 3 Dashboard Northwind predajov.</i>
</p>


## Graf 1: TOP 10 najviac predávaných produktov  

Graf zobtazuje top 10 najpredávanejších produktov podľa celkového množstva predaja. Výstup zobrazuje názvy produktov spolu so súčtom predaných kusov. Tento výsledok pomáha obchodníkom identifikovať najžiadanejšie produkty, čo môže podporiť zlepšenie marketingových stratégií a rozhodovanie o prioritizácii zásob.

```sql
SELECT 
   p.product_name, 
   SUM(od.quantity) AS total_quantity
FROM fact_orderdetails od
  JOIN dim_products p ON od.product_id = p.productsId
GROUP BY p.product_name
ORDER BY total_quantity DESC
LIMIT 10;
```

## Graf 2: Objem objednávok podľa časového obdobia

Graf umožňuje sledovať predajné trendy v rôznych časových obdobiach, čo pomáha identifikovať sezónne výkyvy v predaji a plánovať marketingové kampane alebo zásoby na základe historických dát.

```sql
SELECT 
    d.rok, 
    d.mesiac, 
    SUM(od.total_price) AS monthly_sales
FROM fact_orderdetails od
JOIN dim_date d ON od.date_id = d.datedId
GROUP BY d.rok, d.mesiac
ORDER BY d.rok, d.mesiac;
```

## Graf 3: Počet objednávok podľa cenových kategórií produktov

Graf zobrazuje počet objednávok podľa cenových kategórií produktov, pričom produkty sú rozdelené do kategórií „Nízka“, „Stredná“ a „Vysoká“ na základe ich ceny a pomáha pochopiť, ktoré cenové kategórie produktov sú najobľúbenejšie medzi zákazníkmi, čo je dôležité pre plánovanie cenovej politiky a marketingových stratégií.

```sql
SELECT 
   p.price_category, 
   COUNT(od.order_id) AS total_orders
FROM fact_orderdetails od
JOIN dim_products p ON od.product_id = p.productsId
GROUP BY p.price_category
ORDER BY total_orders DESC;
```

## Graf 4: Trend predaja podľa sezón

Graf zobrazuje trend predaja podľa sezón (Zima, Jar, Leto, Jeseň). Výstup grafu umožňuje identifikovať, v ktorom ročnom období sú predaje najvyššie, čo pomáha firmám prispôsobiť marketingové kampane a zásobovanie sezónnym výkyvom v dopyte.

```sql
SELECT 
   d.sezona, 
   SUM(od.total_price) AS total_sales
FROM fact_orderdetails od
JOIN dim_date d ON od.date_id = d.datedId
GROUP BY d.sezona
ORDER BY total_sales DESC;
```

## Graf 5: Počet objednávok podľa prepravných spoločností

Graf zobrazuje počet objednávok rozdelených podľa prepravných spoločností. Výstup umožňuje analyzovať, ktorá prepravná spoločnosť spracováva najviac objednávok, čo môže pomôcť pri rozhodovaní o spolupráci a optimalizácii logistických procesov. 

```sql
SELECT 
    s.shipper_name, 
    COUNT(od.order_id) AS total_orders
FROM fact_orderdetails od
JOIN dim_shippers s ON od.shipper_id = s.shippersId
GROUP BY s.shipper_name
ORDER BY total_orders DESC;
```
#### Autor: Marián Hlavačka
