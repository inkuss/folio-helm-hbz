{{/*
Expand the name of the chart.
*/}}
{{- define "b3katimport.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Create a default fully qualified app name.
We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
If release name contains chart name it will be used as a full name.
*/}}
{{- define "b3katimport.fullname" -}}
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
{{- define "b3katimport.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Common labels
*/}}
{{- define "b3katimport.labels" -}}
helm.sh/chart: {{ include "b3katimport.chart" . }}
{{ include "b3katimport.selectorLabels" . }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end }}

{{/*
Selector labels
*/}}
{{- define "b3katimport.selectorLabels" -}}
app.kubernetes.io/name: {{ include "b3katimport.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}

{{/*
Create the name of the service account to use
*/}}
{{- define "b3katimport.serviceAccountName" -}}
{{- if .Values.serviceAccount.create }}
{{- default (include "b3katimport.fullname" .) .Values.serviceAccount.name }}
{{- else }}
{{- default "default" .Values.serviceAccount.name }}
{{- end }}
{{- end }}


{{/*
Get Solr URL
*/}}
{{- define "vufind.solrurl" }}
{{- $solrport := "8983" }}
{{- $solrhost := "solr" }}
{{- $solrhttp := (.Values.global).solrhttp | default "http" }}
{{- range $index, $solrservice := (lookup "v1" "Service" $.Release.Namespace "").items }}
{{- if and (get $solrservice.metadata.labels "solr-cloud") (eq (get $solrservice.metadata.labels "service-type") "common") }}
{{- $solrhost = $solrservice.metadata.name }}
{{- $solrport = print (first $solrservice.spec.ports).port }}
{{- end }}
{{- end }}
{{- if (.Values.global).solrhost }}
{{- $solrhost = .Values.global.solrhost }}
{{- end }}
{{- if (.Values.global).solrport }}
{{- $solrport = .Values.global.solrport }}
{{- end }}
{{- printf "%s://%s:%s" $solrhttp $solrhost $solrport }}
{{- end -}}

{{/*
Get Zookeeper Host(s)
*/}}
{{- define "vufind.zkhost" }}
{{- $zkport := "2181" }}
{{- $zkhost := "zookeeper" }}
{{- range $index, $zkservice := (lookup "v1" "Service" $.Release.Namespace "").items }}
{{- if and (get $zkservice.metadata.labels "solr-cloud") (eq (get $zkservice.metadata.labels "technology") "zookeeper") (eq (get $zkservice.metadata.labels "headless") "true") }}
{{- $zkhost = $zkservice.metadata.name }}
{{- range $index, $port:= $zkservice.spec.ports -}}
{{- if eq $port.name "tcp-client" -}}
{{- $zkport = print $port.port }}
{{- end -}}
{{- end -}}
{{- end }}
{{- end }}
{{- if (.Values.global).zkhost }}
{{- $zkhost = .Values.global.zkhost }}
{{- end }}
{{- if (.Values.global).zkport }}
{{- $zkport = .Values.global.zkport }}
{{- end }}
{{- printf "%s:%s" $zkhost $zkport }}
{{- end -}}
