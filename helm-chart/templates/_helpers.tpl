{{/*
Expand the name of the chart.
*/}}
{{- define "griot-and-grits.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Create a default fully qualified app name.
*/}}
{{- define "griot-and-grits.fullname" -}}
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
{{- define "griot-and-grits.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Common labels
*/}}
{{- define "griot-and-grits.labels" -}}
helm.sh/chart: {{ include "griot-and-grits.chart" . }}
{{ include "griot-and-grits.selectorLabels" . }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end }}

{{/*
Selector labels
*/}}
{{- define "griot-and-grits.selectorLabels" -}}
app.kubernetes.io/name: {{ include "griot-and-grits.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}

{{/*
Generate backend route host
*/}}
{{- define "griot-and-grits.backend.host" -}}
{{- .Values.backend.route.host }}
{{- end }}

{{/*
Generate frontend route host
*/}}
{{- define "griot-and-grits.frontend.host" -}}
{{- .Values.frontend.route.host }}
{{- end }}

{{/*
Generate MinIO console route host
*/}}
{{- define "griot-and-grits.minio.host" -}}
{{- .Values.minio.route.host }}
{{- end }}

{{/*
Generate frontend API URL
*/}}
{{- define "griot-and-grits.frontend.apiUrl" -}}
{{- if .Values.frontend.config.nextPublicApiUrl }}
{{- .Values.frontend.config.nextPublicApiUrl }}
{{- else }}
{{- printf "https://%s" (include "griot-and-grits.backend.host" .) }}
{{- end }}
{{- end }}

{{/*
Generate frontend auth URL
*/}}
{{- define "griot-and-grits.frontend.authUrl" -}}
{{- if .Values.frontend.config.nextAuthUrl }}
{{- .Values.frontend.config.nextAuthUrl }}
{{- else }}
{{- printf "https://%s" (include "griot-and-grits.frontend.host" .) }}
{{- end }}
{{- end }}

{{/*
Generate frontend base URL
*/}}
{{- define "griot-and-grits.frontend.baseUrl" -}}
{{- if .Values.frontend.config.nextPublicBaseUrl }}
{{- .Values.frontend.config.nextPublicBaseUrl }}
{{- else }}
{{- printf "https://%s" (include "griot-and-grits.frontend.host" .) }}
{{- end }}
{{- end }}
