#!/bin/bash
# Oppretter en ny gruppe

if [ -z "$1" ]; then
    echo "FEIL: Du må oppgi et gruppenavn som argument."
    echo "Bruk: $0 gruppenavn"
    exit 1
fi

GRUPPE="$1"

sudo groupadd "$GRUPPE"
echo "Gruppe $GRUPPE er opprettet."
exit 0
