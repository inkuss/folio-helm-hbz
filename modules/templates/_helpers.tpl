{{/*
Create backend-module name and maybe version as label.
*/}}
{{- define "folio.backend.name" -}}
{{- printf "%s-%s" .name .version | lower | replace "." "-" | trunc 63 | trimSuffix "-" -}}
{{- end -}}



{{/*
Full name with tag to allow for the same module installed in different releases
Truncation: max length 63; 6 characters for pod hash, 11 characters for replica set hash of deployments
  version: semantic, probably 5-7 characters, tag 6 characters; 63 -6 -11 = 46; 46 -7 -6 = 33;
  Truncating the Module Name itself to make names as clear as possible; revise on collisons 
*/}}
{{- define "folio.backend.fullname" -}}
{{- $truncatedName := .name | trunc 33 }}
{{- printf "%s-%s-%s" $truncatedName .version .tag | lower | trunc 46 | replace "." "-"  | trimSuffix "-" -}}
{{- end -}}




{{/*
Expand the name of the chart.
*/}}
{{- define "folio.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{/*
Create a default fully qualified app name.
We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
If release name contains chart name it will be used as a full name.
CURRENTLY UNUSED
*/}}
{{- define "folio.fullname" -}}
{{- if .Values.fullnameOverride -}}
{{- .Values.fullnameOverride | trunc 63 | trimSuffix "-" -}}
{{- else -}}
{{- $name := default .Chart.Name .Values.nameOverride -}}
{{- if contains $name .Release.Name -}}
{{- .Release.Name | trunc 63 | trimSuffix "-" -}}
{{- else -}}
{{- printf "%s-%s" .Release.Name $name | trunc 63 | trimSuffix "-" -}}
{{- end -}}
{{- end -}}
{{- end -}}

{{/*
Create chart name and version as used by the chart label.
*/}}
{{- define "folio.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{- define "folio.backend.service.type" -}}
        {{- if and .service -}}
                {{- if .service.type -}}
                        {{ .service.type }}
                {{- end -}}
        {{- end -}}
{{- end -}}

{{- define "folio.backend.pod.port" -}}
        {{- if and .pod -}}
                {{- if .pod.port -}}
                        {{ .pod.port }}
                {{- end -}}
        {{- end -}}
{{- end -}}

{{- define "folio.stripes.service.type" -}}
        {{- if and .service -}}
                {{- if .service.type -}}
                        {{ .service.type }}
                {{- end -}}
        {{- end -}}
{{- end -}}

{{- define "folio.stripes.service.port" -}}
        {{- if and .service -}}
                {{- if .service.port -}}
                        {{ .service.port }}
                {{- end -}}
        {{- end -}}
{{- end -}}

