#!/bin/bash
# sync_users.sh
# Hovedskript for synkronisering av brukere og grupper på tvers av servere.


# --- KONFIGURASJON (KONFIGURACJA) ---
CSV_FILE="$1"

# Liste over fjernservere Bruk hostname eller IP.
REMOTE_HOSTS=("harstad_server" "bodo_server")
TEMP_PASSWORD="Velkommen2025!" # Midlertidig passord 

# Sjekk om CSV-filen eksisterer 
if [ -f "$CSV_FILE" ]; then
    tr -d '\r' < "$CSV_FILE" > /tmp/temp_clean.csv && mv /tmp/temp_clean.csv "$CSV_FILE"
else
    echo "Feil: CSV-filen '$CSV_FILE' ble ikke funnet. Kan ikke synkronisere."
    exit 1
fi

# Funksjon for å kjøre kommandoer på fjernservere via SSH
execute_remote() {
    local HOST=$1
    shift
    local COMMAND="$@"
    
    # Kjører kommandoen som root på fjernserveren 
    ssh -o BatchMode=yes -T "$HOST" "sudo $COMMAND"
    if [ $? -ne 0 ]; then
        echo "Advarsel: Feil under kjøring av kommando på $HOST."
    fi
}

# --- LOKAL FUNKSJON  ---

process_local_user() {
    # 1. RENSE VARIABLER (CZYSZCZENIE ZMIENNYCH)
    local CLEAN_FORNAVN=$(echo "$Fornavn" | tr -d '\r' | xargs)
    local CLEAN_ETTERNAVN=$(echo "$Etternavn" | tr -d '\r' | xargs)
    local BRUKERNAVN=$(echo "${CLEAN_FORNAVN,,}.${CLEAN_ETTERNAVN,,}" | tr -d ' ')
    
    local GRUPPE_RAW=$(echo "$Arbeidsomrade" | tr -d '\r')
    local GRUPPE=$(echo "$GRUPPE_RAW" | iconv -f utf8 -t ascii//TRANSLIT | tr '[:upper:]' '[:lower:]' | tr -d '/ ' )
    
    local FULLT_NAVN="$CLEAN_FORNAVN $CLEAN_ETTERNAVN"
    # Lagrer Fullt Navn, Telefon og Kontor i GECOS-feltet
   
    local GECOS_INFO="$FULLT_NAVN,$Telefon,$Kontor"

    echo "--- Behandler bruker: $BRUKERNAVN (Gruppe: $GRUPPE) ---"

    # 2. OPPRETT GRUPPE LOKALT (TWÓRZ GRUPĘ LOKALNIE)
    # Kontrollerer om gruppen eksisterer, ellers opprettes den
    
    if ! getent group "$GRUPPE" > /dev/null; then
        sudo groupadd "$GRUPPE"
        echo "Opprettet gruppe: $GRUPPE"
    fi

    # 3. OPPRETT / OPPDATER BRUKER LOKALT 
    if getent passwd "$BRUKERNAVN" > /dev/null; then
        # Bruker eksisterer - oppdater GECOS og gruppe
        
        sudo usermod -c "$GECOS_INFO" -g "$GRUPPE" -s /bin/bash "$BRUKERNAVN"
        echo "Oppdatert lokal bruker: $BRUKERNAVN"
    else
        # Bruker eksisterer ikke - opprett bruker
        
        sudo useradd -m -g "$GRUPPE" -c "$GECOS_INFO" -s /bin/bash "$BRUKERNAVN"
        
        if [ $? -eq 0 ]; then
            # Setter passord og tvinger bytte 
            echo "$BRUKERNAVN:$TEMP_PASSWORD" | sudo chpasswd
            sudo chage -d 0 "$BRUKERNAVN"
            echo "Opprettet lokal bruker: $BRUKERNAVN"
        fi
    fi

    # 4. HENT UID OG GID (POBIERZ UID I GID)
    local UID_VAL=$(id -u "$BRUKERNAVN")
    local GID_VAL=$(id -g "$BRUKERNAVN")
    local GRP_NAVN="$GRUPPE"

    # 5. SYNCRONISER TIL FJERN-SERVERE 
    for HOST in "${REMOTE_HOSTS[@]}"; do
        sync_remote_user "$HOST" "$BRUKERNAVN" "$UID_VAL" "$GID_VAL" "$GRP_NAVN" "$GECOS_INFO"
    done
}

# --- FJERN FUNKSJON  ---

sync_remote_user() {
    local HOST=$1
    local BRUKERNAVN=$2
    local UID_VAL=$3
    local GID_VAL=$4
    local GRP_NAVN=$5
    local GECOS_INFO=$6
    
    echo "  -> Synkroniserer $BRUKERNAVN til $HOST (UID:$UID_VAL GID:$GID_VAL)..."
    
    # 1. OPPRETT GRUPPE PÅ FJERN-SERVER 
    
    execute_remote "$HOST" "if ! getent group \"$GRP_NAVN\" > /dev/null; then groupadd -g \"$GID_VAL\" \"$GRP_NAVN\"; fi"

    # 2. OPPRETT / OPPDATER BRUKER PÅ FJERN-SERVER 
    if execute_remote "$HOST" "getent passwd \"$BRUKERNAVN\"" > /dev/null; then
        # Bruker eksisterer - oppdater GECOS og gruppe (
        execute_remote "$HOST" "usermod -c \"$GECOS_INFO\" -g \"$GRP_NAVN\" -s /bin/bash \"$BRUKERNAVN\""
    else
        # Bruker eksisterer ikke - opprett bruker 
        # Bruk samme UID og GID som lokalt for konsistens
        
        execute_remote "$HOST" "useradd -m -u \"$UID_VAL\" -g \"$GRP_NAVN\" -c \"$GECOS_INFO\" -s /bin/bash \"$BRUKERNAVN\""
    fi

    # 3. Passord settes kun på den lokale Tromsø-serveren. Passord-synkronisering over SSH er for komplisert og usikkert for Bash-skript.
    
    
    echo "  -> Synkronisering til $HOST fullført."
}


# --- HOVEDLØKKE  ---

echo "Starter sentralisert bruker-synkronisering..."

# Skanner CSV-filen og behandler hver bruker

tail -n +2 "$CSV_FILE" | while IFS=, read -r Fornavn Etternavn Fodselsdato Arbeidsomrade Telefon Kontor
do
    process_local_user
done

echo "Synkronisering fullført for alle brukere og servere. (Sletting av brukere krever separat logikk.)"