#!/bin/bash
# setup_shared_dirs.sh
# Oppretter felles kataloger for grupper fra CSV-filene

BASE_DIR="/srv/nordfrakt"
CSV_FILES=/opt/nordfrakt_data/*.csv

# Opprett hovedkatalog hvis den ikke finnes
if [ ! -d "$BASE_DIR" ]; then
    sudo mkdir -p "$BASE_DIR"
    sudo groupadd -f nordfrakt
    sudo chown :nordfrakt "$BASE_DIR"
    sudo chmod 2770 "$BASE_DIR"
    echo "Opprettet hovedkatalog $BASE_DIR med gruppe nordfrakt"
fi

# Hent grupper fra CSV og opprett kataloger
for FILE in $CSV_FILES; do
    if [ -f "$FILE" ]; then
        tr -d '\r' < "$FILE" | tail -n +2 | while IFS=, read -r Fornavn Etternavn Fodselsdato Arbeidsomrade Telefon Kontor
        do
            GRP=$(echo "$Arbeidsomrade" | tr '[:upper:]' '[:lower:]' | tr -d ' ')
            if getent group "$GRP" > /dev/null; then
                if [ ! -d "$BASE_DIR/$GRP" ]; then
                    sudo mkdir -p "$BASE_DIR/$GRP"
                    sudo chown :"$GRP" "$BASE_DIR/$GRP"
                    sudo chmod 2770 "$BASE_DIR/$GRP"
                    echo "Opprettet felles katalog for $GRP"
                fi
            fi
        done
    fi
done



