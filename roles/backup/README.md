# Backup Role

This role creates a backup of Minikube volumes and sends them via Tailscale taildrop.

## Features

- Creates timestamped tar.gz archives of Minikube persistent volumes
- Automatically excludes socket files that can't be archived
- Automatically sends backups via Tailscale taildrop
- Cleans up temporary files after successful transfer
- Displays backup file size and transfer status

## Default Configuration

**Source Directory:** `/var/lib/docker/volumes/minikube/_data/hostpath-provisioner`

**Target Device:** `100.97.131.29` (Tailscale IP)

**Backup Location:** `/tmp/minikube-volumes-backup-<timestamp>.tar.gz`

## Usage

### Using Make

```bash
make backup
```

### Using Ansible Playbook

```bash
ansible-playbook -i inventory/hosts.yml playbooks/backup.yml
```

### Custom Configuration

Edit `roles/backup/defaults/main.yml` to customize:

```yaml
backup_source_dir: /var/lib/docker/volumes/minikube/_data/hostpath-provisioner
backup_temp_dir: /tmp
tailscale_target_ip: "100.97.131.29"
```

The backup filename is automatically generated with a timestamp in the format: `minikube-volumes-backup-<timestamp>.tar.gz`

Or override in your playbook:

```yaml
- name: Backup with custom settings
  hosts: all
  become: yes
  roles:
    - role: backup
      vars:
        tailscale_target_ip: "100.97.131.50"
        backup_source_dir: /custom/path
```

## Prerequisites

- `zip` package installed (automatically installed by base role)
- Tailscale running and authenticated
- Target device accepting Tailscale file transfers
- Sufficient disk space in temp directory

## What Gets Backed Up

All persistent volume data including:
- Gogs repositories and database
- PostgreSQL data
- Sonarr configuration and database
- qBittorrent configuration and downloads
- Pi-hole configuration and blocklists

## Receiving Backups

On the target device (100.97.131.29), files are saved to:

- **Linux/macOS:** `~/Downloads/`
- **Windows:** `%USERPROFILE%\Downloads\`

## Troubleshooting

**Backup created but not sent:**
- Ensure Tailscale is running: `tailscale status`
- Check target device accepts files: `tailscale file get`
- Verify target IP is correct

**Backup file too large:**
- Large downloads folder from qBittorrent
- Consider excluding downloads: modify backup task to zip specific subdirectories

**Permission denied:**
- Run with sudo: The backup role requires root access
- Ansible playbook should use `become: yes`
