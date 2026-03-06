# Backup and Recovery Domain

## Overview
This domain manages backup of Minikube persistent volumes and transfer to remote hosts via Tailscale's taildrop feature.

## Core Patterns

### Timestamp-Based Naming
Backups named with ISO8601 timestamps for uniqueness:

```yaml
- name: Set backup filename
  ansible.builtin.set_fact:
    backup_filename: "minikube-volumes-backup-{{ ansible_facts.date_time.iso8601_basic_short }}.tar.gz"
```

Format: `minikube-volumes-backup-YYYYMMDDTHHMMSS.tar.gz`

### Error Handling with Block/Rescue
All backup tasks wrapped in error handling:

```yaml
- name: Run backup tasks with error handling
  block:
    - name: Check if backup source directory exists
      ansible.builtin.stat:
        path: "{{ backup_source_dir }}"
      register: backup_source

    - name: Fail if backup source does not exist
      ansible.builtin.fail:
        msg: "Backup source directory {{ backup_source_dir }} does not exist or is not accessible"
      when: not backup_source.stat.exists or not backup_source.stat.readable

    # ... backup tasks ...

  rescue:
    - name: Set error message with details
      ansible.builtin.set_fact:
        backup_error_msg: |
          Backup failed on {{ ansible_facts.hostname }}
          
          Error: {{ ansible_failed_result.msg | default('Unknown error') }}
          {% if ansible_failed_result.stderr is defined and ansible_failed_result.stderr %}
          
          Stderr: {{ ansible_failed_result.stderr }}
          {% endif %}

    - name: Display error message
      ansible.builtin.debug:
        msg: "{{ backup_error_msg }}"
```

### Pre-Backup Validation
Verify source before attempting backup:

```yaml
- name: Check if backup source directory exists
  ansible.builtin.stat:
    path: "{{ backup_source_dir }}"
  register: backup_source

- name: Display backup source status
  ansible.builtin.debug:
    msg: "Backup source: {{ backup_source_dir }} - Exists: {{ backup_source.stat.exists | default(false) }} - Readable: {{ backup_source.stat.readable | default(false) }}"

- name: Check if backup source has contents
  ansible.builtin.find:
    paths: "{{ backup_source_dir }}"
    file_type: any
  register: source_contents

- name: Display directory contents count
  ansible.builtin.debug:
    msg: "Found {{ source_contents.matched }} items in {{ backup_source_dir }}"
```

### Backup Metadata File
Create info file documenting backup contents:

```yaml
- name: Create backup info file
  ansible.builtin.copy:
    content: |
      # Minikube Volume Backup Information

      **Backup Created:** {{ ansible_facts.date_time.iso8601 }}
      
      **Original Path:** `{{ backup_source_dir }}`
      
      **Hostname:** {{ ansible_facts.hostname }}
      
      **Total Items:** {{ source_contents.matched }}
      
      ## Archive Contents
      
      This archive contains a backup of all Minikube persistent volumes, including:
      - Application configurations
      - Database data (PostgreSQL for Gogs)
      - Git repositories (Gogs)
      - Downloaded media files (qBittorrent)
      - Application state (Sonarr, Pi-hole)
      
      ## Exclusions
      
      The following file types are excluded from the backup:
      - `*.sock` - Unix domain sockets
      - `*-socket` - Socket files
      - `ipc-socket` - Inter-process communication sockets
      
      ## Restore Instructions
      
      To restore this backup:
      
      ```bash
      # Extract the archive
      tar -xzf {{ backup_filename }}
      
      # Copy contents to original location (requires root)
      sudo cp -r * {{ backup_source_dir }}/
      ```
    dest: "{{ backup_temp_dir }}/BACKUP_INFO.md"
    mode: '0644'
```

### Archive Creation with Exclusions
Create compressed archive excluding socket files:

```yaml
- name: Create backup archive (excluding socket files)
  ansible.builtin.command:
    cmd: "tar --exclude='*.sock' --exclude='*-socket' --exclude='ipc-socket' -czf {{ backup_temp_dir }}/{{ backup_filename }} -C {{ backup_temp_dir }} BACKUP_INFO.md -C {{ backup_source_dir }} ."
  changed_when: true
  failed_when: false
  register: tar_result

- name: Display tar result
  ansible.builtin.debug:
    msg: "Backup archive creation: {{ 'succeeded' if tar_result.rc == 0 else 'completed with warnings (rc=' + (tar_result.rc | string) + ')' }}"
```

