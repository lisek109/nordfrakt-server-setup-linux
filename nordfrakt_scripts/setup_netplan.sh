#!/bin/bash
# Setter opp statisk IP-adresse med Netplan (oppdatert med korrekt YAML og filrettigheter)

if [ "$#" -ne 3 ]; then
    echo "Bruk: $0 <IP-adresse/24> <gateway> <DNS>"
    exit 1
fi

IP="$1"
GATEWAY="$2"
DNS="$3"
NETPLAN_FILE="/etc/netplan/01-netcfg.yaml"
INTERFACE="enp0s3"  # Endre hvis nødvendig (bruk 'ip a' for å finne riktig navn)

sudo bash -c "cat > $NETPLAN_FILE" <<EOL
network:
  version: 2
  renderer: networkd
  ethernets:
    $INTERFACE:
      dhcp4: no
      addresses:
        - $IP
      routes:
        - to: 0.0.0.0/0
          via: $GATEWAY
      nameservers:
        addresses: [$DNS]
EOL

# Sikre filrettigheter
sudo chmod 600 "$NETPLAN_FILE"

echo "Statisk IP er konfigurert til $IP med gateway $GATEWAY og DNS $DNS."
echo "Bruk 'sudo netplan apply' for å aktivere endringen."
exit 0
