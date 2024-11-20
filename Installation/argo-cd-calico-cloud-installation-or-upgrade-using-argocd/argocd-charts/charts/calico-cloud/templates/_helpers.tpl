{{/*
Expand the name of the chart.
*/}}
{{- define "calico-cloud.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Create a default fully qualified app name.
We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
If release name contains chart name it will be used as a full name.
*/}}
{{- define "calico-cloud.fullname" -}}
{{- if .Values.fullnameOverride }}
{{- .Values.fullnameOverride | trunc 63 | trimSuffix "-" }}
{{- else }}
{{- $name := default .Chart.Name .Values.nameOverride }}
{{- if contains $name .Release.Name }}
{{- .Release.Name | trunc 63 | trimSuffix "-" }}
{{- else }}
{{- printf "%s-%s" .Release.Name $name | trunc 63 | trimSuffix "-" }}
{{- end }}
{{- end }}
{{- end }}

{{/*
Create chart name and version as used by the chart label.
*/}}
{{- define "calico-cloud.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Common labels
*/}}
{{- define "calico-cloud.labels" -}}
helm.sh/chart: {{ include "calico-cloud.chart" . }}
{{ include "calico-cloud.selectorLabels" . }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | replace "+" "-" | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end }}

{{/*
Selector labels
*/}}
{{- define "calico-cloud.selectorLabels" -}}
app.kubernetes.io/name: {{ include "calico-cloud.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}

{{/*
Create the name of the service account to use
*/}}
{{- define "calico-cloud.serviceAccountName" -}}
{{- include "calico-cloud.fullname" . }}
{{- end }}

{{/*
Image and tag.

The image is contructed from various various values and modified to support several use cases as detailed below.

1. Use private registry config if specified
2. Otherwise, use the hidden value 'defaultImage' which enables substitution of the prod and dev image registries.
3. Otherwise, default to the prod registry.

The tag is modified as well to account for the fact that helm only supports semantic versioning for application versions whereas
docker doesn't support the full semantic versioning spec - specifically it does not support the plus '+' symbol which details metadata.
Prod releases will always have a semantic version (vX.Y.Z) and thus their image tag and helm version will match.
For dev, images are published using unmodified output of the git describe command (vX.Y.Z-N-g<hash>). To be semantically correct,
the chart version substitutes the '-g' for '+' (vX.Y.Z-N+<hash>).
*/}}
{{- define "calico-cloud.image" -}}
{{- $ver := replace "+" "-g" (.Values.image.tag | default .Chart.AppVersion) -}}
{{- if .Values.installer.registry -}}
{{- list (trimSuffix "/" .Values.installer.registry) (trimAll "/" .Values.installer.imagePath | default "calico-cloud-public") | join "/" | trimSuffix "/" }}/cc-operator:{{ $ver -}}
{{- else -}}
{{- .Values.defaultImage | default "quay.io/tigera/cc-operator" -}}:{{ $ver }}
{{- end }}
{{- end }}
