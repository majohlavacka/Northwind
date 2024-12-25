# ETL proces datasetu Northwind
Tento repozitár obsahuje implementáciu ETL procesu v Snowflake pre analýzu dát z Northwind datasetu. Projekt sa zameriava na analýzu správania zákazníkov a ich nákupných preferencií na základe informácií o objednávkach, produktoch a zákazníkoch. Výsledný dátový model umožňuje multidimenzionálnu analýzu a vizualizáciu kľúčových metrik, ako sú tržby, obľúbenosť produktov, a sezónne trendy.
# 1. Úvod a popis zdrojových dát
Cieľom tohto semestrálneho projektu je analyzovať dáta o zákazníkoch, objednávkach, produktoch a zamestnancoch v Northwind databáze. Projekt sa zameriava na identifikáciu obchodných trendov, preferencií zákazníkov a správanie zamestnancov, ktoré môžu pomôcť pri optimalizácii predajov a poskytovaní lepších služieb zákazníkom.

Zdrojové dáta pochádzajú z datasetu na githube [tu](https://github.com/microsoft/sql-server-samples/tree/master/samples/databases/northwind-pubs). Dataset obsahuje 8 hlavných tabuliek:

- `orderdetails`
- `products`
- `categories`
- `suppliers`
- `shippers`
- `orders`
- `customers`
- `employees`

Účelom ETL procesu bolo tieto dáta pripraviť, transformovať a sprístupniť pre viacdimenzionálnu analýzu.
# 1.1 Dátová architektúra
Surové dáta sú usporiadané v relačnom modeli, ktorý je znázornený na entitno-relačnom diagrame (ERD):
<p align="center">
  <img src="Northwind_ERD.png" alt="Obrázok 1 Entitno-relačná schéma Northwind" width="500"/>
  <br>
  <i>Obrázok 1: Entitno-relačná schéma databázy Northwind.</i>
</p>

# 2 Dimenzionálny model
Navrhnutý bol hviezdicový model (star schema), pre efektívnu analýzu kde centrálny bod predstavuje faktová tabuľka `fact_sales`, ktorá vychádza z tabuliek orders a orderdetails a je prepojená s nasledujúcimi dimenziami:
- `dim_products`: Obsahuje informácie o produktoch (názov, cena, dodávateľ).
- `dim_categories`: Uchováva údaje o kategóriách produktov.
- `dim_suppliers`: Poskytuje informácie o dodávateľoch (názov, krajina).
- `dim_customers`: Zahŕňa údaje o zákazníkoch (meno, adresa, krajina).
- `dim_employees`: Obsahuje údaje o zamestnancoch (meno, pozícia, pracovisko)

Štruktúra hviezdicového modelu je znázornená na diagrame nižšie. Diagram ukazuje prepojenia medzi faktovou tabuľkou a dimenziami, čo zjednodušuje pochopenie a implementáciu modelu.

