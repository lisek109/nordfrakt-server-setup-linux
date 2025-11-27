#!/bin/bash
# disable_users.sh
# Deaktiverer brukere som ikke finnes i en eller flere CSV-filer

if [ "$#" -lt 1 ]; then
    echo "Bruk: $0 <CSV-fil1> [CSV-fil2] [CSV-fil3] ..."
    exit 1
fi

REMOTE_HOSTS=("server-harstad" "server-bodo")

echo "Starter deaktivering basert på CSV-filene: $@"

# Lag samlet liste over brukere fra alle CSV-filer
CSV_USERS=""
for FILE in "$@"; do
    if [ -f "$FILE" ]; then
        USERS=$(tail -n +2 "$FILE" | awk -F, '{print tolower($1)"."tolower($2)}' | tr -d ' ')
        CSV_USERS="$CSV_USERS $USERS"
    else
        echo "Advarsel: CSV-filen '$FILE' finnes ikke."
    fi
done

# --- LOKAL DEAKTIVERING ---
for USER in $(awk -F: '$3 >= 1000 {print $1}' /etc/passwd); do
    if ! echo "$CSV_USERS" | grep -qw "$USER"; then
        echo "Deaktiverer lokal bruker: $USER"
        sudo usermod -s /usr/sbin/nologin "$USER"
    fi
done

# --- FJERN DEAKTIVERING ---
for HOST in "${REMOTE_HOSTS[@]}"; do
    echo "Kontrollerer brukere på $HOST..."
    REMOTE_USERS=$(ssh -o BatchMode=yes "$HOST" "awk -F: '\$3 >= 1000 {print \$1}' /etc/passwd")
    for USER in $REMOTE_USERS; do
        if ! echo "$CSV_USERS" | grep -qw "$USER"; then
            echo "Deaktiverer $USER på $HOST"
            ssh -o BatchMode=yes "$HOST" "sudo usermod -s /usr/sbin/nologin $USER"
        fi
    done
done

echo "Deaktivering fullført."
