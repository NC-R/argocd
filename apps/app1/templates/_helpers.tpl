{{- define "app1.name" -}}
{{ .Chart.Name }}
{{- end }}

{{- define "app1.fullname" -}}
{{ .Release.Name }}
{{- end }}
