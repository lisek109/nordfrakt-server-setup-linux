# DRI106 – Linux Project

## Overview
This project establishes a professional Linux-based infrastructure for Nordfrakt AS.  
The solution combines local server operations at each branch office with centralized administration from Tromsø.  
It provides structure, security, and collaboration across the company’s three divisions, while also enabling a new website and centralized backup.

## Server Structure
- **Tromsø**: Main administration server, web server for the company website, and dedicated backup server.
- **Harstad**: Customer support, booking, and tracking server with shared and home directories for employees.
- **Bodø**: Terminal operations server for local distribution and returns handling.

All servers are configured with clear hostnames and static IP addresses to ensure stability and oversight.

## Key Features
- **Operating System**: Ubuntu Server LTS chosen for stability and long-term support.
- **Administration**: Remote management via SSH with key-based authentication.
- **Networking**: Static IPv4 configuration using Netplan, synchronized with NTP.
- **Security**:
  - Firewall rules with IPTables.
  - Only essential ports (SSH, HTTP/HTTPS) are open.
  - Root login via SSH disabled.
  - Automatic security updates enabled.
- **User and Group Management**:
  - Automated creation of users and groups via Bash scripts.
  - Home directories for each employee.
  - Shared directories per department and work area.
- **Web Server**:
  - Apache configured on Tromsø server to host the company website.
- **Backup**:
  - Dedicated backup server in Tromsø.
  - Automated nightly backups of home and shared directories using Bash scripts and cron jobs.
  - Backups stored with date-based naming and rotation for easy retrieval.

## Scripts (`/opt/nordfrakt_scripts`)
- `backup.sh` – Creates nightly compressed backups and transfers them to the backup server.
- `create_group.sh` – Automates creation of groups for departments and work areas.
- `create_home.sh` – Sets up home directories for employees.
- `disable_pass.yml` – Ansible playbook snippet to disable password authentication in SSH.
- `disable_users.sh` – Deactivates users not present in the central CSV file.
- `install_packages.sh` – Installs required packages (SSH, firewall, Apache, backup tools).
- `set_hostname.sh` – Configures consistent hostnames across servers.
- `setup_apache.sh` – Configures Apache web server and virtual host for Nordfrakt.
- `setup_motd.sh` – Customizes login message (MOTD) with hostname and IP.
- `setup_netplan.sh` – Applies static IP configuration using Netplan.
- `setup_security.sh` – Configures firewall, disables root login, enforces SSH key authentication.
- `setup_shared_dirs.sh` – Creates shared directories for departments and work areas.
- `sync_shared_data.sh` – Synchronizes shared data across servers.
- `sync_users.sh` – Synchronizes users and groups across servers based on CSV files.
- `verify_users.sh` – Verifies existence of users and groups.

## Playbooks (`/opt/nordfrakt_playbooks`)
- `deploy_config.yml` – Ansible playbook to deploy configuration across Harstad and Bodø servers, ensuring consistent setup of networking, packages, and security.

## Automation
Cron jobs ensure nightly automation:
- 01:00 – `sync_users.sh`
- 01:30 – `setup_shared_dirs.sh`
- 02:00 – `sync_shared_data.sh`
- 03:00 – `backup.sh`

Logs are stored in `/var/log/` for auditing and troubleshooting.

.
