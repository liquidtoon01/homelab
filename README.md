# Kimsufi Infrastructure as Code

This repository contains Ansible playbooks and roles to provision a complete Kubernetes-based infrastructure on a bare-metal Ubuntu 24.04 server.

## Overview

This setup installs and configures:
- **Minikube** - Local Kubernetes cluster
- **kubectl** - Kubernetes CLI
- **Helm** - Kubernetes package manager
- **Tailscale** - VPN mesh network
- **Tailscale Operator** - Kubernetes operator for Tailscale ingress
- **Scheduled apt updates** - Automated system updates

And deploys the following applications via Helm:
- **Gogs** - Self-hosted Git service (accessible via Tailscale at `http://gogs`)
- **Sonarr** - PVR for TV shows (accessible via Tailscale at `http://sonarr`)
- **qBittorrent** - BitTorrent client (accessible via Tailscale at `http://qbittorrent`)
- **Pi-hole** - Network-wide ad blocker and DNS server (accessible via Tailscale at `http://pihole`)

## Quick Start

### 1. Clone the Repository

On your fresh Ubuntu 24.04 instance:

```bash
# Install git if not already present
sudo apt-get update && sudo apt-get install -y git

# Clone this repository
git clone https://github.com/YOUR_USERNAME/kimsufi.git
cd kimsufi
```

### 2. Bootstrap Ansible

Run the bootstrap script:

```bash
sudo bash bootstrap.sh
```

This will install Git, snapd, msedit, Ansible, and configure SSH security hardening.

### 3. Configure Inventory

Edit `inventory/hosts.yml` to specify your target host(s).

### 4. Run the Main Playbook

Install all infrastructure components:

```bash
ansible-playbook -i inventory/hosts.yml playbooks/site.yml
```

Or run specific playbooks:

```bash
# Install only infrastructure components
ansible-playbook -i inventory/hosts.yml playbooks/infrastructure.yml

# Deploy only Helm applications
ansible-playbook -i inventory/hosts.yml playbooks/applications.yml
```

## Project Structure

```
.
├── bootstrap.sh              # Ansible installation script
├── ansible.cfg               # Ansible configuration
├── inventory/
│   └── hosts.yml             # Inventory file
├── group_vars/
│   └── all.yml               # Global variables
├── playbooks/
│   ├── site.yml              # Main playbook (runs everything)
│   ├── infrastructure.yml    # Infrastructure setup playbook
│   └── applications.yml      # Helm applications playbook
├── roles/
│   ├── base/                 # Base system configuration
│   ├── minikube/             # Minikube installation
│   ├── kubectl/              # kubectl installation
│   ├── helm/                 # Helm installation
│   ├── tailscale/            # Tailscale installation
│   ├── apt_updates/          # Scheduled apt updates
│   └── helm_apps/            # Helm applications deployment
└── docs/                     # Documentation
```

## Documentation

- [Getting Started Guide](GETTING_STARTED.md) - Setup and reference guide
- [Bootstrap Guide](docs/bootstrap.md)
- [SSH Security Guide](docs/ssh-security.md)
- [Infrastructure Components](docs/infrastructure.md)
- [Tailscale Operator Setup](docs/tailscale-operator.md) - Configure Tailscale ingress
- [Applications](docs/applications.md)
- [Troubleshooting](docs/troubleshooting.md)

## Requirements

- Ubuntu 24.04 LTS
- Root or sudo access
- Internet connection
- Minimum 4GB RAM
- Minimum 20GB disk space

## License

MIT
