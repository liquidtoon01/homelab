# Project Structure

This document describes the complete structure of the Kimsufi Infrastructure as Code repository.

## Directory Tree

```
kimsufi/
├── README.md                           # Main project documentation
├── GETTING_STARTED.md                  # Complete step-by-step setup guide
├── QUICKSTART.md                       # Quick start guide for immediate use
├── CHANGELOG.md                        # Version history and changes
├── REQUIREMENTS.md                     # System and software requirements
├── Makefile                            # Convenience commands for common tasks
├── .gitignore                          # Git ignore patterns
├── bootstrap.sh                        # Script to install Ansible on Ubuntu 22.04
├── ansible.cfg                         # Ansible configuration
│
├── inventory/                          # Ansible inventory files
│   └── hosts.yml                       # Host definitions and connection settings
│
├── group_vars/                         # Group variables
│   └── all.yml                         # Global variables for all hosts
│
├── playbooks/                          # Ansible playbooks
│   ├── site.yml                        # Main playbook (runs everything)
│   ├── infrastructure.yml              # Infrastructure components
│   └── applications.yml                # Helm applications deployment
│
├── roles/                              # Ansible roles
│   │
│   ├── base/                           # Base system configuration role
│   │   ├── meta/
│   │   │   └── main.yml                # Role dependencies
│   │   └── tasks/
│   │       └── main.yml                # Install Docker, common packages
│   │
│   ├── kubectl/                        # kubectl installation role
│   │   ├── defaults/
│   │   │   └── main.yml                # Default variables
│   │   ├── meta/
│   │   │   └── main.yml                # Role dependencies
│   │   └── tasks/
│   │       └── main.yml                # Download and install kubectl
│   │
│   ├── helm/                           # Helm installation role
│   │   ├── defaults/
│   │   │   └── main.yml                # Default variables
│   │   ├── meta/
│   │   │   └── main.yml                # Role dependencies
│   │   └── tasks/
│   │       └── main.yml                # Download and install Helm
│   │
│   ├── minikube/                       # Minikube installation and setup role
│   │   ├── defaults/
│   │   │   └── main.yml                # Default variables (CPUs, memory, etc.)
│   │   ├── meta/
│   │   │   └── main.yml                # Role dependencies
│   │   └── tasks/
│   │       └── main.yml                # Install and start Minikube
│   │
│   ├── tailscale/                      # Tailscale VPN installation role
│   │   ├── defaults/
│   │   │   └── main.yml                # Default variables (auth key)
│   │   ├── meta/
│   │   │   └── main.yml                # Role dependencies
│   │   └── tasks/
│   │       └── main.yml                # Install and configure Tailscale
│   │
│   ├── apt_updates/                    # Scheduled system updates role
│   │   ├── defaults/
│   │   │   └── main.yml                # Default variables (schedule)
│   │   ├── meta/
│   │   │   └── main.yml                # Role dependencies
│   │   ├── tasks/
│   │   │   └── main.yml                # Configure unattended-upgrades
│   │   └── templates/
│   │       ├── 20auto-upgrades.j2      # Auto-upgrade configuration
│   │       └── 50unattended-upgrades.j2 # Unattended-upgrades configuration
│   │
│   └── helm_apps/                      # Helm applications deployment role
│       ├── defaults/
│       │   └── main.yml                # Default variables (namespaces, configs)
│       ├── meta/
│       │   └── main.yml                # Role dependencies
│       └── tasks/
│           ├── main.yml                # Main task file (orchestrates deployment)
│           ├── tailscale-operator.yml  # Deploy Tailscale operator
│           ├── storage.yml             # Install local-path-provisioner
│           ├── gitea.yml               # Deploy Gogs
│           ├── sonarr.yml              # Deploy Sonarr
│           ├── headscale.yml           # Deploy Headscale
│           ├── qbittorrent.yml         # Deploy qBittorrent
│           └── pihole.yml              # Deploy Pi-hole
│
└── docs/                               # Documentation
    ├── bootstrap.md                    # Bootstrap guide
    ├── ssh-security.md                 # SSH security and hardening guide
    ├── infrastructure.md               # Infrastructure components details
    ├── tailscale-operator.md           # Tailscale operator setup and configuration
    ├── applications.md                 # Applications guide
    └── troubleshooting.md              # Troubleshooting guide
```

