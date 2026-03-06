# Application Deployment Domain

## Overview
This domain handles deployment of self-hosted applications to Kubernetes via Helm charts or inline Kubernetes manifests. All applications are exposed via Tailscale ingress for secure VPN-only access.

## Core Patterns

### Namespace Creation
Every application starts with namespace creation:

```yaml
- name: Create Sonarr namespace
  ansible.builtin.command: kubectl create namespace {{ sonarr_namespace }}
  failed_when: false  # Idempotent - don't fail if exists
  changed_when: false
  become: no
```

### Helm-Based Deployment
Applications deployed using `helm upgrade --install` pattern:

**Example from qBittorrent:**
```yaml
- name: Create qBittorrent Helm values file
  ansible.builtin.copy:
    dest: /tmp/qbittorrent-values.yaml
    content: |
      env:
        TZ: UTC
        PUID: "1000"
        PGID: "1000"
        WEBUI_PORT: "8080"
      
      service:
        main:
          type: ClusterIP
          annotations:
            tailscale.com/expose: "true"
            tailscale.com/hostname: "{{ tailscale_qbittorrent_hostname | default('qbittorrent') }}"
          ports:
            http:
              port: 8080
      
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
      
      resources:
        limits:
          cpu: 1000m
          memory: 2Gi
        requests:
          cpu: 200m
          memory: 512Mi

- name: Deploy qBittorrent using Helm
  ansible.builtin.command: >
    helm upgrade --install qbittorrent gabe565/qbittorrent
    --namespace {{ qbittorrent_namespace }}
    --values /tmp/qbittorrent-values.yaml
    {{ '--version ' + qbittorrent_chart_version if qbittorrent_chart_version else '' }}
    --wait
  changed_when: true
  become: no
```

### Manifest-Based Deployment
Complex applications use inline Kubernetes manifest files:

**Example from Gogs (Git service):**
```yaml
- name: Create Gogs manifest
  ansible.builtin.copy:
    dest: /tmp/gogs-manifest.yaml
    content: |
      ---
      # PostgreSQL ConfigMap
      apiVersion: v1
      kind: ConfigMap
      metadata:
        name: postgres-config
        namespace: {{ gogs_namespace }}
      data:
        db_name: gogs
        db_user: gogs
        db_pass: gogspassword
        data_dir: /var/lib/postgresql/data/pgdata
      ---
      # PostgreSQL Service
      apiVersion: v1
      kind: Service
      metadata:
        name: postgres
        namespace: {{ gogs_namespace }}
        labels:
          app: postgres
      spec:
        ports:
        - name: postgres
          protocol: TCP
          port: 5432
          targetPort: 5432
        selector:
          app: postgres
        type: ClusterIP
      ---
      # ... (StatefulSets, Deployments, etc.)

- name: Apply Gogs manifest
  ansible.builtin.command: kubectl apply -f /tmp/gogs-manifest.yaml
  changed_when: true
  become: no
```

### Tailscale Ingress Configuration
All services use Tailscale annotations for ingress:

```yaml
service:
  main:
    type: ClusterIP
    annotations:
      tailscale.com/expose: "true"
      tailscale.com/hostname: "{{ tailscale_sonarr_hostname | default('sonarr') }}"
    ports:
      http:
        port: 8989
```

This creates a Tailscale ingress accessible at `http://sonarr` within the VPN.

### Persistent Storage Configuration
Applications with persistent data use PersistentVolumeClaims:

**Example - Config storage:**
```yaml
- name: Create Sonarr config PVC
  ansible.builtin.copy:
    dest: /tmp/sonarr-config-pvc.yaml
    content: |
      ---
      apiVersion: v1
      kind: PersistentVolumeClaim
      metadata:
        name: sonarr-config
        namespace: {{ sonarr_namespace }}
      spec:
        accessModes:
          - ReadWriteOnce
        storageClassName: {{ storage_class }}
        resources:
          requests:
            storage: 1Gi
  become: no

- name: Apply Sonarr config PVC
  ansible.builtin.command: kubectl apply -f /tmp/sonarr-config-pvc.yaml
  changed_when: true
  become: no
```

**Example - NFS shared storage:**
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
        storageClassName: ""
        resources:
          requests:
            storage: 500Gi
        volumeName: sonarr-media-pv
