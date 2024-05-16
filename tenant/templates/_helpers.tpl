{{/* vim: set filetype=mustache: */}}
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

{{/*
Create backend-module name and maybe version as label.
*/}}
{{- define "folio.backend.name-legacy" -}}
{{- printf "%s-%s" .name .version | lower | replace "." "-" | trunc 57 | trimSuffix "-" -}}
{{- end -}}

{{- define "folio.backend.name" -}}
{{- $retVal := .module.name -}}
	{{- if not (eq .shortNames "true") -}}
		{{- $retVal = print $retVal "-" .module.version -}}
	{{- end -}}
{{- printf "%s" $retVal | lower | replace "." "-" | trunc 57 | trimSuffix "-" -}}
{{- end -}}

{{/*
Get Okapi URL
*/}}
{{- define "okapi.url" }}
	{{- $okapiport := $.Values.okapiport | default "9130" }}
	{{- $okapihost := $.Values.okapihost | default "okapi" }}
	{{- $okapihttp := $.Values.okapihttp | default "http" }}
	{{- if not .Values.okapihost }}
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
	{{- end }}
	{{- printf "%s://%s:%s" $okapihttp $okapihost $okapiport }}
{{- end -}}


{{/*
Get Okapi Service/host name
*/}}

{{- define "okapi.host" }}
	{{- $okapihost := $.Values.okapihost | default "okapi" }}
	{{- if not .Values.okapihost }}
		{{- range $index, $okapiservice := (lookup "v1" "Service" $.Release.Namespace "").items }}
			{{- if eq (get $okapiservice.metadata.labels "app") "okapi" }}
				{{- $okapihost = $okapiservice.metadata.name }}
			{{- end }}
		{{- end }}
	{{- end }}
	{{- $okapihost }}
{{- end -}}


{{/*
Get Okapi port
*/}}

{{- define "okapi.port" }}
	{{- $okapiport := $.Values.okapiport | default "9130" }}
	{{- if not .Values.okapihost }}
		{{- range $index, $okapiservice := (lookup "v1" "Service" $.Release.Namespace "").items }}
			{{- if eq (get $okapiservice.metadata.labels "app") "okapi" }}
				{{- range $pindex, $port := $okapiservice.spec.ports }}
					{{- if eq (get $port "name") "okapi" }}
						{{- $okapiport = print (get $port "port") }}
					{{- end }}
				{{- end }}
			{{- end }}
		{{- end }}
	{{- end }}
	{{- $okapiport }}
{{- end -}}


