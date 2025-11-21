#!/bin/bash

CSV_FILE="nordfrakt_tromso.csv"

# Wymuś usunięcie znaku powrotu karetki, aby uniknąć błędów
tr -d '\r' < "$CSV_FILE" > temp_clean.csv && mv temp_clean.csv "$CSV_FILE"

echo "Rozpoczęto usuwanie użytkowników z $CSV_FILE..."

tail -n +2 "$CSV_FILE" | while IFS=, read -r Fornavn Etternavn Fodselsdato Arbeidsomrade Telefon Kontor
do
    # Użyj tej samej logiki do generowania nazwy użytkownika
    BRUKERNAVN=$(echo "${Fornavn,,}.${Etternavn,,}" | tr -d ' ')

    # Usuń użytkownika wraz z katalogiem domowym (-r)
    sudo deluser --remove-home "$BRUKERNAVN"
    
    if [ $? -eq 0 ]; then
        echo "Usunięto użytkownika: $BRUKERNAVN"
    else
        # To się zdarzy, jeśli użytkownik nigdy nie został utworzony lub już nie istnieje
        echo "Ostrzeżenie: Nie można usunąć $BRUKERNAVN (prawdopodobnie nie istnieje lub jest w użyciu)."
    fi

done

echo "Zakończono proces usuwania użytkowników."