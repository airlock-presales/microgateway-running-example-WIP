# ⚙️ Airlock Microgateway General OpenShift Setup

<p align="left">
  <img src="https://raw.githubusercontent.com/airlock/microgateway/main/media/Microgateway_Labeled_AlignRight.svg" alt="Microgateway Logo" width="250">
</p>

This guide provides the foundational setup required for running Airlock Microgateway examples within the Red Hat OpenShift environment. It includes all general steps like licensing, infrastructure setup, logging, monitoring, and installing the Microgateway.

---

## 🖼️ Architecture Overview
> ⚠️ This setup is created based on **Red Hat OpenShift Local 4.19**

**Core Components:**
- **Airlock Microgateway** – Data plane security
- **Prometheus & Grafana** – Metrics and dashboards
- **Loki & Grafana-Agent** – Log aggregation and analysis
- **LokiStack & Red Hat Cluster Logging** - Log aggregation and analysis ***Red Hat Supported**

---

### Airlock Microgateway Requirements
- Review and fulfill all [Airlock Microgateway prerequisites](https://docs.airlock.com/microgateway/latest/#data/1660804711882.html)

---

## 🛡️ Install License

 📝 You must obtain a valid license before continuing:
 - **Community License**: [airlock.com/microgateway-community](https://airlock.com/en/microgateway-community)
 - **Premium License**: [airlock.com/microgateway-premium](https://airlock.com/en/microgateway-premium)
 - 📘 [Community vs. Premium Comparison](https://docs.airlock.com/microgateway/latest/#data/1675772882054.html)

### Deploy the License
```bash
oc create ns airlock-microgateway-system --dry-run=client -o yaml | oc apply -f -

oc -n airlock-microgateway-system create secret generic airlock-microgateway-license --from-file=microgateway-license.txt --dry-run=client -o yaml | oc apply -f -
```

## 🗃️ Deploy Cert-Manager Operator for Red Hat OpenShift via OperatorHub
Keep the recommended namespace **cert-manager-operator** during install.

## 🗄️📜 Deploy Certificate Authority (CA)
```bash
oc kustomize --enable-helm manifests/ca | oc apply --server-side -f -
```

## 🔐 Deploy Redis (Session Store)
```bash
oc kustomize --enable-helm manifests/redis-sessionstore | oc apply --server-side -f -

# Wait until the Redis is up and running
oc -n redis rollout status deployment
```

## 📊 Deploy Logging and Monitoring Stack

```bash
oc kustomize --enable-helm manifests/logging-and-reporting | oc apply --server-side -f -

# Wait until Grafana is up and running
oc -n monitoring rollout status deployment
```

### Create the binding and tokens to access Promethues via Thanos
```bash
oc adm policy add-cluster-role-to-user cluster-monitoring-view \
  -z grafana \
  -n monitoring
oc create token grafana -n monitoring --duration=87600h > grafana-token.txt #valid for 10 years

cat grafana-token.txt 
```

### Replace the wrong token with your own Token and reapply Grafana
```bash
oc kustomize --enable-helm manifests/logging-and-reporting/grafana | oc apply --server-side -f -
```

> [!NOTE]
> You can now access
> * Grafana via http://grafana-127-0-0-1.nip.io/

### Install Loki communiti edition via Operator Hub (from opdev) in namespace monitoring
Open Loki via installed Operator and apply the following config.

<details>
<summary>Loki Community config</summary>

```yaml
apiVersion: charts.example.com/v1alpha1
kind: Loki
metadata:
  name: loki-sample
  namespace: monitoring
  annotations:
    helm.sdk.operatorframework.io/install-disable-crds: 'true'
spec:
  global:
    clusterDomain: cluster.local
    dnsService: dns-default
    dnsNamespace: openshift-dns

  rbac:
    sccEnabled: true

  loki:
    auth_enabled: false
    commonConfig:
      replication_factor: 1
    storage:
      type: filesystem

  singleBinary:
    replicas: 1

  monitoring:
    dashboards:
      enabled: false
    servicemonitor:
      enabled: true
    lokiCanary:
      enabled: false
    rules:
      enabled: false
      alerting: false
    selfMonitoring:
      enabled: false
      grafanaAgent:
        installOperator: false

  test:
    enabled: false
```

Apply also the RBAC to grant Loki access:
```bash
kubectl kustomize --enable-helm manifests/logging-and-reporting/loki-community | kubectl apply --server-side -f -
```

</details>

### Install grafana-agent
```bash
kubectl kustomize --enable-helm manifests/logging-and-reporting/grafana-agent/ | kubectl apply --server-side -f -

oc adm policy add-scc-to-user privileged -z alloy-agent -n monitoring
```

<details>
<summary>Install minIO (Optional)</summary>

### Install minIO if you have no valid storage for Loki-Stack

> ⚠️ Please be aware of the minIO license which is maybe needed

```bash
oc kustomize --enable-helm manifests/logging-and-reporting/minio | oc apply --server-side -f -
```
Now create the bucket for Loki called loki
You can do it via minIO CLI (MC) of using the GUI of minIO which is active in this example, but not recommended.
Activate Port Forwading to gain access
```bash
oc -n minio port-forward svc/minio 9000:9000
```
Now you can access minIO GUI via your browser Open http://s3.airlock.local:9000 (make sure you have an valid DNS record)
Default user and password is minioadmin/minioadmin
</details>

<details>
<summary>Loki-Stack by RedHat (under construction)</summary>

### Install Loki Operator provided by Red Hat via OperatorHub *Untested

Keep the recommended default openshift-operators-redhat

In to be able to use LokiStack, we first have to create a secret for Loki to access minIO
```bash
oc kustomize --enable-helm manifests/logging-and-reporting/loki | oc apply --server-side -f -
```

### Create a token a for communication:
echo -n "supersecretlokitoken" > token
oc create secret generic my-loki-token \
  --from-file=token=token \
  -n openshift-logging

### Create Tenant Mapping Secret for Loki Gateway
```bash
oc apply -f manifests/logging-and-reporting/loki/loki-gateway-tenants-secret.yaml
```


Step-by-Step to Create a LokiStack
1. In the OpenShift Web Console:
Go to Operators > Installed Operators

Click on Loki Operator

Click on the LokiStack tab

Click Create LokiStack

2. Fill in the Fields:

<details>
<summary>example yaml:</summary>

```yaml
apiVersion: loki.grafana.com/v1
kind: LokiStack
metadata:
  name: logging-loki
  namespace: openshift-logging
  annotations:
    loki.grafana.com/gateway-tenant-secret-name: loki-gateway-tenants
spec:
  tenants:
    mode: static
  managementState: Managed
  limits:
    global:
      queries:
        queryTimeout: 3m
  storage:
    schemas:
      - effectiveDate: '2025-07-30'
        version: v13
    secret:eval $(crc oc-env)
      name: minio-loki-secret
      type: s3
      credentialMode: static
  hashRing:
    type: memberlist
  size: 1x.demo
  storageClassName: crc-csi-hostpath-provisioner

```
</details>
</details>

<details>
<summary>RedHat OpenShift Logging Operator (under construction)</summary>

### Install Red Hat OpenShift Logging Operator via OperatorHub *Untested

> ⚠️ Does not work without public signed certificate used in Loki Stack until skip TLS verify for Loki Stack or [RFE-2723](https://issues.redhat.com/browse/RFE-2723) is implemented


Keep the recommended default openshift-logging
and point the LogForwarder to loki which is the source in Grafana

```bash
oc kustomize --enable-helm manifests/logging-and-reporting/redhat-logger | oc apply --server-side -f -
```
Create ServiceAccount & Bind Roles:
```bash
oc create sa collector -n openshift-logging
oc adm policy add-cluster-role-to-user collect-application-logs system:serviceaccount:openshift-logging:collector
oc adm policy add-cluster-role-to-user collect-infrastructure-logs system:serviceaccount:openshift-logging:collector
oc adm policy add-cluster-role-to-user collect-audit-logs system:serviceaccount:openshift-logging:collector
oc adm policy add-cluster-role-to-user logging-collector-logs-writer system:serviceaccount:openshift-logging:collector -n openshift-logging
oc adm policy add-cluster-role-to-user loki-application-logs -z collector -n openshift-logging
```
oc create sa collector -n openshift-logging
oc adm policy add-cluster-role-to-user logging-collector-logs-writer -z collector -n openshift-logging
oc adm policy add-cluster-role-to-user collect-application-logs system:serviceaccount:openshift-logging:collector
oc adm policy add-cluster-role-to-user collect-infrastructure-logs system:serviceaccount:openshift-logging:collector
oc adm policy add-cluster-role-to-user collect-audit-logs system:serviceaccount:openshift-logging:collector


#### Step-by-Step to Create a ClusterLogForwarder
1. In the OpenShift Web Console:
Go to Operators > Installed Operators

Click on Red Hat OpenShift Logging Operator

Click on the Cluster Log Forwarder tab

Click Create ClusterLogForwarder

```yaml
apiVersion: observability.openshift.io/v1
kind: ClusterLogForwarder
metadata:
  name: logging-collector
  namespace: openshift-logging
spec:
  serviceAccount:
    name: collector
  outputs:
    - name: my-loki
      type: loki
      loki:
        url: https://logging-loki-gateway-http.openshift-logging.svc:8080/api/logs/v1/openshift-logging
        tenantKey: __tenant_id__
      tls:
        ca:
          secretName: my-loki-ca
          key: ca-bundle.crt
        insecureSkipVerify: true
  pipelines:
    - name: forward-all
      inputRefs:
        - application
        - infrastructure
        - audit
      outputRefs:
        - my-loki
```

Normal Loki community edition:
```yaml
apiVersion: observability.openshift.io/v1
kind: ClusterLogForwarder
metadata:
  name: logging-collector
  namespace: openshift-logging
spec:
  serviceAccount:
    name: collector
  outputs:
    - name: my-loki
      type: loki
      loki:
        url: http://loki-gateway.monitoring.svc:80/loki/api/v1/push
  pipelines:
    - name: forward-all
      inputRefs:
        - application
        - infrastructure
        - audit
      outputRefs:
        - my-loki
```
</details>

## 🚀 Install Airlock Microgateway via OperatorHub

> ⚠️ Warning
> Starting in OpenShift Container Platform 4.19, the Ingress Operator manages the lifecycle of any Gateway API custom resource definitions (CRDs). This means that you will be denied access to creating, updating, and deleting any CRDs within the API groups that are grouped under Gateway API.

If you have an OpenShift version <= 4.18 please uncomment the installation of the GatewayAPI CRDs or install it manually.

<details>
<summary>Install GatewayAPI manual CRD installation</summary>

```bash
oc apply -f https://github.com/kubernetes-sigs/gateway-api/releases/download/v1.3.0/standard-install.yaml
oc apply -f https://github.com/kubernetes-sigs/gateway-api/releases/download/v1.3.0/experimental-install.yaml # For backendTLS support e.g. OIDC example
```

</details>

### Airlock Microgateway configure the after it was installed via OperatorHub
```bash
oc kustomize --enable-helm manifests/airlock-microgateway | oc apply -f -


Activate the Podmonitor, by editing the subscription of the Airlock operator:
spec:
  config:
    env:
      - name: GATEWAY_API_POD_MONITOR_CREATE
        value: "true"
```

---

## 📚 Resources

* [Microgateway manual](https://docs.airlock.com/microgateway/latest/)
  * [Getting Started](https://docs.airlock.com/microgateway/latest/#data/1660804708742.html)
  * [System Architecture](https://docs.airlock.com/microgateway/latest/#data/1660804709650.html)
  * [Installation](https://docs.airlock.com/microgateway/latest/#data/1660804708713.html)
  * [Troubleshooting](https://docs.airlock.com/microgateway/latest/#data/1659430054787.html)
  * [API Reference](https://docs.airlock.com/microgateway/latest/index/api/crds/index.html)
* [Release Repository](https://github.com/airlock/microgateway)
* [Airlock Microgateway labs](https://airlock.instruqt.com/pages/airlock-microgateway-labs)

## ⚖️ License
View the [detailed license terms](https://www.airlock.com/en/airlock-license) for the software contained in this image.
* Decompiling or reverse engineering is not permitted.
* Using any of the deny rules or parts of these filter patterns outside of the image is not permitted.

</details>
<br>

Airlock<sup>&#174;</sup> is a security innovation by [ergon](https://www.ergon.ch/en)

<!-- Airlock SAH Logo (different image for light/dark mode) -->
<a href="https://www.airlock.com/en/secure-access-hub/">
<picture>
    <source media="(prefers-color-scheme: dark)"
        srcset="https://raw.githubusercontent.com/airlock/microgateway/main/media/Airlock_Logo_Negative.png">
    <source media="(prefers-color-scheme: light)"
        srcset="https://raw.githubusercontent.com/airlock/microgateway/main/media/Airlock_Logo.png">
    <img alt="Airlock Secure Access Hub" src="https://raw.githubusercontent.com/airlock/microgateway/main/media/Airlock_Logo.png" width="150">
</picture>
</a>
