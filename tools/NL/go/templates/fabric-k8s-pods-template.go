package templates

//
func DefaultFabricK8sPodsTemplate() string {
	const template = `{{ range $key, $value := .Organizations }}
{{ range $value}}
{{ $w := . }}
{{ range $i, $_ := N $w.NumCa }}
---
apiVersion: apps/v1
kind: StatefulSet
metadata:
  name: ca{{ $i }}-{{ $w.Name }}
spec:
  selector:
    matchLabels:
      k8s-app: ca{{ $i }}-{{ $w.Name }}
      type: ca
  serviceName: ca{{ $i }}-{{ $w.Name }}
  replicas: 1
  template:
    metadata:
      labels:
        k8s-app: ca{{ $i }}-{{ $w.Name }}
        type: ca
    spec:
      volumes:
        - name: task-pv-storage
          persistentVolumeClaim:
            claimName: fabriccerts
      affinity:
        podAntiAffinity:
          preferredDuringSchedulingIgnoredDuringExecution:
          - weight: 1
            podAffinityTerm:
              labelSelector:
                matchExpressions:
                - key: type
                  operator: In
                  values:
                    - {{ $key }}
              topologyKey: kubernetes.io/hostname
      containers:
        - name: ca{{ $i }}-{{ $w.Name }}
          image: hyperledger/fabric-ca
          imagePullPolicy: Always
          env:
            - { name: "FABRIC_CA_HOME", value: "/etc/hyperledger/fabric-ca-server-config/keyfiles/{{ $w.Name }}/ca" }
            - { name: "FABRIC_CA_SERVER_CA_NAME", value: "ca{{ $i }}-{{ $w.Name }}" }
            - { name: "FABRIC_CA_SERVER_CA_KEYFILE", value: "/etc/hyperledger/fabric-ca-server-config/keyfiles/{{ $w.Name }}/ca/ca_private.key" }
            - { name: "FABRIC_CA_SERVER_CA_CERTFILE", value: "/etc/hyperledger/fabric-ca-server-config/keyfiles/{{ $w.Name }}/ca/ca.{{ $w.Name }}-cert.pem" }
            - { name: "FABRIC_CA_SERVER_TLS_ENABLED", value: "true" }
            - { name: "FABRIC_CA_SERVER_TLS_KEYFILE", value: "/etc/hyperledger/fabric-ca-server-config/keyfiles/{{ $w.Name }}/tlsca/tlsca_private.key" }
            - { name: "FABRIC_CA_SERVER_TLS_CERTFILE", value: "/etc/hyperledger/fabric-ca-server-config/keyfiles/{{ $w.Name }}/tlsca/tlsca.{{ $w.Name }}-cert.pem" }
          resources:
            limits:
                cpu: '0.2'
                memory: 0.5Gi
            requests:
                cpu: '0.2'
                memory: 0.5Gi

          volumeMounts:
            - { mountPath: "/etc/hyperledger/fabric-ca-server-config", name: "task-pv-storage" }
          command: ["fabric-ca-server"]
          args:  ["start", "-b", "admin:adminpw", "-d"]
{{- end }}
{{- if eq $key "peer" }}
{{ range $i, $_ := N $w.NumPeers }}
---
apiVersion: apps/v1
kind: StatefulSet
metadata: 
  name: peer{{ $i }}-{{ $w.Name }}
spec:
  selector:
    matchLabels:
      k8s-app: peer{{ $i }}-{{ $w.Name }}
      type: peer
  serviceName: peer{{ $i }}-{{ $w.Name }}
  replicas: 1
  template:
    metadata:
      labels:
        k8s-app: peer{{ $i }}-{{ $w.Name }}
        type: peer
    spec:
      affinity:
        podAntiAffinity:
          preferredDuringSchedulingIgnoredDuringExecution:
          - weight: 1
            podAffinityTerm:
              labelSelector:
                matchExpressions:
                - key: type
                  operator: In
                  values:
                    - peer
              topologyKey: kubernetes.io/hostname
      volumes:
        - name: task-pv-storage
          persistentVolumeClaim:
            claimName: fabriccerts
        - name: rundind
          hostPath:
            path: /var/run/dind/
      containers:
        - name: couchdb-peer{{ $i }}-{{ $w.Name }}
          image: hfrd/fabric-couchdb:amd64-1.4.1-stable
          imagePullPolicy: Always
          securityContext:
            privileged: true
          resources:
            limits:
                cpu: '0.1'
                memory: 1Gi
            requests:
                cpu: '0.1'
                memory: 1Gi
  
        - name: peer{{ $i }}-{{ $w.Name }}
          image: hyperledger/fabric-peer
          imagePullPolicy: Always
          securityContext:
            privileged: true
          env:
            - { name: "CORE_VM_ENDPOINT", value: "unix:///var/run/docker.sock" }
            - { name: "CORE_PEER_GOSSIP_USELEADERELECTION", value: "True" }
            - { name: "CORE_PEER_GOSSIP_ORGLEADER", value: "false" }
            - { name: "CORE_PEER_LISTENADDRESS", value: "0.0.0.0:7051" }
            - { name: "CORE_PEER_CHAINCODELISTENADDRESS", value: "0.0.0.0:7052" }
            - { name: "CORE_PEER_TLS_ENABLED", value: "true" }
            - { name: "FABRIC_LOGGING_SPEC", value: "error" }
            - { name: "CORE_PEER_TLS_CERT_FILE", value: "/etc/hyperledger/fabric/artifacts/keyfiles/{{ $w.Name }}/peers/peer{{ $i }}-{{ $w.Name }}.{{ $w.Name }}/tls/server.crt" }
            - { name: "CORE_PEER_TLS_KEY_FILE", value: "/etc/hyperledger/fabric/artifacts/keyfiles/{{ $w.Name }}/peers/peer{{ $i }}-{{ $w.Name }}.{{ $w.Name }}/tls/server.key" }
            - { name: "CORE_PEER_TLS_ROOTCERT_FILE", value: "/etc/hyperledger/fabric/artifacts/keyfiles/{{ $w.Name }}/tlsca/tlsca.{{ $w.Name }}-cert.pem" }
            - { name: "CORE_PEER_ID", value: "peer{{ $i }}-{{ $w.Name }}" }
            - { name: "CORE_PEER_GOSSIP_EXTERNALENDPOINT", value: "peer{{ $i }}-{{ $w.Name }}:7051" }
            - { name: "CORE_PEER_ADDRESS", value: "peer{{ $i }}-{{ $w.Name }}:7051" }
            - { name: "CORE_PEER_CHAINCODEADDRESS", value: "peer{{ $i }}-{{ $w.Name }}:7052" }
            - { name: "CORE_PEER_LOCALMSPID", value: "{{ $w.Name }}" }
            - { name: "CORE_PEER_MSPCONFIGPATH", value: "/etc/hyperledger/fabric/artifacts/keyfiles/{{ $w.Name }}/peers/peer{{ $i }}-{{ $w.Name }}.{{ $w.Name }}/msp" }
            - { name: "CORE_LEDGER_STATE_STATEDATABASE", value: "CouchDB" }
            - { name: "CORE_LEDGER_STATE_COUCHDBCONFIG_COUCHDBADDRESS", value: "localhost:5984" }
          volumeMounts:
            - { mountPath: "/etc/hyperledger/fabric/artifacts", name: "task-pv-storage" }
            - { mountPath: "/var/run", name: "rundind" }
          command: ["peer"]
          args: ["node", "start"]
          resources:
            limits:
                cpu: '1'
                memory: 1Gi
            requests:
                cpu: '1'
                memory: 1Gi
{{- end }}
{{- end }}
{{- if eq $key "orderer" }}
{{ range $i, $_ := N $w.NumOrderers }}
---
apiVersion: apps/v1
kind: StatefulSet
metadata:
  name: orderer{{ $i }}-{{ $w.Name }}
spec:
  selector:
    matchLabels:
      k8s-app: orderer{{ $i }}-{{ $w.Name }}
      type: orderer
  serviceName: orderer{{ $i }}-{{ $w.Name }}
  replicas: 1
  template:
    metadata:
      labels:
        k8s-app: orderer{{ $i }}-{{ $w.Name }}
        type: orderer
    spec:
      volumes:
        - name: task-pv-storage
          persistentVolumeClaim:
            claimName: fabriccerts
      affinity:
        podAntiAffinity:
          preferredDuringSchedulingIgnoredDuringExecution:
          - weight: 1
            podAffinityTerm:
              labelSelector:
                matchExpressions:
                - key: type
                  operator: In
                  values:
                    - orderer
              topologyKey: kubernetes.io/hostname
      containers:
        - name: orderer{{ $i }}-{{ $w.Name }}
          image: hyperledger/fabric-orderer
          imagePullPolicy: Always
          env:
            - { name: "ORDERER_GENERAL_LISTENADDRESS", value: "0.0.0.0" }
            - { name: "ORDERER_GENERAL_GENESISMETHOD", value: "file" }
            - { name: "FABRIC_LOGGING_SPEC", value: "error" }
            - { name: "ORDERER_GENERAL_TLS_ENABLED", value: "true" }
            - { name: "ORDERER_GENERAL_GENESISFILE", value: "/etc/hyperledger/fabric/artifacts/keyfiles/genesis.block" }
            - { name: "ORDERER_GENERAL_LOCALMSPID", value: "{{ $w.MspId }}" }
            - { name: "ORDERER_GENERAL_LOCALMSPDIR", value: "/etc/hyperledger/fabric/artifacts/keyfiles/{{ $w.Name }}/orderers/orderer-{{ $w.Name }}.{{ $w.Name }}/msp" }
            - { name: "ORDERER_GENERAL_TLS_SERVERHOSTOVERRIDE", value: "orderer-{{ $w.Name }}" }
            - { name: "ORDERER_GENERAL_TLS_PRIVATEKEY", value: "/etc/hyperledger/fabric/artifacts/keyfiles/{{ $w.Name }}/orderers/orderer-{{ $w.Name }}.{{ $w.Name }}/tls/server.key" }
            - { name: "ORDERER_GENERAL_TLS_CERTIFICATE", value: "/etc/hyperledger/fabric/artifacts/keyfiles/{{ $w.Name }}/orderers/orderer-{{ $w.Name }}.{{ $w.Name }}/tls/server.crt" }
            - { name: "ORDERER_GENERAL_TLS_ROOTCAS", value: "[/etc/hyperledger/fabric/artifacts/keyfiles/{{ $w.Name }}/tlsca/tlsca.{{ $w.Name }}-cert.pem]" }
            - { name: "ORDERER_GENERAL_CLUSTER_CLIENTPRIVATEKEY", value: "/etc/hyperledger/fabric/artifacts/keyfiles/{{ $w.Name }}/orderers/orderer-{{ $w.Name }}.{{ $w.Name }}/tls/server.key" }
            - { name: "ORDERER_GENERAL_CLUSTER_CLIENTCERTIFICATE", value: "/etc/hyperledger/fabric/artifacts/keyfiles/{{ $w.Name }}/orderers/orderer-{{ $w.Name }}.{{ $w.Name }}/tls/server.crt" }
          volumeMounts:
            - { mountPath: "/etc/hyperledger/fabric/artifacts", name: "task-pv-storage" }
          command: ["orderer"]
          resources:
            limits:
                cpu: '1'
                memory: 1Gi
            requests:
                cpu: '1'
                memory: 1Gi
{{- end }}
{{- end }}
{{- end }}
{{- end }}
`
	return template
}
