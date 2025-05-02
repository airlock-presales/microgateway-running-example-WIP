# 🔐 Airlock Microgateway OIDC Example

<p align="left">
  <img src="https://raw.githubusercontent.com/airlock/microgateway/main/media/Microgateway_Labeled_AlignRight.svg" alt="Microgateway Logo" width="250">
</p>

> Extend your secure deployment by integrating **authentication and authorization** via **OIDC (OpenID Connect)**.
---

## 🖼 Architecture Overview

![Topology](media/topology.svg)

**Flow Summary:**
- Requests routed through **Traefik Ingress**
- Services protected via **Airlock Microgateway Gateway API**
- Observability stack (Prometheus, Grafana, Loki)
- Authentication via **Microsoft Entra ID (Azure AD)**

---

## 🌐 Access the Apps

| Path | Description |
|------|-------------|
| `/` | Public |
| `/user` | User role required (Microsoft tenant) |
| `/admin` | Admin role required (Microsoft tenant) |

- webserver Base URL: https://webserver-127-0-0-1.nip.io:8081/

---

## ⚙️ Setup
* Install [Rancher Desktop](https://docs.rancherdesktop.io/getting-started/installation/).

> [!NOTE]
> This example is built for Rancher Desktop with containerd as container engine. Nevertheless, it should also work with any other Kubernetes distributions. Simply ensure the following:
> * Ensure the [Airlock Microgateway requirements](https://docs.airlock.com/microgateway/latest/#data/1660804711882.html) are met.
> * [kubectl](https://kubernetes.io/docs/reference/kubectl/overview/) is installed.
> * [helm](https://helm.sh/docs/intro/install/) is installed.
> * [kustomize](https://kustomize.io) >= 5.2.1 is installed.
> * An Ingress Controller (e.g. Traefik, Ingress Nginx, ...) is deployed.

## Airlock OIDC Microgateway prerequisites
### If one of it is missing, please install it according to the [web protection](../web-protect) example
> * Microgateway with valid license and experimental Gateway API CRDs is deployed 
> * cert-manager is deployed
> * logging, monitoring and reporting stack is deployed

---

## 🛠 Deployment Steps
> [!WARNING]
> Be aware that this is an example and some security settings are disabled to make this demo as simple as possible (e.g. authentication enforcement, restrictive deny rule configuration and other security settings).

## Deploy CA
```bash
kubectl kustomize --enable-helm manifests/ca | k apply --server-side -f -
```

## Deploy Redis
```bash
kubectl kustomize --enable-helm manifests/redis-sessionstore | k apply --server-side -f -
```

## Deploy Webserver
> [!NOTE]
> In this example, all configurations are centralized in the airlock-gateway-auth namespace, making them reusable across multiple applications.
>
> However, this approach also has trade-offs — for example, developers must have write access to the Gateway namespace, which is typically managed by [Cluster Operators](https://gateway-api.sigs.k8s.io).

```bash
kubectl kustomize --enable-helm manifests | kubectl apply --server-side -f -
kubectl -n oidc rollout status deployment webserver
```

 > [!WARNING] 
 > If the Microgateway was already deployed and you switched the Gateway API standard to *experimental* (which is required for this example), you may encounter a 500 error.  
 > To resolve this:  
 > 1. Delete the Microgateway operator pods. They will restart automatically with the new *experimental* Gateway API CRDs.  
 > 2. Then, delete and reapply the `BackendTLSPolicy` manually.  
  
 ```bash
 kubectl delete pod -n airlock-microgateway-system $(kubectl get pods -n airlock-microgateway-system -o name | grep airlock-microgateway-operator-)
 
 kubectl delete -n oidc backendtlspolicies.gateway.networking.k8s.io webserver-tls && kubectl apply -f manifests/webserver-microgateway-config/backendtlspolicy.yaml
 ```


## Authentication with browser
Sidecarless Base URL: https://webserver-127-0-0-1.nip.io:8081/

| Path   | Usage                                                                  |
|--------|------------------------------------------------------------------------|
| /      | Unauthenticated access possible                                        |
| /admin | Authentication required                                                |
| /user  | Authentication required                                                |

## ⚠️ Important Notes
- The limit of Groups in a Token is limited to 200 via OIDC my Microsoft.
- In larger Organisations it can easiely happen that a user may reach this limit.
- To avoid it the Administrator should assign the Application the relevant Group memberships and then just activate just
- Groups assigned to the application (recommended for large enterprise companies to avoid exceeding the limit on the number of groups a token can emit)

---

## 📚 Resources

* [Microgateway manual](https://docs.airlock.com/microgateway/latest/)
  * [Getting Started](https://docs.airlock.com/microgateway/latest/#data/1660804708742.html)
  * [System Architecture](https://docs.airlock.com/microgateway/latest/#data/1660804709650.html)
  * [Installation](https://docs.airlock.com/microgateway/latest/#data/1660804708713.html)
  * [Troubleshooting](https://docs.airlock.com/microgateway/latest/#data/1659430054787.html)
  * [API Reference](https://docs.airlock.com/microgateway/latest/index/api/crds/index.html)
* [Release Repository](https://github.com/airlock/microgateway)
* [Airlock Microgateway labs](https://play.instruqt.com/airlock/invite/hyi9fy4b4jzc?icp_referrer=github.com)

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