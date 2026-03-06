# Storage Management Domain

## Overview
This domain manages persistent storage for stateful applications using Minikube's storage provisioner, Kubernetes PersistentVolumes, and PersistentVolumeClaims.

## Core Patterns

### Storage Provisioner Setup
Verify and configure Minikube storage provisioner:

**From roles/helm_apps/tasks/storage.yml:**
```yaml
- name: Verify Minikube storage provisioner is available
  ansible.builtin.command: kubectl get storageclass standard
  register: storage_check
  changed_when: false
  failed_when: false
  become: no

- name: Enable Minikube storage addon if not present
  ansible.builtin.command: minikube addons enable storage-provisioner
  when: storage_check.rc != 0
  become: no
  changed_when: false

- name: Set standard as default storage class
  ansible.builtin.command: >
    kubectl patch storageclass standard -p '{"metadata": {"annotations":{"storageclass.kubernetes.io/is-default-class":"true"}}}'
  when: storage_check.rc == 0
  changed_when: false
  failed_when: false
  become: no
```

Pattern:
1. Check if storage class exists
2. Enable addon if missing
3. Set as default storage class via annotation

### Minikube Cluster with Host Path Mounting
Minikube started with persistent volume mount:

**From roles/minikube/tasks/main.yml:**
```yaml
- name: Start Minikube cluster
  ansible.builtin.command: >
    minikube start
    --driver={{ minikube_driver }}
    --cpus={{ minikube_cpus }}
    --memory={{ minikube_memory }}
    --disk-size={{ minikube_disk_size }}
    --mount-string="/mnt:/tmp/hostpath-provisioner"
  when: minikube_status.rc != 0
  become: no
```

This mounts host `/mnt` to Minikube's `/tmp/hostpath-provisioner` for persistent storage.

### PersistentVolumeClaim Creation
Dynamic provisioning via storage class:

**Example from qBittorrent:**
```yaml
- name: Create shared downloads PVC
  ansible.builtin.copy:
    dest: /tmp/shared-downloads-pvc.yaml
    content: |
      ---
      apiVersion: v1
      kind: PersistentVolumeClaim
      metadata:
        name: shared-downloads
        namespace: {{ qbittorrent_namespace }}
      spec:
        accessModes:
          - ReadWriteMany
        storageClassName: {{ storage_class }}
        resources:
          requests:
            storage: 50Gi
  become: no

- name: Apply shared downloads PVC
  ansible.builtin.command: kubectl apply -f /tmp/shared-downloads-pvc.yaml
  changed_when: true
  become: no
```

### NFS External Storage
Manual PV creation for external NFS mounts:

**Example from Sonarr (media storage):**
```yaml
- name: Create Sonarr NFS PV and PVC
  ansible.builtin.copy:
    dest: /tmp/sonarr-nfs.yaml
    content: |
      ---
      apiVersion: v1
      kind: PersistentVolume
      metadata:
        name: sonarr-media-pv
      spec:
        capacity:
          storage: 500Gi
        accessModes:
          - ReadWriteMany
        persistentVolumeReclaimPolicy: Retain
        nfs:
          server: plex-jellyfin.tail44dd7.ts.net
          path: /d/Videos/Shows
      ---
      apiVersion: v1
      kind: PersistentVolumeClaim
      metadata:
        name: sonarr-media
        namespace: {{ sonarr_namespace }}
      spec:
        accessModes:
          - ReadWriteMany
        storageClassName: ""  # Manual binding (no dynamic provisioning)
        resources:
          requests:
            storage: 500Gi
        volumeName: sonarr-media-pv
```

Pattern:
- PV references external NFS server (via Tailscale)
- PVC explicitly binds to PV by name
- `storageClassName: ""` disables dynamic provisioning
- `persistentVolumeReclaimPolicy: Retain` prevents data deletion

### Helm Chart Persistence Configuration
Applications use existing PVCs via Helm values:

**Example from Sonarr Helm values:**
```yaml
persistence:
  config:
    enabled: true
    existingClaim: sonarr-config
  media:
    enabled: true
    existingClaim: sonarr-media
    mountPath: /media
  downloads:
    enabled: true
    existingClaim: shared-downloads
    mountPath: /downloads
```