## File Descriptions

### Root Directory Files

- **README.md**: Main project documentation with overview, quick start, and project structure
- **GETTING_STARTED.md**: Complete step-by-step guide from cloning to deployment
- **QUICKSTART.md**: Condensed quick reference for getting started immediately
- **CHANGELOG.md**: Version history and planned future enhancements
- **REQUIREMENTS.md**: Detailed system and software requirements
- **Makefile**: Common commands wrapped for convenience (`make install`, `make status`, etc.)
- **.gitignore**: Patterns for files to exclude from version control
- **bootstrap.sh**: Shell script to install Ansible on a fresh Ubuntu 24.04 system
  - Installs Git (for repository cloning)
  - Installs snapd and msedit text editor
  - Installs Ansible from PPA
  - Configures SSH security hardening
  - Creates backup of SSH configuration

### Configuration Directories

#### inventory/
Contains inventory files that define which hosts Ansible will manage.

- **hosts.yml**: Defines the target host(s) and connection parameters
  - Configure for local or remote deployment
  - Set SSH connection details
  - Group hosts into categories (e.g., kubernetes)

#### group_vars/
Variables that apply to groups of hosts defined in the inventory.

- **all.yml**: Variables for all hosts
  - Minikube settings (CPU, memory, disk)
  - Tailscale auth key
  - Application namespaces
  - Storage class configuration
  - Default passwords (should be changed!)

### Playbooks

#### playbooks/
The main orchestration files that define what tasks to run.

- **site.yml**: Master playbook that runs everything
  - Imports infrastructure.yml
  - Imports applications.yml
  - Use this for complete installation

- **infrastructure.yml**: Infrastructure-only playbook
  - Base system packages
  - Scheduled updates
  - kubectl
  - Helm
  - Minikube
  - Tailscale

- **applications.yml**: Applications-only playbook
  - Requires infrastructure to be installed first
  - Deploys all Helm applications

### Roles

#### roles/base/
Foundation role that installs common dependencies.

**Tasks:**
- Update apt cache
- Install Docker and Docker Compose
- Install common packages (curl, git, wget, etc.)
- Start and enable Docker service
- Add user to docker group

#### roles/kubectl/
Installs the Kubernetes command-line tool.

**Tasks:**
- Get latest stable kubectl version
- Download kubectl binary
- Install to `/usr/local/bin/kubectl`
- Verify installation

#### roles/helm/
Installs the Kubernetes package manager.

**Tasks:**
- Get latest Helm version
- Download and extract Helm
- Install to `/usr/local/bin/helm`
- Add common Helm repositories
- Update repositories

#### roles/minikube/
Installs and configures Minikube.

**Tasks:**
- Get latest Minikube version
- Download Minikube binary
- Start Minikube cluster with Docker driver
- Configure resources (CPU, memory, disk)
- Enable addons (storage-provisioner, metrics-server)
- Wait for cluster to be ready

**Default Configuration:**
- Driver: docker
- CPUs: 2
- Memory: 4GB
- Disk: 20GB

#### roles/tailscale/
Installs and configures Tailscale VPN.

**Tasks:**
- Add Tailscale GPG key and repository
- Install Tailscale package
- Start and enable service
- Connect to network (if auth key provided)
- Display connection status

#### roles/apt_updates/
Configures automatic system updates.

**Tasks:**
- Install unattended-upgrades
- Configure update settings
- Create update script
- Schedule weekly updates via cron

**Templates:**
- `50unattended-upgrades.j2`: Main configuration
- `20auto-upgrades.j2`: Auto-update settings

**Default Schedule:** Sundays at 3 AM

#### roles/helm_apps/
Deploys all Helm-based applications.

**Main Tasks:**
- Add Helm repositories for all applications
- Update repositories
- Install storage provisioner
- Deploy each application

