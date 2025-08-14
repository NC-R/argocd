# Kargo on OKD via Argo CD – Files

This bundle contains the minimal files you asked for to install **Kargo** on **OKD** via **Argo CD**.

## Files

1. `kargo-app.yaml` — Argo CD Application that deploys Kargo using the official Helm chart from GHCR.
   - Uses your host: `kargo.apps.rsn-okd.netcloud.lab`
   - Sets admin password hash and token signing key you provided
   - Enables Ingress with self-signed TLS (the OpenShift/OKD router will expose it)

2. (Optional) `kargo-route.yaml` — Use an OpenShift Route instead of Ingress.
   - If you use this, set `api.ingress.enabled: false` in `kargo-app.yaml`.

3. (Optional) `kargo-tls-secret.yaml` — Provide your own TLS cert for the Kargo Ingress.
   - If you use this, set `selfSignedCert: false` and add a `tlsSecret` value in `kargo-app.yaml` under `api.ingress.tls`:
     ```yaml
     api:
       ingress:
         tls:
           selfSignedCert: false
           secretName: kargo-api-ingress-cert
     ```

## Apply

```bash
# Deploy the Argo CD Application
oc apply -f kargo-app.yaml

# (Optional) If you use Route instead of Ingress
# oc apply -f kargo-route.yaml

# (Optional) If you use your own TLS cert for the Ingress
# oc apply -f kargo-tls-secret.yaml
```

## Access

- URL (Ingress): https://kargo.apps.rsn-okd.netcloud.lab
- Initial admin user: `admin`
- Initial admin password (plain text you generated): `NuBEhMgRiWXzqlxsQAzRCHfHnU4WQH7t`

## Notes

- If you prefer Routes, disable Ingress in `kargo-app.yaml` and apply `kargo-route.yaml`.
- For production, consider managing secrets via Sealed Secrets or a secrets manager.
