# 🛡️ Airlock Microgateway Tracing Example

<p align="left">
  <img src="https://raw.githubusercontent.com/airlock/microgateway/main/media/Microgateway_Labeled_AlignRight.svg" alt="Microgateway Logo" width="250">
</p>

This example demonstrates how to integrate Airlock Microgateway with OpenTelemetry to trace requests flowing through the gateway down to the backing microservices.

---

## 🖼 Architecture Overview

**Key Components:**

- **Gateway API** for routing traffic.
- **Airlock Microgateway** for routing and securing traffic while generating and propagating OpenTelemetry distributed traces.
- **Podinfo** as the backend demonstration application, instrumented to report traces.
- **Tempo / Loki / Alloy** for trace collection and log streaming.
- **Prometheus + Grafana** for metrics and trace visualization.

---

## 🌐 Application Access

| Application | URL |
|------------|-----|
| Podinfo | [http://tracing-demo-127-0-0-1.nip.io/](http://tracing-demo-127-0-0-1.nip.io/) |
| Grafana | [http://grafana-127-0-0-1.nip.io](http://grafana-127-0-0-1.nip.io) |

---

## ⚙️ Setup

Before continuing, make sure your environment is prepared by following the instructions in the [General Kubernetes Setup](../README-k8s.md) or [General OpenShift Setup](../README-openshift.md).  
This includes installing required tools, deploying observability components (including Tempo/Alloy for tracing), and the Airlock Microgateway itself.

## 🛠 Deploy the examples:

### Deploy Podinfo

Deploy the `podinfo` application which includes the Airlock Microgateway HTTPRoute and its specific tracing configurations:

```bash {"cwd":"../"}
# Deploy Podinfo
kubectl kustomize --enable-helm manifests/podinfo | kubectl apply --server-side -f -

# Wait until Podinfo is up and running
kubectl -n trace-demo rollout status deployment podinfo
```

> [!NOTE]
> You can now access the Podinfo web application via http://tracing-demo-127-0-0-1.nip.io

## 🔍 Investigate Traces in Grafana

1. Open your browser and generate some traffic by navigating to [http://tracing-demo-127-0-0-1.nip.io](http://tracing-demo-127-0-0-1.nip.io).
2. Access your Grafana instance (deployed in the generic setup).
3. Open the **Explore** tab.
4. Select **Tempo** as the data source.
5. In the search query, look for traces from `airlock-gateway` or `podinfo`.
6. Click on a trace ID to view the waterfall diagram. You will see how the `traceparent` context is propagated from Airlock Microgateway (showing internal WAAP processing spans) to the Podinfo backend service.

---

## 📚 Resources

* [Microgateway manual](https://docs.airlock.com/microgateway/latest/)

   * [Getting Started](https://docs.airlock.com/microgateway/latest/#data/1660804708742.html)
   * [System Architecture](https://docs.airlock.com/microgateway/latest/#data/1660804709650.html)
   * [Installation](https://docs.airlock.com/microgateway/latest/#data/1660804708713.html)
   * [Observability & Tracing](https://docs.airlock.com/microgateway/latest/index/1725073468781.html)
   * [API Reference](https://docs.airlock.com/microgateway/latest/index/api/crds/index.html)

* [Release Repository](https://github.com/airlock/microgateway)
* [Airlock Microgateway labs](https://airlock.instruqt.com/pages/airlock-microgateway-labs)

## ⚖️ License

<details>
<summary>License details</summary>

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
