#!/bin/bash
# Grunnleggende sikkerhetsoppsett

export DEBIAN_FRONTEND=noninteractive

# Oppdaterer systemet
sudo apt update && sudo apt upgrade -y

# Installerer UFW og aktiverer brannmur
sudo apt install ufw -y
sudo ufw default deny incoming
sudo ufw default allow outgoing
sudo ufw allow ssh
sudo ufw --force enable

# Deaktiverer root-innlogging via SSH
sudo sed -i 's/^PermitRootLogin.*/PermitRootLogin no/' /etc/ssh/sshd_config
sudo sed -i 's/^#PasswordAuthentication yes/PasswordAuthentication no/' /etc/ssh/sshd_config
sudo systemctl restart ssh

# Installerer automatiske sikkerhetsoppdateringer
sudo apt install unattended-upgrades -y
echo 'Unattended-Upgrade::Automatic-Reboot "true";' | sudo tee /etc/apt/apt.conf.d/51auto-reboot

echo "Sikkerhetsoppsett fullført. SSH er sikret, brannmur aktivert, og automatiske oppdateringer er konfigurert."
