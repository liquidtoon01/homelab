# Ansible Templates Style Guide

## Overview
Jinja2 templates generate configuration files from variables. This project uses templates minimally - only for system configuration in the apt_updates role.

## File Structure

### File Location
`roles/{role-name}/templates/{filename}.j2`

### Extension
Always `.j2` for Jinja2 templates.

## Template Files in Project

### 20auto-upgrades.j2
APT automatic update configuration:
```jinja
APT::Periodic::Update-Package-Lists "1";
APT::Periodic::Download-Upgradeable-Packages "1";
APT::Periodic::AutocleanInterval "7";
APT::Periodic::Unattended-Upgrade "1";
```

No variables - static configuration.

### 50unattended-upgrades.j2
Unattended upgrades configuration with conditional:

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

## Jinja2 Syntax

### Variable Substitution
```jinja
{{ variable_name }}
```

### Conditionals
```jinja
{% if condition %}
content when true
{% endif %}
```

### Comments
```jinja
{# This is a Jinja2 comment - won't appear in output #}
```

## Template Deployment

### Usage in Tasks
```yaml
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

### Parameters
- `src`: Template filename (automatically found in templates/ dir)
- `dest`: Destination path on target system
- `mode`: File permissions

## Template vs Copy Module

### Use Template When:
- File needs variable substitution
- Conditional content based on variables
- Dynamic configuration generation

### Use Copy When:
- Static content
- Multi-line YAML/JSON
- Kubernetes manifests
- Helm values files

Example - Copy is used for Kubernetes manifests:
```yaml
- name: Create Gogs manifest
  ansible.builtin.copy:
    dest: /tmp/gogs-manifest.yaml
    content: |
      ---
      apiVersion: v1
      kind: ConfigMap
      metadata:
        name: postgres-config
        namespace: {{ gogs_namespace }}
```

Even though `{{ gogs_namespace }}` is used, `copy` with `content` handles variable substitution.

## File Permissions

### System Configuration Files
```yaml
mode: '0644'  # Readable by all, writable by root only
```

### Scripts
```yaml
mode: '0755'  # Executable by all, writable by root only
```

## Conditional Blocks

### Optional Configuration
```jinja
{% if apt_updates_email %}
// Send email to this address for problems or packages upgrades
Unattended-Upgrade::Mail "{{ apt_updates_email }}";
{% endif %}
```

Pattern: Only include configuration block if variable is defined and not empty.

### Check for Empty String
The template checks truthiness - empty string is falsy:
```yaml
# In defaults
apt_updates_email: ""

# In template - this block won't render
{% if apt_updates_email %}
...
{% endif %}
```

## Comment Preservation

### Target File Comments
Keep comments in target file format:
```jinja
// This is a C-style comment for APT config
# This is a shell-style comment
// Use appropriate comment style for the target file
```

### Inline Documentation
```jinja
// Automatically reboot *WITHOUT CONFIRMATION* if
//  the file /var/run/reboot-required is found after the upgrade
Unattended-Upgrade::Automatic-Reboot "false";
```

Explain non-obvious settings.

## Static Content Pattern

### Mostly Static with Few Variables
Most configuration is static - templates used minimally:
```jinja
// Fixed values
Unattended-Upgrade::Remove-Unused-Dependencies "true";
Unattended-Upgrade::Automatic-Reboot "false";
Unattended-Upgrade::Automatic-Reboot-Time "03:00";

// Variable section
{% if apt_updates_email %}
Unattended-Upgrade::Mail "{{ apt_updates_email }}";
{% endif %}
```

## No Complex Logic

### Keep Templates Simple
Templates contain:
- Simple variable substitution: `{{ variable }}`
- Basic conditionals: `{% if variable %}`
- NO loops
- NO filters beyond basic
- NO complex Jinja2 operations

Complex logic belongs in tasks, not templates.

## Whitespace Handling

### Preserve Original Formatting
Maintain formatting of original configuration files:
```jinja
Unattended-Upgrade::Origins-Pattern {
    "origin=Ubuntu,archive=${distro_codename}-security";
    "origin=Ubuntu,archive=${distro_codename}-updates";
};
```

### Jinja2 Whitespace Control
Not used in this project - templates preserve all whitespace as-is.

## Project-Specific Patterns

### Limited Template Usage
Only `apt_updates` role uses templates.

Other roles use:
- `copy` module with `content` for inline YAML
- Static files in `files/` directory
- Direct command execution

### System Configuration Only
Templates used for system configuration files:
- APT configuration
- NOT for application config
- NOT for Kubernetes manifests

### No Template Inheritance
No base templates or includes - each template standalone.

### No Custom Filters
Uses only built-in Jinja2 features, no custom filters registered.
