# Tech Stack Analysis

## Core Technology Analysis

### Programming Language(s)
- **Primary**: YAML (Ansible playbooks, roles, and configuration)
- **Secondary**: Bash (bootstrap scripts and automation)
- **Tertiary**: Jinja2 templating (for Ansible template files)

### Primary Framework
- **Ansible** - Infrastructure as Code (IaC) automation platform
  - Version: Latest (from PPA repository)
  - Used for provisioning, configuration management, and application deployment

### Secondary Frameworks
- **Kubernetes** (via Minikube)
  - Local single-node Kubernetes cluster
  - Version: Latest stable
  - Driver: Docker
  - Resource allocation: 2 CPUs, 4GB memory, 20GB disk
  
- **Helm** - Kubernetes package manager
  - Version: Latest stable
  - Used for deploying and managing applications on Kubernetes

- **kubectl** - Kubernetes command-line tool
  - Version: Latest stable
  - Used for Kubernetes cluster operations

### State Management Approach
- **Declarative Infrastructure**: All infrastructure and application state defined via Ansible roles and playbooks
- **Idempotent Operations**: Ansible ensures consistent state across runs
- **Inventory Management**: Host and group variables define configuration state
- **Ansible Vault**: Encrypted credential management for sensitive values (Tailscale auth keys, OAuth secrets)

### Other Relevant Technologies
- **Tailscale**: Zero-config VPN mesh network
  - Used for secure ingress to services
  - Tailscale Operator deployed in Kubernetes
  - OAuth-based authentication for operator
  
- **Docker**: Container runtime for Minikube
  
- **Make**: Task automation and CLI wrapper
  
- **Storage Provisioner**: Kubernetes persistent volume management
  
- **Deployed Applications**:
  - Gogs (self-hosted Git service)
  - Sonarr (TV show PVR)
  - qBittorrent (BitTorrent client)
  - Jackett (torrent indexer proxy)
  - Crontab UI (web-based cron manager)
  - Pi-hole (network-wide ad blocker and DNS)

## Domain Specificity Analysis

### Problem Domain
This is a **homelab infrastructure automation and self-hosted application platform**. The project provides:
- Automated provisioning of a complete Kubernetes-based homelab environment
- Self-hosted media management and download infrastructure
- Private development tools (Git hosting)
- Network-wide ad blocking and DNS management
- VPN-based secure access to all services
- Bare-metal server configuration and hardening

### Core Concepts
1. **Infrastructure as Code**: All infrastructure components defined as code
2. **Declarative Configuration**: Desired state specified, Ansible ensures compliance
3. **Role-Based Architecture**: Modular roles for each component
4. **Idempotency**: Safe to run playbooks multiple times
5. **Separation of Concerns**: Infrastructure vs. application deployment layers
6. **Security Hardening**: SSH configuration, automated updates, VPN access
7. **Persistent Storage**: StatefulSets with persistent volumes for stateful applications
8. **Service Discovery**: Kubernetes DNS and Tailscale hostname-based routing

### User Interactions
- **Command-Line Operations**: Via Makefile targets and ansible-playbook commands
- **Service Access**: Via Tailscale DNS names (http://servicename)
- **Configuration**: Via YAML variables in group_vars and inventory files
- **Secrets Management**: Via Ansible Vault for sensitive credentials
- **Monitoring**: Via kubectl, minikube commands, and Make targets for status checks

### Primary Data Types and Structures
- **Ansible Inventory**: YAML-based host and group definitions
- **Playbooks**: YAML workflow definitions orchestrating roles
- **Roles**: Structured directories with tasks, defaults, templates, and meta
- **Variables**: YAML-based configuration in group_vars/all.yml and vault.yml
- **Kubernetes Manifests**: YAML resource definitions (Services, Deployments, StatefulSets, ConfigMaps)
- **Helm Values**: YAML configuration for Helm chart customization
- **Jinja2 Templates**: Template files for system configuration (e.g., unattended-upgrades)

## Application Boundaries

### Features/Functionality Within Scope
1. **Infrastructure Provisioning**:
   - Minikube cluster setup and configuration
   - kubectl and Helm installation
   - Tailscale VPN setup on host and in Kubernetes
   - Base system configuration and hardening
   - Automated apt updates and security patches

2. **Application Deployment**:
   - Helm-based application installation
   - Namespace management
   - Persistent volume provisioning
   - Tailscale ingress configuration
   - PostgreSQL databases for applications

3. **Backup and Recovery**:
   - Minikube volume backup functionality
   - Backup transfer via Tailscale

4. **Operational Management**:
   - Status checking and monitoring
   - Service listing and log viewing
   - Clean-up and uninstall operations

5. **Security**:
   - SSH hardening
   - Vault-encrypted secrets
   - VPN-only service access (no public exposure)

### Features Architecturally Inconsistent
- Cloud provider integration (AWS, GCP, Azure) - This is a bare-metal homelab solution
- Multi-node Kubernetes clusters - Designed for single-node Minikube
- Production-grade high availability - Single-node design without redundancy
- External load balancers - Uses Tailscale ingress instead
- CI/CD pipeline integration - Focused on infrastructure provisioning, not application development
- Container registry management - Uses external registries
- Dynamic scaling - Fixed resource allocation
- Web UI for management - CLI-first design

### Specialized Libraries and Domain Constraints
- **Ansible Core Modules**: Uses primarily builtin Ansible modules (command, copy, template, apt, systemd, etc.)
- **Minikube Addons**: storage-provisioner, default-storageclass, metrics-server
- **Helm Repositories**: 
  - tailscale (Tailscale operator)
  - k8s-at-home (homelab-focused charts)
  - gabe565 (community charts)
  - mojo2600 (Pi-hole)
  - pree (additional charts)
- **Ubuntu 24.04 Specific**: Bootstrap script and apt configuration tailored for Ubuntu Noble
- **Systemd**: Service management for host-level services
- **Docker as Minikube Driver**: Requires Docker for container runtime

### Design Constraints
- Designed for **bare-metal Ubuntu 24.04** servers
- **Single-host** deployment model (localhost or remote host)
- **Idempotent operations** required for all tasks
- **Declarative configuration** - no imperative scripts outside bootstrap
- **VPN-first networking** - all services accessed via Tailscale
- **Stateful applications** must use Kubernetes PersistentVolumes
- **Role-based modularity** - each component as a separate role
- **Tag-based execution** - support for selective provisioning