**Application Tasks:**
- `storage.yml`: Rancher local-path-provisioner (CSI driver)
- `gogs.yml`: Self-hosted Git service (Gogs)
- `sonarr.yml`: TV show PVR
- `headscale.yml`: Self-hosted Tailscale control server
- `qbittorrent.yml`: BitTorrent client
- `pihole.yml`: Network-wide ad blocker and DNS server

Each application task:
1. Creates namespace
2. Generates values file with configuration
3. Deploys via Helm
4. Waits for deployment to complete

### Documentation

#### docs/
Comprehensive documentation for users.

- **bootstrap.md**: Step-by-step bootstrap guide
  - Prerequisites
  - Installation steps
  - Configuration
  - Verification
  - Security recommendations

- **ssh-security.md**: SSH security and hardening guide
  - SSH hardening applied by bootstrap
  - Setting up SSH keys
  - Enabling maximum security
  - Additional security measures
  - Monitoring SSH access
  - Troubleshooting SSH issues

- **infrastructure.md**: Infrastructure components documentation
  - Details on each component
  - Configuration options
  - Management commands
  - Verification steps
  - Network access

- **applications.md**: Applications guide
  - Overview of each application
  - Access instructions
  - Default credentials
  - Configuration
  - Integration setup
  - Backup procedures
  - Common operations

- **troubleshooting.md**: Troubleshooting guide
  - Common issues and solutions
  - Debugging commands
  - Complete reset procedure
  - Getting help resources

## Usage Patterns

### Initial Setup
```bash
bootstrap.sh → infrastructure.yml → applications.yml
```

### Selective Installation
```bash
# Install only infrastructure
ansible-playbook -i inventory/hosts.yml playbooks/infrastructure.yml

# Install only specific role
ansible-playbook -i inventory/hosts.yml playbooks/infrastructure.yml --tags kubectl

# Install only applications
ansible-playbook -i inventory/hosts.yml playbooks/applications.yml
```

### Using Makefile
```bash
make bootstrap        # Install Ansible
make install          # Install everything
make status           # Check status
make services         # List service URLs
```

## Customization Points

### Variables to Customize

**group_vars/all.yml:**
- `minikube_cpus`: Adjust based on server capacity
- `minikube_memory`: Increase for better performance
- `tailscale_auth_key`: Your Tailscale auth key
- Application namespaces: Organize as needed

### Inventory Customization

**inventory/hosts.yml:**
- Change from `localhost` to remote IP
- Add more hosts
- Create host groups
- Set per-host variables

### Role Customization

Modify role defaults in `roles/<role>/defaults/main.yml`:
- Software versions
- Installation paths
- Configuration options

## Best Practices

1. **Version Control**: Commit all changes to git
2. **Sensitive Data**: Use Ansible Vault for secrets
3. **Testing**: Test changes on a non-production system
4. **Backups**: Backup before major changes
5. **Documentation**: Document any customizations
6. **Tags**: Use tags for selective execution
7. **Idempotency**: Playbooks can be run multiple times safely

## Extending the Infrastructure

### Adding a New Application

1. Create new task file in `roles/helm_apps/tasks/`
2. Add Helm repository in `roles/helm_apps/tasks/main.yml`
3. Include new task file in `main.yml`
4. Add configuration variables to `roles/helm_apps/defaults/main.yml`
5. Document in `docs/applications.md`

### Adding a New Infrastructure Component

1. Create new role in `roles/`
2. Add to `playbooks/infrastructure.yml`
3. Add dependencies in role's `meta/main.yml`
4. Document in `docs/infrastructure.md`

### Creating Custom Playbooks

1. Create playbook in `playbooks/`
2. Import required roles
3. Add to `site.yml` if needed
4. Document usage in README.md

## Security Considerations

- Change default passwords in `group_vars/all.yml`
- Use Ansible Vault for sensitive variables
- Restrict file permissions on SSH keys
- Regularly update components
- Monitor logs for suspicious activity
- Use Tailscale for secure remote access
- Don't commit secrets to version control
