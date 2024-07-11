{{/*
Expand the name of the chart.
*/}}
{{- define "vufind.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Create a default fully qualified app name.
We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
If release name contains chart name it will be used as a full name.
*/}}
{{- define "vufind.fullname" -}}
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
{{- define "vufind.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Common labels
*/}}
{{- define "vufind.labels" -}}
helm.sh/chart: {{ include "vufind.chart" . }}
{{ include "vufind.selectorLabels" . }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end }}

{{/*
Selector labels
*/}}
{{- define "vufind.selectorLabels" -}}
app.kubernetes.io/name: {{ include "vufind.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}

{{/*
Create the name of the service account to use
*/}}
{{- define "vufind.serviceAccountName" -}}
{{- if .Values.serviceAccount.create }}
{{- default (include "vufind.fullname" .) .Values.serviceAccount.name }}
{{- else }}
{{- default "default" .Values.serviceAccount.name }}
{{- end }}
{{- end }}


{{/*
Get Database Host name
*/}}
{{- define "vufind.dbhostname" -}}
{{- $teamId := "vufind" }}
{{- $host := "postgres" }}
{{- if .Values.database }}
{{- $teamId := default "vufind" .Values.database.teamId }}
{{- $host := default "postgres" .Values.database.host }}
{{- end}}
{{- printf "%s-%s" $teamId $host }}
{{- end }}

{{/*
Get Database Name
*/}}
{{- define "vufind.dbname" -}}
{{- $defname := "vufind" }}
{{- if and .Values.database .Values.database.name }}
{{ .Values.database.name }}
{{- else }}
{{- printf "%s-%s" "vufind" $.Release.Name }}
{{- end }}
{{- end }}


{{/*
Get or create Database Password
*/}}
{{- define "vufind.dbpassword" -}}
{{- $secret := printf "%s%s" $.Release.Name "-db-secret" }}
{{- $postgresPassword := default (randAlphaNum 32) .Values.database.password | b64enc }}
{{- if not .Values.database.password }}
{{- $existingSecret := (lookup "v1" "Secret" .Release.Namespace $secret) }}
{{- if $existingSecret }}
{{- $postgresPassword = (index $existingSecret).data.password }}
{{- end -}}
{{- end -}}
{{- printf "%s" $postgresPassword }}
{{- end }}


{{/*
Get Database Username
*/}}
{{- define "vufind.dbusername" -}}
{{- $defname := printf "%s%s" "vufind-" $.Release.Name }}
{{- $secret := printf "%s%s" $.Release.Name "-db-secret" }}
{{- $postgresUsername := default $defname .Values.database.username | b64enc }}
{{- if not .Values.database.username }}
{{- $existingSecret := (lookup "v1" "Secret" .Release.Namespace $secret) }}
{{- if $existingSecret }}
{{- $postgresUsername = (index $existingSecret).data.username }}
{{- end -}}
{{- end -}}
{{- printf "%s" $postgresUsername }}
{{- end }}

{{/*
Get Okapi URL
*/}}
{{- define "vufind.okapiurl" }}
{{- $okapiport := "9130" }}
{{- $okapihost := "okapi" }}
{{- $okapihttp := .Values.global.okapihttp | default "http" }}
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
{{- if .Values.global.okapihost }}
{{- $okapihost = .Values.global.okapihost }}
{{- end }}
{{- if .Values.global.okapiport }}
{{- $okapiport = .Values.global.okapiport }}
{{- end }}
{{- printf "%s://%s:%s" $okapihttp $okapihost $okapiport }}
{{- end -}}


{{/*
Get Solr URL
*/}}
{{- define "vufind.solrurl" }}
{{- $solrport := "8983" }}
{{- $solrhost := "solr" }}
{{- $solrhttp := .Values.global.solrhttp | default "http" }}
{{- range $index, $solrservice := (lookup "v1" "Service" $.Release.Namespace "").items }}
{{- if and (get $solrservice.metadata.labels "solr-cloud") (eq (get $solrservice.metadata.labels "service-type") "common") }}
{{- $solrhost = $solrservice.metadata.name }}
{{- $solrport = print (first $solrservice.spec.ports).port }}
{{- end }}
{{- end }}
{{- if .Values.global.solrhost }}
{{- $solrhost = .Values.global.solrhost }}
{{- end }}
{{- if .Values.global.solrport }}
{{- $solrport = .Values.global.solrport }}
{{- end }}
{{- printf "%s://%s:%s/solr" $solrhttp $solrhost $solrport }}
{{- end -}}


{{/*
Get Folio Username for vufind
*/}}
{{- define "vufind.foliousername" -}}
{{- $secret := printf "%s%s" $.Release.Name "-foliouser" }}
{{- $folioUsername := default "vufinduser" .Values.folio.username }}
{{- if not .Values.folio.username }}
{{- $existingSecret := (lookup "v1" "Secret" .Release.Namespace $secret) }}
{{- if $existingSecret }}
{{- $folioUsername = (index $existingSecret).data.username | b64dec }}
{{- end -}}
{{- end -}}
{{- printf "%s" $folioUsername }}
{{- end }}


{{/*
Get Folio Password for vufind
*/}}
{{- define "vufind.foliopassword" -}}
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


{{/*
Get vufind encryption secret
*/}}
{{- define "vufind.encryptionsecret" -}}
{{- $secret := printf "%s%s" $.Release.Name "-encryptionsecret" }}
{{- $encSecret := default (randAlphaNum 32) .Values.encryptionsecret }}
{{- if not .Values.encryptionsecret }}
{{- $existingSecret := (lookup "v1" "Secret" .Release.Namespace $secret) }}
{{- if $existingSecret }}
{{- $encSecret = (index $existingSecret).data.secret | b64dec }}
{{- end -}}
{{- end -}}
{{- printf "%s" $encSecret }}
{{- end }}


{{/*
Get vufind shibboleth entityId
*/}}
{{- define "vufind.shib.entityId" -}}
{{.Values.shibboleth.entityId | default (printf "%s%s%s" "https://" (first .Values.ingress.hosts).host "/shibboleth") }}
{{- end }}