```

### Helm Repository Management
Helm repos added and updated before deployment:

**From helm_apps main.yml:**
```yaml
- name: Add Helm repositories for applications
  ansible.builtin.command: "helm repo add {{ item.name }} {{ item.url }}"
  loop:
    - { name: "tailscale", url: "https://pkgs.tailscale.com/helmcharts" }
    - { name: "k8s-at-home", url: "https://k8s-at-home.com/charts/" }
    - { name: "gabe565", url: "https://charts.gabe565.com" }
    - { name: "mojo2600", url: "https://mojo2600.github.io/pihole-kubernetes/" }
    - { name: "pree", url: "https://pree.github.io/helm-charts/" }
  register: helm_repo_add_result
  changed_when: false
  failed_when: false
  become: no

- name: Update Helm repositories
  ansible.builtin.command: helm repo update
  changed_when: false
  become: no
```

### Task Organization
Applications organized in separate task files:

**From roles/helm_apps/tasks/main.yml:**
```yaml
- name: Deploy Tailscale operator
  ansible.builtin.include_tasks: tailscale-operator.yml

- name: Configure Minikube storage provisioner
  ansible.builtin.include_tasks: storage.yml

- name: Deploy Gogs
  ansible.builtin.include_tasks: gogs.yml

- name: Deploy qBittorrent
  ansible.builtin.include_tasks: qbittorrent.yml

- name: Deploy Sonarr
  ansible.builtin.include_tasks: sonarr.yml

- name: Deploy Jackett
  ansible.builtin.include_tasks: jackett.yml

- name: Deploy Crontab UI
  ansible.builtin.include_tasks: crontab-ui.yml

- name: Deploy Pi-hole
  ansible.builtin.include_tasks: pihole.yml
```

## Application Categories

### Media Management (Namespace: media)
- **Sonarr** - TV show PVR
- **qBittorrent** - BitTorrent client  
- **Jackett** - Torrent indexer proxy

These share:
- Same namespace (`media`)
- Shared downloads PVC (`shared-downloads`)
- Internal DNS communication (e.g., `qbittorrent.media.svc.cluster.local`)

### Development Tools (Namespace: git)
- **Gogs** - Self-hosted Git service with PostgreSQL backend
- StatefulSet architecture
- Dual Tailscale ingress (HTTP and SSH)

### Network Services (Namespace: pihole)
- **Pi-hole** - DNS and ad blocking
- Dual Tailscale services (web UI and DNS)

### System Management (Namespace: default)
- **Crontab UI** - Web-based cron manager
- Uses custom Helm chart from `files/crontab-ui/`

### Infrastructure (Namespace: tailscale)
- **Tailscale Operator** - VPN ingress controller
- OAuth-based authentication

## Deployment Patterns

### Pattern 1: Simple Helm Chart
1. Create namespace
2. Update Helm repos
3. Create values file in /tmp
4. Run `helm upgrade --install` with values file

### Pattern 2: Complex Manifest
1. Create namespace
2. Create multi-document YAML manifest in /tmp
3. Apply manifest with `kubectl apply -f`

### Pattern 3: Helm Chart + Pre-created PVCs
1. Create namespace
2. Create PVC manifest(s)
3. Apply PVC manifest(s)
4. Create Helm values referencing `existingClaim`
5. Deploy with Helm

## Service Discovery
Applications communicate using Kubernetes DNS:
- Format: `{service}.{namespace}.svc.cluster.local:{port}`
- Example: `qbittorrent.media.svc.cluster.local:8080`
- Example: `postgres.git.svc.cluster.local:5432`

## Resource Management
All applications define resource requests and limits:

```yaml
resources:
  limits:
    cpu: 1000m
    memory: 2Gi
  requests:
    cpu: 200m
    memory: 512Mi
```

## Constraints
- All services must use `ClusterIP` type (no LoadBalancer/NodePort)
- External access only via Tailscale ingress annotations
- Manifest files written to `/tmp` before application
- All Helm operations run with `become: no` (non-root)
- `--wait` flag ensures deployment completion before proceeding
- Namespaces created before any resources
- Storage provisioner must be configured before app deployment
