#!/bin/bash
# setup_motd.sh
# Oppretter et eget MOTD-skript for Nordfrakt AS

MOTD_SCRIPT="/etc/update-motd.d/99-nordfrakt"

sudo bash -c "cat > $MOTD_SCRIPT" <<'EOF'
#!/bin/bash
# Viser Nordfrakt-spesifikk informasjon ved innlogging

echo "--------------------------------------------"
echo " Velkommen til Nordfrakt AS - $(hostname) "
echo " Hostname: $(hostname)"
echo " IP-adresse: $(hostname -I | awk '{print $1}')"
echo " Kun autoriserte brukere har tilgang."
echo "--------------------------------------------"
EOF

# Gjør skriptet kjørbart
sudo chmod +x $MOTD_SCRIPT

echo "Tilpasset MOTD er opprettet i $MOTD_SCRIPT"