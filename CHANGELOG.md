# Changelog

All notable changes to this project will be documented in this file.

## [1.1.0] - 2026-02-23

### Added
- **snapd and msedit** installation in bootstrap script:
  - snapd (Snap package manager) installed via apt
  - msedit (text editor) installed via Snap
  - Useful for editing configuration files on the server
- **Tailscale Operator** for Kubernetes ingress:
  - Deployed via Helm chart from official Tailscale repository
  - All applications now accessible via Tailscale hostnames (e.g., `http://gogs`, `http://sonarr:8989`)
  - Automatic Tailscale device creation for each service
  - MagicDNS integration for easy access across Tailnet
  - OAuth client authentication for Kubernetes operator
- Service configurations updated to use LoadBalancer type with Tailscale annotations
- Tailscale hostname customization variables in `group_vars/all.yml`
- Comprehensive Tailscale operator documentation (`docs/tailscale-operator.md`)
- Updated all application documentation with Tailscale access instructions
- Updated infrastructure documentation with Tailscale operator section

### Changed
- All application services changed from NodePort to LoadBalancer type
- Primary access method is now via Tailscale (NodePort still available as fallback)
- Documentation updated to prioritize Tailscale access over NodePort

### Documentation
- Added [Tailscale Operator Setup](docs/tailscale-operator.md) guide
- Updated [Applications](docs/applications.md) with Tailscale access methods
- Updated [Infrastructure Components](docs/infrastructure.md) with Tailscale operator
- Updated [Getting Started](GETTING_STARTED.md) with OAuth credential setup
- Updated [Quick Start](QUICKSTART.md) with Tailscale configuration
- Updated [README.md](README.md) with Tailscale operator information

## [1.0.0] - 2026-02-23

### Added
- Initial release of Kimsufi Infrastructure as Code
- Bootstrap script for Ansible installation on Ubuntu 24.04
- Git installation in bootstrap script (required for cloning repository)
- Complete setup documentation:
  - GETTING_STARTED.md - Comprehensive step-by-step guide
  - Instructions for cloning repository before bootstrap
  - Repository URL placeholders in documentation
- SSH security hardening in bootstrap script:
  - Public key authentication enabled
  - Empty passwords disabled
  - X11 forwarding disabled
  - Connection keep-alive configuration
  - Max authentication attempts limited
  - Original SSH config backup
  - Optional password auth and root login disable (commented for safety)
- Ansible roles for infrastructure components:
  - Base dependencies (Docker, common packages)
  - kubectl installation
  - Helm installation
  - Minikube setup with Docker driver
  - Tailscale VPN configuration
  - Scheduled apt updates with unattended-upgrades
- Ansible role for Helm applications:
  - Rancher local-path-provisioner for storage
  - Gogs for self-hosted Git
  - Sonarr for TV show management
  - Headscale for self-hosted Tailscale control
  - Immich for photo/video backup
  - qBittorrent for torrent downloads
  - Pi-hole for network-wide ad blocking and DNS
- Comprehensive documentation:
  - Bootstrap guide
  - Infrastructure components guide
  - Applications guide
  - Troubleshooting guide
- Project structure following Ansible best practices
- Makefile for common operations
- Example inventory and variables files

### Infrastructure Details
- Minikube configured with 2 CPUs, 4GB RAM, 20GB disk by default
- All services exposed via NodePort
- Persistent storage using local-path-provisioner
- Security hardening with automatic updates

### Documentation
- README with quick start guide
- Detailed documentation for each component
- Troubleshooting guide with common issues
- Requirements documentation

## Future Enhancements

Planned features for future releases:

- [x] ~~Ingress controller with SSL/TLS~~ (Replaced with Tailscale Operator - simpler and more secure)
- [ ] Monitoring stack (Prometheus + Grafana)
- [ ] Automated backup solution
- [ ] CI/CD pipeline with Gogs webhooks
- [ ] Additional media applications (Radarr, Lidarr)
- [ ] Network file sharing (NFS/Samba)
- [ ] VPN gateway (WireGuard)
- [ ] Certificate management (cert-manager with Tailscale certificates)
- [ ] External DNS integration
- [ ] Multiple node support
