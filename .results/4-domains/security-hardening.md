# Security Hardening Domain

## Overview
This domain implements security best practices including SSH hardening, automated security updates, secrets encryption, and VPN-only service access.

## Core Patterns

### SSH Configuration Hardening
Bootstrap script backs up and modifies SSH configuration:

**From bootstrap.sh:**
```bash
echo ""
echo "=== Configuring SSH Security ==="

# Backup original SSH config
sudo cp /etc/ssh/sshd_config /etc/ssh/sshd_config.backup.$(date +%Y%m%d_%H%M%S)

# Configure SSH hardening
SSH_CONFIG="/etc/ssh/sshd_config"

# Disable root login (uncomment if you want to enforce this)
# sudo sed -i 's/^#\?PermitRootLogin.*/PermitRootLogin no/' "$SSH_CONFIG"

# Disable password authentication (recommend using keys only)
# sudo sed -i 's/^#\?PasswordAuthentication.*/PasswordAuthentication no/' "$SSH_CONFIG"

# Limit max authentication attempts
sudo sed -i 's/^#\?MaxAuthTries.*/MaxAuthTries 3/' "$SSH_CONFIG"

# Restart SSH service to apply changes
sudo systemctl restart sshd
```

Pattern:
1. Backup original config with timestamp
2. Use sed for in-place modifications
3. Restart service to apply changes

### Automated Security Updates
Uses Ubuntu's unattended-upgrades system:

**From roles/apt_updates/tasks/main.yml:**
```yaml
- name: Install unattended-upgrades package
  ansible.builtin.apt:
    name:
      - unattended-upgrades
      - apt-listchanges
    state: present

- name: Configure unattended-upgrades
  ansible.builtin.template:
    src: 50unattended-upgrades.j2
    dest: /etc/apt/apt.conf.d/50unattended-upgrades
    mode: '0644'

- name: Enable automatic updates
  ansible.builtin.template:
    src: 20auto-upgrades.j2
    dest: /etc/apt/apt.conf.d/20auto-upgrades
    mode: '0644'
```

**Template: 50unattended-upgrades.j2:**
```jinja
// Unattended-Upgrade::Origins-Pattern controls which packages are
// upgraded.
Unattended-Upgrade::Origins-Pattern {
    "origin=Ubuntu,archive=${distro_codename}-security";
    "origin=Ubuntu,archive=${distro_codename}-updates";
};

// List of packages to not update
Unattended-Upgrade::Package-Blacklist {
};

// Do automatic removal of new unused dependencies after the upgrade
Unattended-Upgrade::Remove-Unused-Dependencies "true";

// Automatically reboot *WITHOUT CONFIRMATION* if
//  the file /var/run/reboot-required is found after the upgrade
Unattended-Upgrade::Automatic-Reboot "false";

// If automatic reboot is enabled and needed, reboot at the specific
// time instead of immediately
Unattended-Upgrade::Automatic-Reboot-Time "03:00";

{% if apt_updates_email %}
// Send email to this address for problems or packages upgrades
Unattended-Upgrade::Mail "{{ apt_updates_email }}";
{% endif %}
```

**Template: 20auto-upgrades.j2:**
```jinja
APT::Periodic::Update-Package-Lists "1";
APT::Periodic::Download-Upgradeable-Packages "1";
APT::Periodic::AutocleanInterval "7";
APT::Periodic::Unattended-Upgrade "1";
```

### Scheduled Update Script
Additional cron-based update automation:

```yaml
- name: Create apt update script
  ansible.builtin.copy:
    dest: /usr/local/bin/apt-update.sh
    mode: '0755'
    content: |
      #!/bin/bash
      # Automated apt update script
      
      apt-get update
      apt-get upgrade -y
      apt-get autoremove -y
      apt-get autoclean

- name: Schedule apt updates with cron
  ansible.builtin.cron:
    name: "Automated apt updates"
    minute: "{{ apt_updates_schedule.split()[0] }}"
    hour: "{{ apt_updates_schedule.split()[1] }}"
    day: "{{ apt_updates_schedule.split()[2] }}"
    month: "{{ apt_updates_schedule.split()[3] }}"
    weekday: "{{ apt_updates_schedule.split()[4] }}"
    job: "/usr/local/bin/apt-update.sh >> /var/log/apt-update.log 2>&1"
    user: root
```

