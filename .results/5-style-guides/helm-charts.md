# Helm Charts Style Guide

## Overview
Custom Helm charts for applications without suitable public charts. This project has one custom chart: crontab-ui.

## Chart Location
`roles/helm_apps/files/{chart-name}/`

## Standard Helm Chart Structure

```
crontab-ui/
├── Chart.yaml
├── .helmignore
├── README.md
├── values.yaml
└── templates/
    ├── _helpers.tpl
    ├── deployment.yaml
    ├── pvc.yaml
    └── service.yaml
```

## Chart.yaml

### Required Fields
```yaml
apiVersion: v2
name: crontab-ui
description: A Helm chart for Crontab UI - Web-based cron job manager
type: application
version: 0.1.0
appVersion: "latest"
home: https://github.com/alseambusher/crontab-ui
sources:
  - https://github.com/alseambusher/crontab-ui
maintainers:
  - name: Your Name
    email: your.email@example.com
```

### Version Fields
- `version`: Chart version (semver)
- `appVersion`: Application version (string)

### Metadata Fields
- `home`: Project homepage
- `sources`: Source code repositories
- `maintainers`: Chart maintainers

## values.yaml

### Application Configuration
```yaml
replicaCount: 1

image:
  repository: alseambusher/crontab-ui
  pullPolicy: IfNotPresent
  tag: "latest"

service:
  type: ClusterIP
  port: 8000

persistence:
  enabled: true
  storageClass: standard
  accessMode: ReadWriteOnce
  size: 1Gi

resources:
  limits:
    cpu: 500m
    memory: 512Mi
  requests:
    cpu: 100m
    memory: 128Mi

tailscale:
  enabled: true
  hostname: cron
```

### Value Structure
- Top-level sections: image, service, persistence, resources
- Nested values with consistent indentation (2 spaces)
- String values quoted when necessary
- Boolean values: `true`/`false` (lowercase)

### Resource Specifications
```yaml
resources:
  limits:
    cpu: 500m       # Millicores
    memory: 512Mi   # Mebibytes
  requests:
    cpu: 100m
    memory: 128Mi
```

### Storage Configuration
```yaml
persistence:
  enabled: true
  storageClass: standard
  accessMode: ReadWriteOnce
  size: 1Gi
```

## Templates

### _helpers.tpl

Helper template functions:

```yaml
{{/*
Expand the name of the chart.
*/}}
{{- define "crontab-ui.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Create a default fully qualified app name.
*/}}
{{- define "crontab-ui.fullname" -}}
{{- if .Values.fullnameOverride }}
{{- .Values.fullnameOverride | trunc 63 | trimSuffix "-" }}
{{- else }}
{{- $name := default .Chart.Name .Values.nameOverride }}
{{- printf "%s" $name | trunc 63 | trimSuffix "-" }}
{{- end }}
{{- end }}

{{/*
Common labels
*/}}
{{- define "crontab-ui.labels" -}}
app.kubernetes.io/name: {{ include "crontab-ui.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end }}

{{/*
Selector labels
*/}}
{{- define "crontab-ui.selectorLabels" -}}
app.kubernetes.io/name: {{ include "crontab-ui.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}
```

Pattern: Standard Helm helper functions for names and labels.

### deployment.yaml

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: {{ include "crontab-ui.fullname" . }}
  labels:
    {{- include "crontab-ui.labels" . | nindent 4 }}
spec:
  replicas: {{ .Values.replicaCount }}
  selector:
    matchLabels:
      {{- include "crontab-ui.selectorLabels" . | nindent 6 }}
  template:
    metadata:
      labels:
        {{- include "crontab-ui.selectorLabels" . | nindent 8 }}
    spec:
      containers:
      - name: {{ .Chart.Name }}
        image: "{{ .Values.image.repository }}:{{ .Values.image.tag | default .Chart.AppVersion }}"
        imagePullPolicy: {{ .Values.image.pullPolicy }}
        ports:
        - name: http
          containerPort: 8000
          protocol: TCP
        volumeMounts:
        - name: crontab-data
          mountPath: /crontab-ui/crontabs
        resources:
          {{- toYaml .Values.resources | nindent 10 }}
      volumes:
      - name: crontab-data
        persistentVolumeClaim:
          claimName: {{ include "crontab-ui.fullname" . }}
