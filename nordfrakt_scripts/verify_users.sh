#!/bin/bash
# Sjekker om brukere fra CSV-filen eksisterer i systemet.

CSV_FILE="nordfrakt_tromso.csv"

echo "Verifiserer status for brukere fra $CSV_FILE:"

tail -n +2 "$CSV_FILE" | while IFS=, read -r Fornavn Etternavn Fodselsdato Arbeidsomrade Telefon Kontor
do
    # Samme logikk for å generere brukernavn som i create_basic_user.sh
    BRUKERNAVN=$(echo "${Fornavn,,}.${Etternavn,,}" | tr -d ' ')

    # Skjekk om brukeren eksisterer
    if id "$BRUKERNAVN" &>/dev/null; then
        echo "Bruker $BRUKERNAVN EKSISTERER fortsatt."
    else
        echo "Bruker $BRUKERNAVN ble vellykket fjernet/eksisterer ikke."
    fi
done

echo "Verifisering fullført."