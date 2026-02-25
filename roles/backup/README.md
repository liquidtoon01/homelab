# Backup Role

This role creates a backup of Minikube volumes and sends them via Tailscale taildrop.

## Features

- Creates timestamped tar.gz archives of Minikube persistent volumes
- Includes BACKUP_INFO.md file with original path and restore instructions
- Automatically excludes socket files that can't be archived
- Automatically sends backups via Tailscale taildrop
- Automated weekly backups via cron (default: Sunday at 2 AM)
- Sends push notifications on errors via Pushover.net (optional)
- Cleans up temporary files after successful transfer
- Displays backup file size and transfer status

## Default Configuration

**Source Directory:** `/var/lib/docker/volumes/minikube/_data/hostpath-provisioner`

**Target Device:** `100.97.131.29` (Tailscale IP)

**Backup Location:** `/tmp/minikube-volumes-backup-<timestamp>.tar.gz`

**Schedule:** Weekly on Sunday at 2 AM (configurable)

**Log File:** `/var/log/minikube-backup.log`

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
backup_schedule: "0 2 * * 0"  # Weekly on Sunday at 2 AM (cron format)
homelab_dir: "{{ ansible_env.HOME }}/homelab"  # Path to homelab directory

# Pushover notifications (optional)
pushover_enabled: false
pushover_user_key: ""
pushover_api_token: ""
pushover_priority: 0  # -2=lowest, -1=low, 0=normal, 1=high, 2=emergency
```

#### Backup Schedule

The `backup_schedule` uses standard cron format: `minute hour day month weekday`

Examples:
- `0 2 * * 0` - Weekly on Sunday at 2 AM (default)
- `0 3 * * *` - Daily at 3 AM
- `0 1 1 * *` - Monthly on the 1st at 1 AM
- `0 4 * * 6` - Weekly on Saturday at 4 AM

The backup filename is automatically generated with a timestamp in the format: `minikube-volumes-backup-<timestamp>.tar.gz`

#### Enabling Pushover Notifications

To receive push notifications on backup errors:

1. Sign up at [pushover.net](https://pushover.net)
2. Create an application to get an API token
3. Get your user key from the dashboard
4. Update `roles/backup/defaults/main.yml`:

```yaml
pushover_enabled: true
pushover_user_key: "your-user-key-here"
pushover_api_token: "your-app-token-here"
pushover_priority: 1  # High priority for errors
```

Notifications are sent when:
- Backup tasks fail (critical errors) - includes error message, stderr, stdout, and task name
- Backup archive is not created - includes tar exit code and error output
- Tailscale is not running (backup created but not sent) - includes Tailscale error details

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
- Pushover.net account (optional, for error notifications)

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
