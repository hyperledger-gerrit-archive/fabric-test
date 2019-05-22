package templates

func DefaultCryptoConfigTemplate() string {
	const template = `---{{ $w := . }}
OrdererOrgs: {{ range .OrdererOrganizations }}
  - Name: {{ .Name }}
    Domain: {{ .Name }}
    EnableNodeOUs: true {{ $orgName := .Name}}
    Specs: {{ range $key, $value := $w.OrdererHosts }}{{ range $value }}
    {{- if eq $key $orgName }}
      - Hostname: {{ . }}
    {{- end }}
		{{- end }}
    {{- end }}	
{{- end }}
PeerOrgs: {{ range .PeerOrganizations }}
  - Name: {{ .Name }}
    Domain: {{ .Name }}
    EnableNodeOUs: true {{ $orgName := .Name}}
    Specs: {{ range $key, $value := $w.PeerHosts }}{{ range $value }}
    {{- if eq $key $orgName }}
      - Hostname: {{ . }}
    {{- end }}
    {{- end }}
    {{- end }}	
{{- end }}
  `
	return template
}
