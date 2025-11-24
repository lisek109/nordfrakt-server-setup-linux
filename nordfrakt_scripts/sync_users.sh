#!/bin/bash
# sync_users.sh
# Sentralisert synkronisering av brukere og grupper på tvers av servere.
# Kjøring: sudo ./sync_users.sh /opt/nordfrakt_data/nordfrakt_tromso.csv
# Forutsetning: SSH-nøkler fra Tromsø til Harstad/Bodø og sudo uten passord for it_admin.

set -euo pipefail

# --- KONFIGURASJON ---
CSV_FILE="${1:-}"
REMOTE_HOSTS=("server-harstad" "server-bodo")  # Oppdater til faktiske hostnames/IP
TEMP_PASSWORD="Velkommen2025!"                 # Midlertidig passord ved første innlogging
PRIMARY_GROUP_MAP=("ledelse" "itlogistikk" "okonomi" "ruteplanlegging" "it_admin")
LOG_FILE="/var/log/nordfrakt_sync_users.log"

# --- HJELPEFUNKSJONER ---
log() { echo "[$(date +'%Y-%m-%d %H:%M:%S')] $*" | tee -a "$LOG_FILE"; }

die() { log "FEIL: $*"; exit 1; }

# Kjør kommando på fjernserver (forvent at sudo ikke krever passord for it_admin)
execute_remote() {
  local HOST=$1; shift
  local COMMAND="$*"
  if ! ssh -o BatchMode=yes -o StrictHostKeyChecking=accept-new -T "$HOST" "sudo bash -lc '$COMMAND'"; then
    log "Advarsel: Feil under kjøring på $HOST: $COMMAND"
    return 1
  fi
}

# Normaliser arbeidsområde til gruppenavn (ASCII, små bokstaver, ingen mellomrom)
normalize_group() {
  local RAW="$1"
  echo "$RAW" | iconv -f utf8 -t ascii//TRANSLIT | tr '[:upper:]' '[:lower:]' | tr -d ' /'
}

# --- VALIDERING AV INNGANG ---
[[ -n "$CSV_FILE" ]] || die "Mangler CSV-fil som argument."
[[ -f "$CSV_FILE" ]] || die "CSV-filen '$CSV_FILE' finnes ikke."

# Fjern eventuelle CRLF fra Windows
tr -d '\r' < "$CSV_FILE" > /tmp/nordfrakt_clean.csv && mv /tmp/nordfrakt_clean.csv "$CSV_FILE"

log "Starter sentralisert bruker-synkronisering basert på $CSV_FILE"

# Samle ønsket tilstand fra CSV (brukernavn-liste) for senere deaktivering
declare -A CSV_USERS=()

# --- HOVEDLØKKE OVER CSV ---
tail -n +2 "$CSV_FILE" | while IFS=, read -r Fornavn Etternavn Fodselsdato Arbeidsomrade Telefon Kontor; do
  # Rens og bygg brukernavn
  CLEAN_FORNAVN=$(echo "$Fornavn" | xargs)
  CLEAN_ETTERNAVN=$(echo "$Etternavn" | xargs)
  BRUKERNAVN=$(echo "${CLEAN_FORNAVN,,}.${CLEAN_ETTERNAVN,,}" | tr -d ' ')
  GRUPPE=$(normalize_group "$Arbeidsomrade")
  FULLT_NAVN="$CLEAN_FORNAVN $CLEAN_ETTERNAVN"
  GECOS_INFO="$FULLT_NAVN,$Telefon,$Kontor"

  CSV_USERS["$BRUKERNAVN"]=1
  log "--- Behandler $BRUKERNAVN (gruppe: $GRUPPE) ---"

  # Opprett gruppe lokalt hvis den mangler
  if ! getent group "$GRUPPE" >/dev/null; then
    groupadd "$GRUPPE"
    log "Opprettet lokal gruppe: $GRUPPE"
  fi

  # Opprett/oppdater bruker lokalt
  if getent passwd "$BRUKERNAVN" >/dev/null; then
    usermod -c "$GECOS_INFO" -g "$GRUPPE" -s /bin/bash "$BRUKERNAVN"
    log "Oppdatert lokal bruker: $BRUKERNAVN"
  else
    useradd -m -g "$GRUPPE" -c "$GECOS_INFO" -s /bin/bash "$BRUKERNAVN"
    echo "$BRUKERNAVN:$TEMP_PASSWORD" | chpasswd
    chage -d 0 "$BRUKERNAVN"  # Tvinger passordbytte ved første innlogging (kun lokalt)
    log "Opprettet lokal bruker: $BRUKERNAVN"
  fi

  UID_VAL=$(id -u "$BRUKERNAVN")
  GID_VAL=$(getent group "$GRUPPE" | cut -d: -f3)

  # Synkroniser bruker og gruppe til fjernservere
  # for HOST in "${REMOTE_HOSTS[@]}"; do
  #   log "-> Synkroniserer $BRUKERNAVN til $HOST (UID:$UID_VAL GID:$GID_VAL)"
  #   execute_remote "$HOST" "getent group '$GRUPPE' >/dev/null || groupadd -g '$GID_VAL' '$GRUPPE'"
  #   if execute_remote "$HOST" "getent passwd '$BRUKERNAVN'"; then
  #     execute_remote "$HOST" "usermod -c '$GECOS_INFO' -g '$GRUPPE' -s /bin/bash '$BRUKERNAVN'"
  #   else
  #     execute_remote "$HOST" "useradd -m -u '$UID_VAL' -g '$GRUPPE' -c '$GECOS_INFO' -s /bin/bash '$BRUKERNAVN'"
  #   fi
  #   # Passord synkroniseres ikke over nettverket av sikkerhetshensyn – lokal første-innlogging på Tromsø håndterer det.
  #   log "-> Ferdig synk for $BRUKERNAVN på $HOST"
  # done
done

# --- DEAKTIVERING AV BRUKERE SOM IKKE LENGER STÅR I CSV ---
log "Kontrollerer brukere for deaktivering (ikke i CSV)"
for USER in $(awk -F: '{if ($3>=1000 && $1!="nobody") print $1}' /etc/passwd); do
  # Hopp over it_admin-brukere og systemkonti
  if id "$USER" >/dev/null 2>&1 && id -nG "$USER" | grep -qw it_admin; then
    continue
  fi
  if [[ -z "${CSV_USERS[$USER]:-}" ]]; then
    # Deaktiver lokalt
    usermod --expiredate 1 "$USER"
    log "Deaktivert lokal bruker: $USER (mangler i CSV)"
    # Deaktiver på fjernservere
    for HOST in "${REMOTE_HOSTS[@]}"; do
      execute_remote "$HOST" "id '$USER' >/dev/null 2>&1 && usermod --expiredate 1 '$USER' && echo 'Deaktivert $USER på $HOST'"
    done
  fi
done

log "Synkronisering fullført."
