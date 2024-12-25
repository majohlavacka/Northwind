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
<center>
  ![Obrázok 1 Entitno-relačná schéma Northwind](Northwind_ERD.png)
  <br>
  *Obrázok 1: Entitno-relačná schéma databázy Northwind.*
</center>


