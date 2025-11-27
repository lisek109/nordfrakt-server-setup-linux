#!/bin/bash
# setup_apache.sh
# Installerer og konfigurerer Apache for Nordfrakt AS

# 1. Installerer Apache
sudo apt update
sudo apt install apache2 -y

# Legger til regler i UFW for å tillate HTTP (80) og HTTPS (443). 
# Dette er kritisk for å sikre at nettjenesten er tilgjengelig etter aktivering av brannmur.
sudo ufw allow 'Apache Full'

# 2. Oppretter katalog for nettsiden
sudo mkdir -p /var/www/nordfrakt
sudo chown -R www-data:www-data /var/www/nordfrakt
sudo chmod -R 755 /var/www/nordfrakt

# 3. Lager en enkel index.html
echo "<!DOCTYPE html>
<html>
<head><title>Nordfrakt AS</title></head>
<body>
<h1>Velkommen til Nordfrakt AS</h1>
<p>Nettsiden er under utvikling.</p>
</body>
</html>" | sudo tee /var/www/nordfrakt/index.html > /dev/null

# 4. Oppretter virtuell host
VHOST_CONF="/etc/apache2/sites-available/nordfrakt.conf"
sudo bash -c "cat > $VHOST_CONF" <<EOF
<VirtualHost *:80>
    ServerAdmin webmaster@nordfrakt.local
    DocumentRoot /var/www/nordfrakt
    ServerName nordfrakt.local

    <Directory /var/www/nordfrakt>
        Options Indexes FollowSymLinks
        AllowOverride None
        Require all granted
    </Directory>

    ErrorLog \${APACHE_LOG_DIR}/nordfrakt_error.log
    CustomLog \${APACHE_LOG_DIR}/nordfrakt_access.log combined
</VirtualHost>
EOF

# 5. Aktiverer vhost og Apache
sudo a2ensite nordfrakt.conf
sudo systemctl reload apache2

echo "Apache er installert og konfigurert for Nordfrakt AS."
