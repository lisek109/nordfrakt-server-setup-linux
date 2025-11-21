#!/bin/bash
# Oppretter hjemmeområde for en bruker og setter riktig eierskap

if [ -z "$1" ]; then
    echo "FEIL: Du må oppgi et brukernavn som argument."
    echo "Bruk: $0 brukernavn"
    exit 1
fi

BRUKER="$1"
HOMEDIR="/home/$BRUKER"

sudo mkdir -p "$HOMEDIR"
sudo chown "$BRUKER:$BRUKER" "$HOMEDIR"
sudo chmod 700 "$HOMEDIR"

echo "✅ Hjemmeområde $HOMEDIR opprettet for bruker $BRUKER."
exit 0
