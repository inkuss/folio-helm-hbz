{{/*
Get Database Host name - the service name for the database will be the same
*/}}
{{- define "vufind.dbhostname" -}}
{{- $teamId := "vufind" }}
{{- $host := "postgres" }}
{{- if and .Values.global .Values.global.vufinddb }}
{{- $teamId := default "vufind" .Values.global.vufinddb.teamId }}
{{- $host := default "postgres" .Values.global.vufinddb.host }}
{{- end}}
{{- printf "%s-%s" $teamId $host }}
{{- end }}

{{/*
Get Database Admin secret name
*/}}
{{- define "vufind.dbadminsecret" -}}
{{- $name := "postgresAdminSecret" }}
{{- if and .Values.global .Values.global.vufinddb }}
{{- $name := default "postgresAdminSecret" .Values.global.vufinddb.adminSecret }}
{{- end}}
{{- printf "%s" $name }}
{{- end }}