Pattern:
- Use `--exclude` for socket files (can't be backed up)
- `failed_when: false` allows warnings (non-fatal)
- Include BACKUP_INFO.md in archive

### File Size Reporting
Display backup size after creation:

```yaml
- name: Check if backup file was created
  ansible.builtin.stat:
    path: "{{ backup_temp_dir }}/{{ backup_filename }}"
  register: backup_file

- name: Display backup file size
  ansible.builtin.debug:
    msg: "Backup created: {{ backup_temp_dir }}/{{ backup_filename }} ({{ (backup_file.stat.size / 1024 / 1024) | round(2) }} MB)"
  when: backup_file.stat.exists
```

### Tailscale Transfer
Send backup to remote host via taildrop:

```yaml
- name: Check if Tailscale is running
  ansible.builtin.command: tailscale status
  register: tailscale_status
  changed_when: false
  failed_when: false

- name: Send backup via Tailscale taildrop
  ansible.builtin.command:
    cmd: "tailscale file cp {{ backup_temp_dir }}/{{ backup_filename }} {{ tailscale_target_ip }}:"
  when: tailscale_status.rc == 0
  changed_when: true

- name: Display taildrop status
  ansible.builtin.debug:
    msg: "Backup sent to {{ tailscale_target_ip }} via Tailscale taildrop"
  when: tailscale_status.rc == 0

- name: Warning if Tailscale is not running
  ansible.builtin.debug:
    msg: "WARNING: Tailscale is not running. Backup created at {{ backup_temp_dir }}/{{ backup_filename }} but not sent."
  when: tailscale_status.rc != 0
```

Pattern:
- Check Tailscale status before attempting transfer
- Only transfer if Tailscale is running
- Keep backup locally if transfer fails

### Cleanup After Transfer
Remove backup after successful transfer:

```yaml
- name: Remove backup file from temp directory
  ansible.builtin.file:
    path: "{{ backup_temp_dir }}/{{ backup_filename }}"
    state: absent
  when: tailscale_status.rc == 0

- name: Remove backup info file from temp directory
  ansible.builtin.file:
    path: "{{ backup_temp_dir }}/BACKUP_INFO.md"
    state: absent
```

Only delete if transfer succeeded.

## Backup Configuration

**From roles/backup/defaults/main.yml:**
```yaml
---
# Backup configuration
backup_source_dir: /var/lib/docker/volumes/minikube/_data/hostpath-provisioner
backup_temp_dir: /tmp
tailscale_target_ip: "100.97.131.29"
backup_schedule: "0 2 * * 0"  # Weekly on Sunday at 2 AM
homelab_dir: "{{ ansible_facts.env.HOME }}/homelab"  # Path to homelab directory

# Pushover notification configuration
pushover_enabled: false
pushover_user_key: ""
pushover_api_token: ""
pushover_priority: 0  # -2=lowest, -1=low, 0=normal, 1=high, 2=emergency
```

## Backup Scope

### What is Backed Up
- All Minikube persistent volumes
- Application configurations
- Database data (PostgreSQL, etc.)
- Git repositories (Gogs)
- Downloaded media files (qBittorrent shared-downloads)
- Application state (Sonarr, Pi-hole, etc.)

### What is Excluded
- Socket files: `*.sock`, `*-socket`, `ipc-socket`
- Temporary files
- Running process data

## Backup Source Location
Default: `/var/lib/docker/volumes/minikube/_data/hostpath-provisioner`

This is the Docker volume where Minikube stores all persistent volume data.

## Transfer Methods

### Tailscale Taildrop
- Direct file transfer via Tailscale VPN
- No intermediate storage needed
- Secure encrypted transfer
- Target identified by Tailscale IP

Command format:
```bash
tailscale file cp /path/to/backup.tar.gz 100.97.131.29:
```

## Recovery Process

### Manual Restore
From BACKUP_INFO.md documentation:

```bash
# Extract the archive
tar -xzf minikube-volumes-backup-YYYYMMDDTHHMMSS.tar.gz

# Stop Minikube (to prevent conflicts)
minikube stop

# Copy contents to original location (requires root)
sudo cp -r * /var/lib/docker/volumes/minikube/_data/hostpath-provisioner/

# Start Minikube
minikube start
```

## Playbook Usage

**From playbooks/backup.yml:**
```yaml
---
- name: Backup Minikube Volumes
  hosts: all
  become: yes
  
  roles:
    - role: backup
      tags: ['backup']
```

**Execute backup:**
```bash
ansible-playbook -i inventory/hosts.yml playbooks/backup.yml
```

**From Makefile:**
```makefile
backup: ## Backup Minikube volumes and send via Tailscale
	@echo "Creating backup of Minikube volumes..."
	ansible-playbook -i inventory/hosts.yml playbooks/backup.yml
```

## Backup Schedule
Default: Weekly on Sunday at 2 AM (`0 2 * * 0`)

Can be scheduled via cron or run manually.

## Constraints
- Full backup only (no incremental)
- Entire Minikube volume directory backed up as single archive
- No per-application/volume granularity
- Requires Tailscale for remote transfer
- Manual restore process (no automated restore)
- Backup runs as root (requires sudo)
- Socket files excluded (can't be archived)
- Temporary storage required (usually /tmp)
- No retention policy (manual cleanup)
- No compression level configuration (uses default gzip -6)