```

### service.yaml

```yaml
apiVersion: v1
kind: Service
metadata:
  name: {{ include "crontab-ui.fullname" . }}
  labels:
    {{- include "crontab-ui.labels" . | nindent 4 }}
  {{- if .Values.tailscale.enabled }}
  annotations:
    tailscale.com/expose: "true"
    tailscale.com/hostname: {{ .Values.tailscale.hostname | quote }}
  {{- end }}
spec:
  type: {{ .Values.service.type }}
  ports:
    - port: {{ .Values.service.port }}
      targetPort: http
      protocol: TCP
      name: http
  selector:
    {{- include "crontab-ui.selectorLabels" . | nindent 4 }}
```

### pvc.yaml

```yaml
{{- if .Values.persistence.enabled }}
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: {{ include "crontab-ui.fullname" . }}
  labels:
    {{- include "crontab-ui.labels" . | nindent 4 }}
spec:
  accessModes:
    - {{ .Values.persistence.accessMode }}
  storageClassName: {{ .Values.persistence.storageClass }}
  resources:
    requests:
      storage: {{ .Values.persistence.size }}
{{- end }}
```

## Template Syntax

### Value References
```yaml
{{ .Values.image.repository }}
{{ .Values.service.port }}
```

### Chart/Release Info
```yaml
{{ .Chart.Name }}
{{ .Chart.AppVersion }}
{{ .Release.Name }}
{{ .Release.Service }}
```

### Helper Function Calls
```yaml
{{ include "crontab-ui.fullname" . }}
{{ include "crontab-ui.labels" . | nindent 4 }}
```

### Conditionals
```yaml
{{- if .Values.tailscale.enabled }}
annotations:
  tailscale.com/expose: "true"
{{- end }}
```

### YAML Conversion
```yaml
resources:
  {{- toYaml .Values.resources | nindent 10 }}
```

## .helmignore

Exclude files from packaged chart:

```
# Patterns to ignore when building packages.
*.md
.git/
```

## README.md

Document chart usage:

```markdown
# Crontab UI Helm Chart

A Helm chart for deploying Crontab UI on Kubernetes.

## Installation

```bash
helm install crontab-ui ./crontab-ui
```

## Configuration

| Parameter | Description | Default |
|-----------|-------------|---------|
| `replicaCount` | Number of replicas | `1` |
| `image.repository` | Image repository | `alseambusher/crontab-ui` |
```

## Chart Deployment

### From Local Path
```yaml
- name: Deploy Crontab UI using local Helm chart
  ansible.builtin.command: >
    helm upgrade --install crontab-ui
    {{ helm_apps_role_path }}/files/crontab-ui
    --namespace {{ crontab_ui_namespace }}
    --wait
  changed_when: true
  become: no
```

### From Repository
For public charts (not custom):
```yaml
- name: Deploy qBittorrent using Helm
  ansible.builtin.command: >
    helm upgrade --install qbittorrent gabe565/qbittorrent
    --namespace {{ qbittorrent_namespace }}
    --values /tmp/qbittorrent-values.yaml
    --wait
```

## Unique Patterns

### Minimal Custom Charts
Only create custom charts when:
- No suitable public chart exists
- Customization needs exceed values file override capability

### Local Chart Storage
Custom charts in `roles/helm_apps/files/{chart-name}/`

### Tailscale Integration
Custom charts include Tailscale service annotations:
```yaml
{{- if .Values.tailscale.enabled }}
annotations:
  tailscale.com/expose: "true"
  tailscale.com/hostname: {{ .Values.tailscale.hostname | quote }}
{{- end }}
```

### No Chart Dependencies
Charts are standalone - no dependencies in Chart.yaml.

### Standard Resource Limits
All charts define CPU/memory limits and requests.

### ClusterIP Services Only
All services use `type: ClusterIP` - external access via Tailscale only.