Pattern:
- Create PVCs before deploying application
- Reference via `existingClaim` in Helm values
- Specify mount paths for each volume

### Inline Helm Persistence (Dynamic Provisioning)
Some applications let Helm create PVCs:

**Example from qBittorrent:**
```yaml
persistence:
  config:
    enabled: true
    storageClass: {{ storage_class }}
    accessMode: ReadWriteOnce
    size: 1Gi
  downloads:
    enabled: true
    existingClaim: shared-downloads
    mountPath: /downloads
```

Pattern:
- `storageClass` specified for dynamic provisioning
- Helm chart creates PVC automatically
- Mix of dynamic (config) and pre-created (downloads) claims

## Storage Types

### Application Configuration Storage
Small volumes for application config/database:
- Size: 1Gi - 10Gi
- Access Mode: ReadWriteOnce (single pod)
- Storage Class: `standard` (Minikube provisioner)
- Examples: Gogs config, Sonarr config, qBittorrent config

### Shared Storage
Volumes shared across multiple applications:
- Size: 50Gi+
- Access Mode: ReadWriteMany (multiple pods)
- Storage Class: `standard` or NFS
- Example: `shared-downloads` (used by qBittorrent, Sonarr, Jackett)

### Media Storage
Large external NFS volumes for media files:
- Size: 500Gi+
- Access Mode: ReadWriteMany
- Storage: External NFS server
- Examples: TV shows, movies

### Database Storage
StatefulSet volumes for databases:
- Size: 5Gi - 20Gi
- Access Mode: ReadWriteOnce
- Storage Class: `standard`
- Example: PostgreSQL for Gogs

## Storage Addons

### Minikube Storage Addons
Enabled during cluster initialization:

```yaml
- name: Enable Minikube addons
  ansible.builtin.command: "minikube addons enable {{ item }}"
  loop:
    - storage-provisioner
    - default-storageclass
    - metrics-server
  changed_when: false
  failed_when: false
  become: no
```

## Volume Mounting in StatefulSets

**Example from Gogs PostgreSQL:**
```yaml
spec:
  containers:
  - name: postgres
    image: postgres:14
    volumeMounts:
    - name: postgres-storage
      mountPath: /var/lib/postgresql/data
  volumeClaimTemplates:
  - metadata:
      name: postgres-storage
    spec:
      accessModes:
        - ReadWriteOnce
      storageClassName: {{ storage_class }}
      resources:
        requests:
          storage: 10Gi
```

StatefulSet pattern:
- Uses `volumeClaimTemplates` instead of PVCs
- Each replica gets its own PVC
- PVCs named: `{template-name}-{statefulset-name}-{ordinal}`

## Storage Configuration Variables

**From group_vars/all.yml:**
```yaml
storage_class: "standard"
```

**From Minikube defaults:**
```yaml
minikube_disk_size: "20g"
```

## Access Modes

### ReadWriteOnce (RWO)
- Volume mounted read-write by single node
- Used for: Application configs, databases
- Storage backend: Minikube hostPath provisioner

### ReadWriteMany (RWX)
- Volume mounted read-write by multiple nodes
- Used for: Shared downloads, media libraries
- Storage backend: NFS or Minikube provisioner

## Storage Lifecycle

### Creation Flow
1. Verify storage provisioner is running
2. Set default storage class
3. Create PVC manifests (or use Helm)
4. Apply PVC manifests
5. Wait for PVCs to bind
6. Deploy application with volume references

### Backup Flow
(See backup-recovery domain for full details)
- Volumes backed up at Minikube level (entire volume directory)
- Not per-PVC granularity

## Constraints
- All storage provisioning via Minikube storage-provisioner or external NFS
- No cloud storage providers (EBS, Azure Disks, etc.)
- Storage class must be configured before app deployment
- PVCs must exist in same namespace as consuming pods
- StatefulSet volumeClaimTemplates create PVCs automatically
- External NFS requires network accessibility (via Tailscale)
- Minikube disk size set at cluster creation (can't expand)
- Volume data persists across pod restarts but tied to cluster lifecycle
