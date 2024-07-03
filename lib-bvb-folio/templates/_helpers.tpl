{{/*
Expand the name of the chart.
*/}}
{{- define "titeldatenversorgung.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Create a default fully qualified app name.
We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
If release name contains chart name it will be used as a full name.
*/}}
{{- define "titeldatenversorgung.fullname" -}}
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
{{- define "titeldatenversorgung.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Common labels
*/}}
{{- define "titeldatenversorgung.labels" -}}
helm.sh/chart: {{ include "titeldatenversorgung.chart" . }}
{{ include "titeldatenversorgung.selectorLabels" . }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end }}

{{/*
Selector labels
*/}}
{{- define "titeldatenversorgung.selectorLabels" -}}
app.kubernetes.io/name: {{ include "titeldatenversorgung.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}

{{/*
Create the name of the service account to use
*/}}
{{- define "titeldatenversorgung.serviceAccountName" -}}
{{- if .Values.serviceAccount.create }}
{{- default (include "titeldatenversorgung.fullname" .) .Values.serviceAccount.name }}
{{- else }}
{{- default "default" .Values.serviceAccount.name }}
{{- end }}
{{- end }}


{{/*
Get Okapi URL
*/}}
{{- define "titeldatenversorgung.okapiurl" }}
{{- if .Values.okapiurl -}}
{{ .Values.okapiurl }}
{{- else -}}
{{- $okapiport := "9130" }}
{{- $okapihost := "okapi" }}
{{- $okapihttp := "http" }}
{{- range $index, $okapiservice := (lookup "v1" "Service" $.Release.Namespace "").items }}
{{- if eq (get $okapiservice.metadata.labels "app") "okapi" }}
{{- $okapihost = $okapiservice.metadata.name }} 
{{- range $pindex, $port := $okapiservice.spec.ports }}
{{- if eq (get $port "name") "okapi" }}
{{- $okapiport = print (get $port "port") }}
{{- end }}
{{- end }}
{{- end }} 
{{- end }}
{{- printf "%s://%s:%s" $okapihttp $okapihost $okapiport }}
{{- end -}}
{{- end -}}


{{/*
Get Folio Password for titeldatenversorgung
*/}}
{{- define "titeldatenversorgung.foliopassword" -}}
{{- $secret := printf "%s%s" $.Release.Name "-foliouser" }}
{{- $folioPassword := default (randAlphaNum 32) .Values.folio.password }}
{{- if not .Values.folio.password }}
{{- $existingSecret := (lookup "v1" "Secret" .Release.Namespace $secret) }}
{{- if $existingSecret }}
{{- $folioPassword = (index $existingSecret).data.password | b64dec }}
{{- end -}}
{{- end -}}
{{- printf "%s" $folioPassword }}
{{- end }}

