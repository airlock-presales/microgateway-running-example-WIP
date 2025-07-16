# 🛡️ Airlock Microgateway Web Protection Example

<p align="left">
  <img src="https://raw.githubusercontent.com/airlock/microgateway/main/media/Microgateway_Labeled_AlignRight.svg" alt="Microgateway Logo" width="250">
</p>

This example demonstrates how to secure web applications in Kubernetes using Airlock Microgateway.

---

## 🖼 Architecture Overview

![Topology Diagram](media/topology.svg)

**Key Components:**
- **Ingress Controller (Traefik)** for routing
- **Airlock Microgateway**:
  - Sidecar data plane mode for Nextcloud
  - Sidecarless data plane mode (Gateway API) for Juice Shop
- **Prometheus + Grafana** for metrics
- **Loki + Promtail** for logging

---

## 🌐 Application Access

| Application | URL |
|------------|-----|
| Grafana | [http://grafana-127-0-0-1.nip.io/](http://grafana-127-0-0-1.nip.io/) |
| Prometheus | [http://prometheus-127-0-0-1.nip.io/](http://prometheus-127-0-0-1.nip.io/) |

---

## ⚙️ Setup


> [!WARNING]
> Be aware that this is an example and some security settings are disabled to make this demo as simple as possible (e.g. authentication enforcement, restrictive deny rule configuration and other security settings).

## General prerequisites
* Install [Rancher Desktop](https://docs.rancherdesktop.io/getting-started/installation/).

> [!NOTE]
> This example is built for Rancher Desktop with containerd as container engine. Nevertheless, it should also work with any other Kubernetes distributions. Simply ensure the following:
> * Ensure the [Airlock Microgateway requirements](https://docs.airlock.com/microgateway/latest/#data/1660804711882.html) are met.
> * [kubectl](https://kubernetes.io/docs/reference/kubectl/overview/) is installed.
> * [helm](https://helm.sh/docs/intro/install/) is installed.
> * [kustomize](https://kustomize.io) >= 5.2.1 is installed.
> * An Ingress Controller (e.g. Traefik, Ingress Nginx, ...) is deployed.

## 🛠 Deployment Steps

### Obtain and deploy the Airlock Microgateway license
1. Either request a community license free of charge or purchase a premium license.
   * Community license: [airlock.com/microgateway-community](https://airlock.com/en/microgateway-community)
   * Premium license: [airlock.com/microgateway-premium](https://airlock.com/en/microgateway-premium)
2. Check your mailbox and save the license file `microgateway-license.txt` locally (replace any existing file).
3. Deploy the Airlock Microgateway license
```bash
# Create the airlock-microgateway-system namespace
kubectl create ns airlock-microgateway-system --dry-run=client -o yaml | kubectl apply -f -

# Deploy the Airlock Microgateway license
kubectl -n airlock-microgateway-system create secret generic airlock-microgateway-license --from-file=microgateway-license.txt --dry-run=client -o yaml | kubectl apply -f -
```

> [!NOTE]
> See [Community vs. Premium editions in detail](https://docs.airlock.com/microgateway/latest/#data/1675772882054.html) to choose the right license type.

## Deploy the needed components

### Deploy the cert-manager
For an easy start in non-production environments, you may deploy the same [cert-manager](https://cert-manager.io/) we are using internally for testing.
```bash
# Deploy the cert-manager
kubectl kustomize --enable-helm manifests/cert-manager | kubectl apply --server-side -f -

# Wait until the cert-manager is up and running
kubectl -n cert-manager rollout status deployment
```

### Deploy the logging, monitoring and reporting  stack
```bash
# Deploy Promtail, Loki, Prometheus and Grafana
kubectl kustomize --enable-helm manifests/logging-and-reporting | kubectl apply --server-side -f -

# Wait until Promtail, Loki, Prometheus and Grafana are up and running
kubectl -n monitoring rollout status deployment,daemonset,statefulset
```

> [!NOTE]
> You can now access
> * Prometheus via http://prometheus-127-0-0-1.nip.io/
> * Grafana via http://grafana-127-0-0-1.nip.io/

## Deploy CA
```bash
kubectl kustomize --enable-helm manifests/ca | kubectl apply --server-side -f -
```

## Deploy Redis (Sessionstore)
```bash
kubectl kustomize --enable-helm manifests/redis-sessionstore | kubectl apply --server-side -f -
```

### Deploy Airlock Microgateway
> [!TIP]
> Certain environments such as OpenShift or GKE require non-default configurations when installing the CNI plugin. In case that the CNI plugin does not start properly consult [Troubleshooting Microgateway CNI](https://docs.airlock.com/microgateway/latest/#data/1710781909882.html).

> [!NOTE]
> In case this example is not deployed in Rancher Desktop, most likely the `cniBinDir`and `cniNetDir`in the file `manifests/airlock-microgateway/microgateway-cni-values.yaml` must be adjusted.
> Example:
> ```
> config:
>   cniBinDir: "/usr/libexec/cni/"
>   cniNetDir: "/etc/cni/net.d"
> ```

```bash
# Deploy Airlock Microgateway including the CNI plugin
kubectl kustomize --enable-helm manifests/airlock-microgateway | kubectl apply -f -

# Wait until Airlock Microgateway is up and running
kubectl -n kube-system rollout status daemonset airlock-microgateway-microgateway-cni
kubectl -n airlock-microgateway-system rollout status deployment
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
