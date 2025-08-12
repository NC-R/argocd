# ArgoCD GitOps Setup – Staging & Kunden-Deployments

Dieses Repository enthält **alle Applikationen (Helm-Charts)** und **die komplette ArgoCD-Konfiguration (Projects, ApplicationSets, Namespaces)** für Staging- und Produktionsumgebungen.

---

## 📦 Repository-Struktur

```

apps/                        # Helm-Charts (eine pro App)
app1/                      # Beispiel-App mit eigenem Image
app2/                      # Beispiel-App hello-openshift

infra/                       # ArgoCD & Cluster-Config
argocd-projects/           # ArgoCD Projects (1 pro App)
customers/                 # Kunden- & Staging-Definition
environments/              # ApplicationSets für Staging & Prod
staging1/
prod/
namespaces/                # Versionierte Namespace-Definitionen
app-of-apps/                # Root-App für ArgoCD

```

---

## 🗺 Architekturübersicht

                                ┌──────────────────────────┐
                                │        ArgoCD Root       │
                                │    (infra/app-of-apps)   │
                                └─────────────┬────────────┘
                                              │
                    ┌─────────────────────────┴─────────────────────────┐
                    │                                                   │
          ┌─────────▼──────────┐                             ┌─────────▼──────────┐
          │   ArgoCD Projects  │                             │  Namespaces (YAML) │
          │ infra/argocd-      │                             │  infra/namespaces  │
          │ projects/*         │                             └─────────┬──────────┘
          └─────────┬──────────┘                                       │
                    │                                                  │
          ┌─────────▼──────────┐                             ┌─────────▼──────────┐
          │  ApplicationSet    │                             │   ApplicationSet   │
          │      Staging       │                             │        Prod        │
          │ infra/environments │                             │ infra/environments │
          │   /staging1/...    │                             │      /prod/...     │
          └─────────┬──────────┘                             └─────────┬──────────┘
                    │                                                  │
          ┌─────────▼──────────┐                             ┌─────────▼──────────┐
          │   staging1-<app>   │                             │    <kunde>-<app>   │
          │  Automated Sync    │                             │     Manual Sync    │
          │   newest-build     │                             │  allow-tags: prod  │
          └─────────┬──────────┘                             └─────────┬──────────┘
                    │                                                  │
          ┌─────────▼──────────┐                             ┌─────────▼──────────┐
          │ Namespace: staging1│                             │ Namespace: kundeX  │
          │  Route: <app>...   │                             │  Route: kundeX...  │
          │ Apps: 1x pro Env   │                             │ Apps: individuell  │
          └────────────────────┘                             └────────────────────┘


---

### Erklärung des Flows:
1. **Root-App** (`infra/app-of-apps/root.yaml`) → deployed alles unter `infra/`
2. **ArgoCD Projects** → ein Project pro App (`app1`, `app2`, …)
3. **Namespaces** → versionierte Definitionen für Staging/Kunden
4. **ApplicationSets** → generieren ArgoCD-Anwendungen für:
   - Staging (automatisch, neuester Build)
   - Prod (manuell, nur `prod` Tag)
5. **Apps** → Helm-Charts unter `apps/` werden je Namespace und Umgebung deployed

---

## 🌍 Architektur

- **Staging**  
  - z. B. `staging1` Namespace
  - Jede App genau **1×** deployed
  - Automatisches Sync & immer neuestes Image (Strategy: `newest-build`)
- **Prod**  
  - Ein Namespace pro Kunde (`kunde1`, `kunde2`, …)
  - Apps frei pro Kunde zuweisbar
  - Manuelles Sync & nur Images mit Tag `prod` (Strategy: `newest-build` + `allow-tags: prod`)
- **Routing**  
  - Staging: `<app>.<staging>.apps.rsn-okd.netcloud.lab`
  - Prod: `<kunde>.<app>.apps.rsn-okd.netcloud.lab`
- **Image Management**  
  - ArgoCD Image Updater für automatisches Update der Image-Tags in Git

---

## 🚀 Deploy-Anleitung

### 1. Root-App in ArgoCD erstellen (einmalig)
1. ArgoCD UI → **NEW APP**
2. Name: `argocd-root`
3. Repo URL: `https://github.com/NC-R/argocd.git`
4. Path: `infra`
5. Revision: `main`
6. Destination: Cluster: `https://kubernetes.default.svc`, Namespace: `argocd`
7. Sync Policy: **Automated** + **Prune** + **Self Heal**

Danach erstellt ArgoCD automatisch:
- Alle ArgoCD Projects
- Alle Namespaces (falls vorhanden)
- Alle ApplicationSets für Staging & Prod

---

### 2. Kunden & Staging-Umgebungen konfigurieren

Bearbeite **`infra/customers/customers.yaml`**:

```yaml
customers:
  - name: kunde1
    namespace: kunde1
    apps:
      - app1
      - app2
  - name: kunde2
    namespace: kunde2
    apps:
      - app1

baseDomain: "apps.rsn-okd.netcloud.lab"

staging:
  - name: staging1
    namespace: staging1
    apps:
      - app1
      - app2
````

Speichern → Commit → Push
→ ApplicationSets passen automatisch die Deployments in ArgoCD an.

---

### 3. Neues App-Chart hinzufügen

1. Ordner unter `apps/<appname>` anlegen
2. Helm-Chart mit `Chart.yaml`, `values.yaml` und Templates erstellen
3. Neues ArgoCD Project unter `infra/argocd-projects/<appname>-project.yaml` hinzufügen
4. App in `customers.yaml` eintragen

---

## 🛠 Wichtige Dateien

| Datei/Ordner                                      | Zweck                               |
| ------------------------------------------------- | ----------------------------------- |
| `apps/app1`                                       | Helm-Chart Beispiel-App             |
| `apps/app2`                                       | Helm-Chart hello-openshift          |
| `infra/customers/customers.yaml`                  | Kunden/Staging-Konfiguration        |
| `infra/environments/staging1/applicationset.yaml` | ApplicationSet für Staging          |
| `infra/environments/prod/applicationset.yaml`     | ApplicationSet für Prod             |
| `infra/argocd-projects`                           | ArgoCD Projects pro App             |
| `infra/namespaces`                                | Versionierte Namespace-Definitionen |
| `infra/app-of-apps/root.yaml`                     | Root-App für ArgoCD                 |

---

## 🔄 Image Updater

### Staging (neuester Build)

```yaml
argocd-image-updater.argoproj.io/image-list: app1=reg.rsn-okd.netcloud.lab:8880/app1/app1
argocd-image-updater.argoproj.io/app1.update-strategy: newest-build
argocd-image-updater.argoproj.io/write-back-method: git:secret:argocd/git-creds
argocd-image-updater.argoproj.io/git-branch: main
```

### Prod (nur `prod` Tag)

```yaml
argocd-image-updater.argoproj.io/image-list: app1=reg.rsn-okd.netcloud.lab:8880/app1/app1
argocd-image-updater.argoproj.io/app1.update-strategy: newest-build
argocd-image-updater.argoproj.io/app1.allow-tags: prod
argocd-image-updater.argoproj.io/write-back-method: git:secret:argocd/git-creds
argocd-image-updater.argoproj.io/git-branch: main
```

---

## 📋 Anforderungen

* ArgoCD & ArgoCD Image Updater installiert
* Zugriff auf Registry `reg.rsn-okd.netcloud.lab:8880`
* Schreibzugriff für `argocd/git-creds` Secret im `argocd` Namespace
* Helm 3.x Charts in `apps/`

---

## 📧 Support

Bei Fragen:

* GitHub Issues im Repo
* Oder direkt im internen DevOps-Channel melden

```
```
