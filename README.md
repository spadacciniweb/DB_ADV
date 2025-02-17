# Esercizi vari del corso

## Esercizio 0

L'esercizio è composto dai seguenti step:

1. Importare nel DB i csv in cui:
    - la tabella `bank_account` avrà le due colonne `available_balance` e `accounting_balance` popolate in maniera equivalente al campo `euro` del csv;
    - la tabella `bank_movement` avrà la colonna `euro` equivalente al merge dei campi `type` e `euro` del csv, in particolare il segno della colonna `euro` sarà in accordo alla tipologia del movimento (quindi `+` e `-` nella colonna `euro` sostituiranno rispettivamente `ADD` e `SUB` del campo `type`).
2. Processare i movimenti nella tabella `bank_movement` e aggiornare la corrispondente disponibilità nella colonna `available_balance` della tabella `bank_account`, Solo al termine del processamento dei movimenti, aggiornare il campo `accounting_balance` (che dovrà corrispondere a `available_balance`).
3. TODO

#### Esecuzione

Nella directory `esercizio_0/` sono presenti:

- `DB/structure.sql` -> DDL - struttura DB (MariaDB) (`step 1`);
- `DB/control.sql` -> DCL - permessi utente (`step 1`);
- `import.pl` -> script Perl per l'importazione dei csv su DB (`step 1`);
- `process.pl` -> script Perl per il processamento dei movimenti sulla tabella `bank_movement` (`step 2`).
