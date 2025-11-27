#!/bin/bash
# sync_shared_data.sh
# Synkroniserer felles kataloger fra Tromsø til andre lokasjoner

BASE_DIR="/srv/nordfrakt"
REMOTE_HOSTS=("server-harstad" "server-bodo")

for HOST in "${REMOTE_HOSTS[@]}"; do
    echo "Synkroniserer $BASE_DIR til $HOST..."
    sudo rsync -az --delete -e "ssh -o BatchMode=yes" "$BASE_DIR/" "$HOST:$BASE_DIR/"
    if [ $? -eq 0 ]; then
        echo " -> Synkronisering til $HOST fullført."
    else
        echo " -> Feil under synkronisering til $HOST"
    fi
done



