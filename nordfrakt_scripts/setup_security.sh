#!/bin/bash
# Grunnleggende sikkerhetsoppsett for server-tromso

# Oppdaterer systemet
sudo apt update && sudo apt upgrade -y

# Installerer UFW og aktiverer brannmur
sudo apt install ufw -y
sudo ufw default deny incoming
sudo ufw default allow outgoing
sudo ufw allow ssh
sudo ufw enable

# Deaktiverer root-innlogging via SSH
sudo sed -i 's/^PermitRootLogin.*/PermitRootLogin no/' /etc/ssh/sshd_config
sudo sed -i 's/^#PasswordAuthentication yes/PasswordAuthentication no/' /etc/ssh/sshd_config
sudo systemctl restart ssh

# Installerer automatiske sikkerhetsoppdateringer
sudo apt install unattended-upgrades -y
sudo dpkg-reconfigure --priority=low unattended-upgrades

echo "Sikkerhetsoppsett fullført. SSH er sikret, brannmur aktivert, og automatiske oppdateringer er konfigurert."

