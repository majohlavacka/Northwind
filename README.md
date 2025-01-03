# ETL proces datasetu Northwind
Tento repozitár obsahuje implementáciu ETL procesu v Snowflake pre analýzu dát z Northwind datasetu. Projekt sa zameriava na analýzu správania zákazníkov a ich nákupných preferencií na základe informácií o objednávkach, produktoch a zákazníkoch. Výsledný dátový model umožňuje multidimenzionálnu analýzu a vizualizáciu kľúčových metrik, ako sú tržby, obľúbenosť produktov, a sezónne trendy.
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

Northwind databáza je verejne dostupná na [GitHube](https://github.com/microsoft/sql-server-samples/tree/master/samples/databases/northwind-pubs) a zahŕňa 8 hlavných tabuliek:

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
Pôvodne dáta, ktoré obsahuje databáza Northwind 
Surové dáta sú organizované v relačnom databázovom modeli, ktorý je vizualizovaný pomocou entitno-relačného diagramu (ERD). Tento diagram zobrazuje hlavné entity v databáze Northwind, ich atribúty a vzájomné vzťahy.
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

# 2 Dimenzionálny model
Na základe entito-relačnej schemy bol navrhnuty hviezdicový model (star scheme), ktorý slúži na efektívne organizovanie a analyzovanie dát.
Faktová tabuľka `fact_orderdetails` bola zvolená ako centrálny bod, pretože obsahuje detailné transakčné údaje o objednávkach, ktoré sú kľúčové pre analýzu.

Keďže sa jedná o hviezdicový model, je potrebné určiť dimenzionálne tabuľky, ktoré sú následovné:
- `dim_products`: Obsahuje informácie o produktoch vrátane ich názvu, ceny, kategórie a údajov o dodávateľoch.
- `dim_customers`: Uchováva údaje zákazníkov, ako meno, kontaktné údaje, mesto a krajinu.
- `dim_employees`:  Zaznamenáva informácie o zamestnancoch, ako sú mená a dátumy narodenia.
- `dim_shippers`: Obsahuje detaily o prepravcoch.
- `dim_time`: Poskytuje časové údaje o objednávkach vrátane dátumu, času a ďalších časových dimenzií (rok, mesiac, deň, AM/PM).

Po výbere faktovej tabuľky a dimenzionálnych tabuliek je ich štruktúra vytvorená v programe Workbench, čo zebezpečuje lepšie pochopenie a jednoduchšiu implementáciu.
<p align="center">
  <img src="Northwind_star_scheme.png" alt="Obrázok 2 Schéma hviezdy pre Northwind" width="500"/>
  <br>
  <i>Obrázok 2 Schéma hviezdy pre Northwind.</i>
</p>

# 3 ETL proces v Snowflake

ETL proces zahŕňa tri kľúčové kroky: extrakciu (Extract), transformáciu (Transform) a načítanie (Load). V prostredí Snowflake bol tento proces implementovaný na spracovanie zdrojových dát zo staging vrstvy, pričom výsledkom je viacdimenzionálny model optimalizovaný pre analýzu a vizualizáciu.

## 3.1 Extract (Extrahovanie dát)

Aby sa dáta z databázy Northwind mohli v Snowflake využivať je potrebné vytvoriť dočasné stage uložisko pomenované `my_stage`. V Snowflake následne tento stage nájdeme v sekci Add data -> Load files into a Stage. Aby sme tabuľky (.csv), nahrali do správneho stage, je potrebné vybrat našu vytovrenú databázu, schému a stage následovne: `KANGAROO_NORTHWIND_DB.STAGING` a vyberie sa `MY_STAGE`.
Vytvorenie stage bolo zabezpečené príkazom:

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

## 3.2 Transfor (Transformácia dát)

