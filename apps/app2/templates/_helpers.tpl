{{- define "app2.name" -}}
{{ .Chart.Name }}
{{- end }}

{{- define "app2.fullname" -}}
{{ .Release.Name }}
{{- end }}
