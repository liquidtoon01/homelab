# Troubleshooting Guide

Common issues and their solutions for the Kimsufi infrastructure.

## Table of Contents

- [SSH Issues](#ssh-issues)
- [Ansible Issues](#ansible-issues)
- [Minikube Issues](#minikube-issues)
- [Kubernetes Issues](#kubernetes-issues)
- [Helm Issues](#helm-issues)
- [Application Issues](#application-issues)
- [Storage Issues](#storage-issues)
- [Network Issues](#network-issues)
- [Performance Issues](#performance-issues)

---

## SSH Issues

### Locked Out After SSH Hardening

**Symptoms**: Cannot connect via SSH after running bootstrap or modifying SSH config

**Solutions**:

1. **If you have console access** (KVM, IPMI, physical access):
   ```bash
   # Login via console
   # Restore SSH backup
   sudo cp /etc/ssh/sshd_config.backup.* /etc/ssh/sshd_config
   sudo systemctl restart sshd
   ```

2. **If password auth was disabled but keys aren't working**:
   ```bash
   # Via console, re-enable password auth temporarily
   sudo sed -i 's/^PasswordAuthentication no/PasswordAuthentication yes/' /etc/ssh/sshd_config
   sudo systemctl restart sshd
   ```

3. **Check SSH key permissions** (on your local machine):
   ```bash
   chmod 600 ~/.ssh/id_rsa
   chmod 644 ~/.ssh/id_rsa.pub
   chmod 700 ~/.ssh
   ```

4. **Test SSH with verbose output**:
   ```bash
   ssh -v user@server-ip
   # Look for authentication errors in output
   ```

### SSH Connection Refused

**Symptoms**: `Connection refused` error

**Solutions**:

1. Verify SSH service is running:
   ```bash
   # Via console
   sudo systemctl status sshd
   sudo systemctl start sshd
   ```

2. Check if SSH is listening on correct port:
   ```bash
   sudo netstat -tlnp | grep ssh
   # Or
   sudo ss -tlnp | grep ssh
   ```

3. Verify firewall rules:
   ```bash
   sudo ufw status
   sudo ufw allow OpenSSH
   ```

### SSH Key Authentication Not Working

**Symptoms**: Prompted for password despite having SSH keys

**Solutions**:

1. Verify public key is in authorized_keys:
   ```bash
   # On server
   cat ~/.ssh/authorized_keys
   ```

2. Check SSH directory permissions:
   ```bash
   # On server
   chmod 700 ~/.ssh
   chmod 600 ~/.ssh/authorized_keys
   ```

3. Check SSH config allows key authentication:
   ```bash
   # On server
   sudo grep PubkeyAuthentication /etc/ssh/sshd_config
   # Should show: PubkeyAuthentication yes
   ```

4. View SSH auth logs:
   ```bash
   sudo tail -f /var/log/auth.log
   # Try connecting in another terminal and watch for errors
   ```

### Restore Original SSH Configuration

**Symptoms**: Need to revert SSH changes

**Solutions**:

```bash
# List available backups
ls -la /etc/ssh/sshd_config.backup.*

# Restore most recent backup
sudo cp /etc/ssh/sshd_config.backup.* /etc/ssh/sshd_config

# Or restore to Ubuntu defaults
sudo apt-get install --reinstall openssh-server

# Restart SSH
sudo systemctl restart sshd
```

---

## Ansible Issues

### Bootstrap Script Fails

**Symptoms**: Bootstrap script exits with errors

**Solutions**:

1. Ensure you're running as root or with sudo:
   ```bash
   sudo ./bootstrap.sh
   ```

2. Check internet connectivity:
   ```bash
   ping -c 4 8.8.8.8
   ```

3. Verify Ubuntu version:
   ```bash
   lsb_release -a
   # Should show 24.04
   ```

### Playbook Fails with "Unable to connect"

**Symptoms**: Ansible cannot connect to the host

**Solutions**:

1. For local installation, verify `ansible_connection: local` in inventory

2. For remote installation, test SSH connection:
   ```bash
   ssh -i ~/.ssh/id_rsa user@hostname
   ```

3. Check SSH key permissions:
   ```bash
   chmod 600 ~/.ssh/id_rsa
   ```

### "Permission denied" Errors

**Symptoms**: Tasks fail with permission errors

**Solutions**:

1. Ensure user has sudo privileges:
   ```bash
   sudo -v
   ```

2. Add `--ask-become-pass` flag:
   ```bash
   ansible-playbook -i inventory/hosts.yml playbooks/site.yml --ask-become-pass
   ```

---

## Minikube Issues

### Minikube Fails to Start

**Symptoms**: `minikube start` fails with errors

**Solutions**:

1. Check Docker is running:
   ```bash
   sudo systemctl status docker
   sudo systemctl start docker
   ```

2. Delete and recreate Minikube cluster:
   ```bash
   minikube delete
   minikube start --driver=docker
   ```

3. Check available resources:
   ```bash
   free -h  # Check memory
   df -h    # Check disk space
   ```

4. View detailed Minikube logs:
   ```bash
   minikube logs
   ```

### Minikube is Slow

**Symptoms**: Minikube performance is poor

**Solutions**:

1. Allocate more resources in `group_vars/all.yml`:
   ```yaml
   minikube_cpus: 4
   minikube_memory: "8192"
   ```

2. Restart Minikube with new settings:
   ```bash
   minikube delete
   ansible-playbook -i inventory/hosts.yml playbooks/infrastructure.yml --tags minikube
   ```

### Cannot Access Minikube Services

**Symptoms**: Services not accessible from host

**Solutions**:

1. Get Minikube IP:
   ```bash
   minikube ip
   ```

2. List services and their ports:
   ```bash
   minikube service list
   ```

3. Use port forwarding:
   ```bash
   kubectl port-forward -n <namespace> svc/<service> 8080:8080
   ```

---

## Kubernetes Issues

### Pods Stuck in Pending State

**Symptoms**: Pods don't start, remain in "Pending"

**Solutions**:

1. Check pod events:
   ```bash
   kubectl describe pod -n <namespace> <pod-name>
   ```

2. Check node resources:
   ```bash
   kubectl top nodes
   kubectl describe node
   ```

3. Check for PVC issues:
   ```bash
   kubectl get pvc -n <namespace>
   kubectl describe pvc -n <namespace> <pvc-name>
   ```

4. Verify storage class exists:
   ```bash
   kubectl get storageclass
   ```

### Pods CrashLoopBackOff

**Symptoms**: Pods keep restarting

**Solutions**:

1. Check pod logs:
   ```bash
   kubectl logs -n <namespace> <pod-name>
   kubectl logs -n <namespace> <pod-name> --previous
   ```

2. Describe pod for events:
   ```bash
   kubectl describe pod -n <namespace> <pod-name>
   ```

3. Check resource limits:
   ```bash
   kubectl get pod -n <namespace> <pod-name> -o yaml | grep -A 5 resources
   ```

### Image Pull Errors

**Symptoms**: Pods fail to pull container images

**Solutions**:

1. Check internet connectivity from Minikube:
   ```bash
   minikube ssh
   ping -c 4 8.8.8.8
   curl https://registry-1.docker.io/v2/
   ```

2. Check image name and tag:
   ```bash
   kubectl get pod -n <namespace> <pod-name> -o yaml | grep image:
   ```

3. Pull image manually to test:
   ```bash
   minikube ssh
   docker pull <image-name>
   ```

---

## Helm Issues

### Helm Install Fails

**Symptoms**: `helm install` or `helm upgrade` fails

**Solutions**:

1. Check Helm version compatibility:
   ```bash
   helm version
   ```

2. Update Helm repositories:
   ```bash
   helm repo update
   ```

3. Verify chart exists:
   ```bash
   helm search repo <chart-name>
   ```

4. Use verbose mode for debugging:
   ```bash
   helm install <release> <chart> --debug --dry-run
   ```

5. Check values file syntax:
   ```bash
   helm lint -f <values-file>
   ```

### Helm Timeout Errors

**Symptoms**: Helm operations timeout

**Solutions**:

1. Increase timeout:
   ```bash
   helm upgrade --install <release> <chart> --timeout 15m
   ```

2. Check if pods are starting:
   ```bash
   kubectl get pods -n <namespace> -w
   ```

3. Disable wait (not recommended for production):
   ```bash
   helm upgrade --install <release> <chart> --wait=false
   ```

---

## Application Issues

### Gitea Not Accessible

**Solutions**:

1. Check Gitea pod status:
   ```bash
   kubectl get pods -n gitea
   kubectl logs -n gitea -l app.kubernetes.io/name=gitea
   ```

2. Verify service:
   ```bash
   kubectl get svc -n gitea
   minikube service gitea-http -n gitea
   ```

3. Check PVC is bound:
   ```bash
   kubectl get pvc -n gitea
   ```

### qBittorrent Won't Start

**Solutions**:

1. Check permissions on PVCs:
   ```bash
   kubectl get pvc -n media
   ```

2. Verify user/group IDs:
   ```bash
   kubectl logs -n media -l app.kubernetes.io/name=qbittorrent
   ```

3. Reset qBittorrent config:
   ```bash
   kubectl delete pod -n media -l app.kubernetes.io/name=qbittorrent
   ```

### Sonarr Can't Connect to qBittorrent

**Solutions**:

1. Verify both are in the same namespace:
   ```bash
   kubectl get pods -n media
   ```

2. Use correct service name:
   - Host: `qbittorrent.media.svc.cluster.local`
   - Port: `8080`

3. Test connectivity:
   ```bash
   kubectl exec -it -n media <sonarr-pod> -- curl qbittorrent:8080
   ```

---

## Storage Issues

### PVC Stuck in Pending

**Symptoms**: Persistent Volume Claims not bound

**Solutions**:

1. Check storage class:
   ```bash
   kubectl get storageclass
   kubectl get pvc -n <namespace>
   ```

2. Reinstall local-path-provisioner:
   ```bash
   ansible-playbook -i inventory/hosts.yml playbooks/applications.yml --tags helm --start-at-task="Install local-path-provisioner"
   ```

3. Manually provision:
   ```bash
   kubectl apply -f https://raw.githubusercontent.com/rancher/local-path-provisioner/master/deploy/local-path-storage.yaml
   ```

### Out of Disk Space

**Symptoms**: Cannot create new volumes

**Solutions**:

1. Check disk usage:
   ```bash
   df -h
   minikube ssh
   df -h /opt/local-path-provisioner/
   ```

2. Clean up unused volumes:
   ```bash
   kubectl delete pvc -n <namespace> <unused-pvc>
   ```

3. Prune Docker images:
   ```bash
   minikube ssh
   docker system prune -a
   ```

4. Expand disk if possible or add external storage

---

## Network Issues

### Cannot Access Services from Outside

**Solutions**:

1. Use Minikube service command:
   ```bash
   minikube service <service-name> -n <namespace>
   ```

2. Use kubectl port-forward:
   ```bash
   kubectl port-forward -n <namespace> svc/<service-name> 8080:8080
   ```

3. Access via Minikube IP:
   ```bash
   MINIKUBE_IP=$(minikube ip)
   NODE_PORT=$(kubectl get svc -n <namespace> <service-name> -o jsonpath='{.spec.ports[0].nodePort}')
   echo "Access at: http://$MINIKUBE_IP:$NODE_PORT"
   ```

4. Check firewall rules:
   ```bash
   sudo ufw status
   ```

### DNS Resolution Issues

**Symptoms**: Pods cannot resolve DNS names

**Solutions**:

1. Check CoreDNS pods:
   ```bash
   kubectl get pods -n kube-system -l k8s-app=kube-dns
   ```

2. Restart CoreDNS:
   ```bash
   kubectl rollout restart deployment -n kube-system coredns
   ```

3. Test DNS from a pod:
   ```bash
   kubectl run -it --rm debug --image=busybox --restart=Never -- nslookup kubernetes.default
   ```

---

## Performance Issues

### High CPU Usage

**Solutions**:

1. Check top processes:
   ```bash
   kubectl top pods --all-namespaces
   kubectl top nodes
   ```

2. Identify resource-hungry pods:
   ```bash
   kubectl get pods --all-namespaces --sort-by='.status.containerStatuses[0].restartCount'
   ```

3. Set resource limits:
   Edit Helm values to add CPU limits

4. Scale down non-essential services

### High Memory Usage

**Solutions**:

1. Check memory usage:
   ```bash
   free -h
   kubectl top nodes
   kubectl top pods --all-namespaces --sort-by='.metadata.name' | grep -v Running
   ```

2. Set memory limits in Helm values

3. Increase Minikube memory:
   ```yaml
   minikube_memory: "8192"
   ```

### Slow Application Response

**Solutions**:

1. Check pod status:
   ```bash
   kubectl get pods --all-namespaces
   ```

2. Check Minikube resources:
   ```bash
   minikube ssh
   top
   df -h
   ```

3. Restart slow applications:
   ```bash
   kubectl rollout restart deployment -n <namespace> <deployment-name>
   ```

4. Clear caches if applicable

---

## General Debugging Commands

```bash
# Get all resources in a namespace
kubectl get all -n <namespace>

# Describe any resource
kubectl describe <resource-type> <resource-name> -n <namespace>

# Get events
kubectl get events -n <namespace> --sort-by='.lastTimestamp'

# Get pod YAML
kubectl get pod -n <namespace> <pod-name> -o yaml

# Execute command in pod
kubectl exec -it -n <namespace> <pod-name> -- /bin/sh

# Copy files from pod
kubectl cp <namespace>/<pod-name>:/path/to/file ./local-file

# Get API resources
kubectl api-resources

# Check cluster info
kubectl cluster-info
kubectl cluster-info dump
```

---

## Getting Help

If you're still experiencing issues:

1. Check Minikube logs:
   ```bash
   minikube logs
   ```

2. Check Ansible playbook output for errors

3. Check application logs in detail:
   ```bash
   kubectl logs -n <namespace> <pod-name> --all-containers=true
   ```

4. Review the official documentation:
   - [Minikube Documentation](https://minikube.sigs.k8s.io/docs/)
   - [Kubernetes Documentation](https://kubernetes.io/docs/)
   - [Helm Documentation](https://helm.sh/docs/)

5. Search for specific error messages

6. Check application-specific documentation for each Helm chart

---

## Complete Reset

If all else fails, start fresh:

```bash
# Delete Minikube
minikube delete

# Re-run infrastructure playbook
ansible-playbook -i inventory/hosts.yml playbooks/infrastructure.yml

# Re-deploy applications
ansible-playbook -i inventory/hosts.yml playbooks/applications.yml
```

**Note**: This will delete all data. Backup important data first!
