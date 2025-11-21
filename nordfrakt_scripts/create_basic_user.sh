#!/bin/bash
# Oppretter brukere fra CSV som vanlige brukere

# Tar første argument ($1) som filnavn for CSV
# Hvis ingen filnavn er oppgitt, stopper skriptet
if [ -z "$1" ]; then
    echo "Feil: Vennligst oppgi CSV-filnavn som argument."
    echo "Bruk: $0 <filnavn.csv>"
    exit 1
fi

CSV_FILE="$1"
TEMP_PASSWORD="Velkommen2025!" # Midlertidig passord

# Sjekk om filen eksisterer
if [ ! -f "$CSV_FILE" ]; then
    echo "Feil: Filen '$CSV_FILE' ble ikke funnet."
    exit 1
fi

tail -n +2 "$CSV_FILE" | while IFS=, read -r Fornavn Etternavn Fodselsdato Arbeidsomrade Telefon Kontor
do
    CLEAN_FORNAVN=$(echo "$Fornavn" | tr -d '\r' | xargs)
    CLEAN_ETTERNAVN=$(echo "$Etternavn" | tr -d '\r' | xargs)
    BRUKERNAVN=$(echo "${CLEAN_FORNAVN,,}.${CLEAN_ETTERNAVN,,}" | tr -d ' ')
    GRUPPE_RAW=$(echo "$Arbeidsomrade" | tr -d '\r')
    GRUPPE=$(echo "$GRUPPE_RAW" | iconv -f utf8 -t ascii//TRANSLIT | tr '[:upper:]' '[:lower:]' | tr -d '/ ' )

    echo "DEBUG: BRUKERNAVN='$BRUKERNAVN', GRUPPE='$GRUPPE'"

    FULLT_NAVN="$Fornavn $Etternavn"

    # opprett bruker med hjemmekatalog og legg til i gruppe
    sudo useradd -m -g "$GRUPPE" -c "$FULLT_NAVN" -s /bin/bash "$BRUKERNAVN"
    
    # Sjekk om useradd var vellykket (exit code 0)
    if [ $? -eq 0 ]; then
        # 2. Sett midlertidig passord via chpasswd
        echo "$BRUKERNAVN:$TEMP_PASSWORD" | sudo chpasswd
        
        # 3. Tving passordbytte ved første innlogging
        sudo chage -d 0 "$BRUKERNAVN"

       
            
        # Kopier standard konfigurasjonsfiler
        sudo cp /etc/skel/.bashrc /home/"$BRUKERNAVN"/
        sudo cp /etc/skel/.profile /home/"$BRUKERNAVN"/
            
        # Sett riktig eierskap og gruppe
        sudo chown "$BRUKERNAVN":"$GRUPPE" /home/"$BRUKERNAVN"/.bashrc
        sudo chown "$BRUKERNAVN":"$GRUPPE" /home/"$BRUKERNAVN"/.profile

        # Legger til linje for å tvinge lasting av .bashrc (Dodaje linię, aby wymusić ładowanie .bashrc)
        echo "if [ -f ~/.bashrc ]; then . ~/.bashrc; fi" | sudo tee -a /home/"$BRUKERNAVN"/.profile > /dev/null
        
        
        echo "Opprettet bruker $BRUKERNAVN i gruppe $GRUPPE. Midlertidig passord: $TEMP_PASSWORD. Må bytte passord ved første innlogging."
    else
        echo "Feil: Kunne ikke opprette bruker $BRUKERNAVN. Sjekk om gruppen '$GRUPPE' eksisterer."
    fi
done