#!/bin/bash

# Sjekker om et argument (nytt vertsnavn) ble oppgitt
if [ -z "$1" ]; then
    echo "FEIL: Du må oppgi et nytt vertsnavn som argument."
    echo "Bruk: $0 nytt_vertsnavn"
    exit 1
fi

NYTT_VERTSNAVN="$1"

# Setter vertsnavnet ved hjelp av hostnamectl
echo "Setter vertsnavn til: $NYTT_VERTSNAVN"
sudo hostnamectl set-hostname "$NYTT_VERTSNAVN"

# Oppdaterer /etc/hosts med 127.0.1.1 <vertsnavn> hvis ikke allerede der
if ! grep -q "$NYTT_VERTSNAVN" /etc/hosts; then
    echo "Oppdaterer /etc/hosts..."
    echo "127.0.1.1 $NYTT_VERTSNAVN" | sudo tee -a /etc/hosts > /dev/null
fi

# Verifiserer endringen
echo "Aktuelt vertsnavn er:"
hostnamectl status | grep "Static hostname"

echo "Vertsnavnet er endret. Du må kanskje koble deg til SSH på nytt eller starte terminalen på nytt."

exit 0
