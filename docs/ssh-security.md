# SSH Security Guide

This guide explains the SSH security hardening applied by the bootstrap script and how to further secure your server.

## What the Bootstrap Script Does

The `bootstrap.sh` script automatically hardens SSH configuration with the following settings:

### Applied Automatically

✅ **Public Key Authentication**: Enabled  
✅ **Empty Passwords**: Disabled  
✅ **X11 Forwarding**: Disabled (security risk)  
✅ **Client Keep-Alive**: 300 seconds (prevents connection timeouts)  
✅ **Max Authentication Tries**: Limited to 3 attempts  
✅ **Login Grace Time**: 60 seconds  
✅ **Configuration Backup**: Original config saved to `/etc/ssh/sshd_config.backup.TIMESTAMP`

### Optional (Commented for Safety)

The following settings are **commented out** in the bootstrap script for safety. You should enable them manually after setting up SSH keys:

🔒 **Disable Password Authentication**: Force SSH key-only authentication  
🔒 **Disable Root Login**: Prevent direct root SSH access

## Setting Up SSH Keys

### On Your Local Machine

If you don't already have SSH keys:

```bash
# Generate a new SSH key pair (Ed25519 is recommended)
ssh-keygen -t ed25519 -C "your_email@example.com"

# Or use RSA if Ed25519 is not supported
ssh-keygen -t rsa -b 4096 -C "your_email@example.com"

# Accept the default location (~/.ssh/id_ed25519 or ~/.ssh/id_rsa)
# Set a strong passphrase (recommended)
```

### Copy Key to Server

```bash
# Copy your public key to the server
ssh-copy-id username@server-ip

# Or manually:
cat ~/.ssh/id_ed25519.pub | ssh username@server-ip "mkdir -p ~/.ssh && cat >> ~/.ssh/authorized_keys"
```

### Test SSH Key Authentication

```bash
# Test the connection
ssh username@server-ip

# You should login without entering your server password
# (You may need to enter your SSH key passphrase)
```

## Enabling Maximum Security

Once SSH key authentication is working, enable maximum security:

### Step 1: Edit SSH Configuration

```bash
# On the server
sudo nano /etc/ssh/sshd_config
```

### Step 2: Uncomment or Add These Lines

```
# Disable password authentication
PasswordAuthentication no

# Disable root login via SSH
PermitRootLogin no

# Optional: Change the default SSH port (security through obscurity)
# Port 2222
```

### Step 3: Verify Configuration

```bash
# Test the SSH configuration syntax
sudo sshd -t

# If no errors, proceed to restart
```

### Step 4: Restart SSH

```bash
sudo systemctl restart sshd
```

### Step 5: Test Before Closing Session

**IMPORTANT**: Before logging out, test the connection in a new terminal:

```bash
# In a NEW terminal window (don't close the existing one yet!)
ssh username@server-ip
```

If the new connection works, you can safely close the old terminal.

## Additional SSH Security Measures

### Change Default SSH Port

Changing the SSH port reduces automated attack attempts:

```bash
sudo nano /etc/ssh/sshd_config
```

Change:
```
Port 2222  # Or any port above 1024
```

Update firewall:
```bash
sudo ufw allow 2222/tcp
sudo ufw reload
sudo systemctl restart sshd
```

Connect using:
```bash
ssh -p 2222 username@server-ip
```

### Use SSH Key Passphrases

Always protect your SSH keys with strong passphrases:

```bash
# Add a passphrase to an existing key
ssh-keygen -p -f ~/.ssh/id_ed25519
```

### Use SSH Agent

To avoid typing the passphrase repeatedly:

```bash
# Start SSH agent
eval "$(ssh-agent -s)"

# Add your key
ssh-add ~/.ssh/id_ed25519

# Now SSH connections won't prompt for the passphrase
```

### Limit User Access

Create a dedicated user for SSH access instead of using root:

```bash
# Create new user
sudo adduser deployuser

# Add to sudo group
sudo usermod -aG sudo deployuser

# Copy SSH keys
sudo rsync -av ~/.ssh/ /home/deployuser/.ssh/
sudo chown -R deployuser:deployuser /home/deployuser/.ssh
```

### Enable Two-Factor Authentication (Advanced)

For maximum security, enable 2FA with Google Authenticator:

```bash
sudo apt-get install libpam-google-authenticator

# Follow the prompts
google-authenticator

# Edit PAM configuration
sudo nano /etc/pam.d/sshd

# Add this line at the top:
# auth required pam_google_authenticator.so

# Edit SSH config
sudo nano /etc/ssh/sshd_config

# Set:
# ChallengeResponseAuthentication yes

sudo systemctl restart sshd
```

## Monitoring SSH Access

### View SSH Login Attempts

```bash
# Recent successful logins
sudo lastlog

# All login attempts
sudo last

# Failed login attempts
sudo grep "Failed password" /var/log/auth.log

# Successful SSH logins
sudo grep "Accepted publickey" /var/log/auth.log
```

### Real-time SSH Monitoring

```bash
# Watch authentication logs in real-time
sudo tail -f /var/log/auth.log
```

### Install Fail2Ban (Recommended)

Automatically ban IPs after failed login attempts:

```bash
sudo apt-get install fail2ban

# Configure
sudo cp /etc/fail2ban/jail.conf /etc/fail2ban/jail.local
sudo nano /etc/fail2ban/jail.local

# Enable SSH jail
[sshd]
enabled = true
port = ssh
filter = sshd
logpath = /var/log/auth.log
maxretry = 3
bantime = 3600

# Start and enable
sudo systemctl start fail2ban
sudo systemctl enable fail2ban

# Check status
sudo fail2ban-client status sshd
```

## Troubleshooting

### Locked Out

If you lock yourself out:

1. **Console Access**: Use KVM/IPMI to access the server console
2. **Restore Backup**:
   ```bash
   sudo cp /etc/ssh/sshd_config.backup.* /etc/ssh/sshd_config
   sudo systemctl restart sshd
   ```

3. **Re-enable Password Auth**:
   ```bash
   sudo sed -i 's/^PasswordAuthentication no/PasswordAuthentication yes/' /etc/ssh/sshd_config
   sudo systemctl restart sshd
   ```

### SSH Keys Not Working

1. **Check permissions**:
   ```bash
   # On server
   chmod 700 ~/.ssh
   chmod 600 ~/.ssh/authorized_keys
   
   # On local machine
   chmod 600 ~/.ssh/id_ed25519
   chmod 644 ~/.ssh/id_ed25519.pub
   ```

2. **Verify key format**:
   ```bash
   cat ~/.ssh/authorized_keys
   # Should be one key per line, no extra whitespace
   ```

3. **Check SSH logs**:
   ```bash
   sudo tail -100 /var/log/auth.log
   ```

### Connection Timeouts

If connections keep timing out:

1. **Adjust keep-alive** (already configured by bootstrap):
   ```
   ClientAliveInterval 300
   ClientAliveCountMax 2
   ```

2. **On client side** (`~/.ssh/config`):
   ```
   Host your-server
       HostName server-ip
       ServerAliveInterval 60
       ServerAliveCountMax 120
   ```

## SSH Configuration File Locations

- **Main SSH config**: `/etc/ssh/sshd_config`
- **Backup config**: `/etc/ssh/sshd_config.backup.*`
- **User authorized keys**: `~/.ssh/authorized_keys`
- **SSH logs**: `/var/log/auth.log`
- **Client config**: `~/.ssh/config` (on your local machine)

## Best Practices Summary

1. ✅ Always use SSH keys instead of passwords
2. ✅ Protect SSH keys with strong passphrases
3. ✅ Disable password authentication after key setup
4. ✅ Disable root SSH login
5. ✅ Consider changing the default SSH port
6. ✅ Monitor SSH logs regularly
7. ✅ Install Fail2Ban to prevent brute force attacks
8. ✅ Keep SSH server updated
9. ✅ Use a firewall (UFW)
10. ✅ Consider 2FA for critical servers

## Quick Reference Commands

```bash
# Test SSH config syntax
sudo sshd -t

# Restart SSH service
sudo systemctl restart sshd

# View SSH service status
sudo systemctl status sshd

# View recent SSH logins
sudo last | head -20

# View failed login attempts
sudo grep "Failed password" /var/log/auth.log | tail -20

# Check current SSH connections
who

# Reload SSH (without dropping connections)
sudo systemctl reload sshd
```

## Additional Resources

- [OpenSSH Documentation](https://www.openssh.com/)
- [SSH Key Management Best Practices](https://www.ssh.com/academy/ssh/key-management)
- [Fail2Ban Documentation](https://www.fail2ban.org/)
- [Mozilla SSH Guidelines](https://infosec.mozilla.org/guidelines/openssh)
