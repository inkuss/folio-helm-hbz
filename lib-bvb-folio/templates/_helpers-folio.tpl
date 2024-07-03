{{/*
Get Database Host
*/}}
{{- define "folio.dbhostname" -}}
{{- $teamId := "folio" }}
{{- $host := "zal-pg" }}
{{- if .Values.database }}
{{- $teamId := default "folio" .Values.database.teamId }}
{{- $host := default "zal-pg" .Values.database.host }}
{{- end}}
{{- printf "%s-%s" $teamId $host }}
{{- end }}

{{/*
Get Database Name
*/}}
{{- define "folio.dbname" -}}
{{- $defname := "folio" }}
{{- if and .Values.database .Values.database.name }}
{{- $defname := .Values.database.name }}
{{- end }}
{{- printf "%s" $defname }}
{{- end }}

{{/*
Get Okapi URL
*/}}
{{- define "folio.okapiurl" }}
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
{{- if (.Values.global).okapihost }}
{{- $okapihost = .Values.global.okapihost }}
{{- end }}
{{- if (.Values.global).okapiport }}
{{- $okapiport = .Values.global.okapiport }}
{{- end }}
{{- if (.Values.global).okapihttp }}
{{- $okapihttp = .Values.global.okapihttp }}
{{- end }}
{{- printf "%s://%s:%s" $okapihttp $okapihost $okapiport }}
{{- end -}}
