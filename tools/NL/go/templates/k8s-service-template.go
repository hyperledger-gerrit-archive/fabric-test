package templates

func DufaultK8sServiceTemplate() string {
	const template = `{{ range .PeerOrganizations }}
{{ $w := .}}
{{ range $i, $_ := N $w.NumCa }}
---
kind: Service
appVersion: v1
metadata:
  labels:
    k8s-app: ca{{ $i }}-{{ $w.Name }}
  name: ca{{ $i }}-{{ $w.Name }}
spec:
  selector:
    k8s-app: ca{{ $i }}-{{ $w.Name }}
  ports:
    - name: port1
      port: 7054 
{{- end }}
{{ range $i, $_ := N $w.NumPeers }}
---
kind: Service
appVersion: v1
metadata:
  labels:
    k8s-app: peer{{ $i }}-{{ $w.Name }}
  name: peer{{ $i }}-{{ $w.Name }}
spec:
  selector:
    k8s-app: peer{{ $i }}-{{ $w.Name }}
  ports:
    - name: port1
      port: 7051
    - name: port2
      port: 7052 
{{- end }}
{{- end }}

{{ range .OrdererOrganizations }}
{{ $w := .}}
{{ range $i, $_ := N $w.NumCa }}
---
kind: Service
appVersion: v1
metadata:
  labels:
    k8s-app: ca{{ $i }}-{{ $w.Name }}
  name: ca{{ $i }}-{{ $w.Name }}
spec:
  selector:
    k8s-app: ca{{ $i }}-{{ $w.Name }}
  ports:
    - name: port1
      port: 7054 
{{- end }}
{{ range $i, $_ := N $w.NumOrderers }}
---
kind: Service
appVersion: v1
metadata:
  labels:
    k8s-app: orderer{{ $i }}-{{ $w.Name }}
  name: orderer{{ $i }}-{{ $w.Name }}
spec:
  selector:
    k8s-app: orderer{{ $i }}-{{ $w.Name }}
  ports:
    - name: port1
      port: 7050
{{- end }}
{{- end }}`
	return template
}