Default schedule: `"0 3 * * 0"` (Weekly Sunday at 3 AM)

### Ansible Vault Encryption
All sensitive data encrypted with ansible-vault:

**Vault setup script (setup-vault.sh):**
```bash
#!/bin/bash
# Script to set up Ansible Vault for sensitive variables

# Check if vault.yml already exists
if [ -f "vault.yml" ]; then
    echo "vault.yml already exists."
    read -p "Do you want to edit it? (y/n): " edit_choice
    if [ "$edit_choice" = "y" ]; then
        ansible-vault edit vault.yml
    fi
    exit 0
fi

# Copy example to vault.yml
cp vault.yml.example vault.yml

echo "Please edit vault.yml and add your actual secrets:"
$EDITOR vault.yml

# Encrypt the vault file
ansible-vault encrypt vault.yml

echo ""
echo "vault.yml created and encrypted!"
echo "To edit in the future: ansible-vault edit vault.yml"
```

**Vault password file:**
ansible.cfg references `.vault_pass` file for automatic decryption:
```properties
vault_password_file = .vault_pass
```

### VPN-Only Service Access
No public exposure - all services behind Tailscale VPN:

**Tailscale service annotations:**
```yaml
service:
  main:
    type: ClusterIP  # Never LoadBalancer or NodePort
    annotations:
      tailscale.com/expose: "true"
      tailscale.com/hostname: "{{ tailscale_gogs_hostname }}"
```

Pattern:
- All services use `ClusterIP` type (internal only)
- Tailscale Operator creates ingress tunnels
- Services accessible only within VPN: `http://hostname`

### Privilege Separation
Minimal use of root privileges:

```yaml
- name: Start Minikube cluster
  ansible.builtin.command: minikube start ...
  become: no  # Run as regular user

- name: Install Docker prerequisites
  ansible.builtin.apt:
    name: docker.io
    state: present
  # become: yes (inherited from play level)
```

Pattern:
- Play-level `become: yes` for general system operations
- Task-level `become: no` override for user operations
- Docker group membership instead of running as root

## Security Configuration Files

### File Permissions
All security-sensitive files have restricted permissions:
- System config files: `0644` (read-only for non-root)
- Scripts: `0755` (executable by all, writable by root only)
- Vault files: Should be in `.gitignore`, encrypted at rest

### Backup Before Modification
Always backup before changing security-critical files:

```bash
sudo cp /etc/ssh/sshd_config /etc/ssh/sshd_config.backup.$(date +%Y%m%d_%H%M%S)
```

Timestamp format: `YYYYMMDD_HHMMSS`

## Network Security

### No Public Ports
- No services listen on public interfaces
- All ingress via Tailscale encrypted tunnels
- Kubernetes services use `ClusterIP` only

### Host Firewall
Configured via Tailscale:
- Only Tailscale network has access
- Host firewall managed by Tailscale daemon

## Application Security

### Database Credentials
Stored in ConfigMaps (not ideal for production, acceptable for homelab):

```yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: postgres-config
  namespace: {{ gogs_namespace }}
data:
  db_name: gogs
  db_user: gogs
  db_pass: gogspassword  # Note: Use secrets in production
```

Pattern: Acceptable for internal homelab, but noted for improvement.

### User Isolation
Docker group membership for non-root Docker access:

```yaml
- name: Get current username
  ansible.builtin.command: whoami
  register: current_user
  changed_when: false
  become: no

- name: Add current user to docker group
  ansible.builtin.user:
    name: "{{ current_user.stdout }}"
    groups: docker
    append: yes
```

## Update Schedule Configuration

Default schedule manageable via variable:
```yaml
apt_updates_schedule: "0 3 * * 0"  # Cron format
apt_updates_email: ""  # Optional email notifications
```

## Security Constraints
- Vault password file (`.vault_pass`) must be present but NOT in git
- All secrets must be in encrypted vault.yml
- No services exposed on public IPs
- SSH modifications require service restart
- Unattended-upgrades only installs security updates by default
- Automatic reboots disabled by default (set to false)
- All system services managed via systemd
- Tailscale must be running for service access
