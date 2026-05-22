# Lab 6 — GitLab CI/CD variables checklist

Project: http://10.0.0.10/root/juice-shop-lab → **Settings → CI/CD → Variables**

## Required (pipeline fails without these)

| Variable | Example / notes | Flags |
|----------|-----------------|-------|
| `DEFECTDOJO_TOKEN` | API v2 key from DefectDojo Profile | Masked, Protected |
| `DEFECTDOJO_PRODUCTID` | Numeric ID of Product **OWASP Juice Shop** | Protected |
| `DEPENDENCYTRACK_API_KEY` | From DT → Access Management → API Keys | Masked, Protected |
| `DEPENDENCYTRACK_PROJECT_UUID` | UUID of Juice Shop project in DT | Protected |

## Optional

| Variable | When |
|----------|------|
| `REGISTRY_USER` / `REGISTRY_PASSWORD` | Only if VM-101 registry `localhost:5000` requires auth |
| `RUN_ZAP_FULL` | Set to `true` when manually running **full** ZAP scan |
| `SKIP_SBOM_DT` | `true` — не запускать `sbom-upload-dt` (Lab 6 не нужен DT) |

## Do not set (causes Docker Hub login failure)

| Variable | Why |
|----------|-----|
| `CI_REGISTRY` override pointing at Docker Hub | `build_app` uses `COURSE_REGISTRY=localhost:5000` in YAML |

## Lab 6 jobs on `main` push

1. `defectdojo-init` → Engagement **Lab6 CI &lt;pipeline_id&gt;**
2. `build_app` → push `10.0.0.11:5000/juice-shop-lab/app:&lt;sha&gt;` (tracked `build/routes/*.js` required)
3. `zap_baseline` → pull **`localhost:5000/juice-shop-lab/app:&lt;sha&gt;`** → artifacts `baseline.*`
4. `defectdojo-import-zap` → import `baseline.xml` (skips `full.xml` if absent)

## Troubleshooting

| Symptom | Fix |
|---------|-----|
| `registry-1.docker.io` unauthorized | Remove wrong `CI_REGISTRY` vars; use commit with `COURSE_REGISTRY` fix |
| В логе `Checking out cc68b089` / `Starting service docker:24-dind` | Это **старый** pipeline — не Retry. Запусти pipeline для **последнего** коммита на `main` |
| `mount: permission denied` / dind 2375 | Runner без privileged — в актуальном YAML **Kaniko**, `services: []`, без dind |
| `HTTP response to HTTPS client` при pull `10.0.0.11:5000` | Runner тянет service по HTTPS — в YAML `APP_IMAGE=localhost:5000/...`, push остаётся на `10.0.0.11:5000` |
| Kaniko не тянет gcr.io | `lab6/push-app-to-registry.ps1` с ПК, затем Retry `zap_baseline` |
| `sbom-upload-dt` HTTP 401 | Новый ключ: `ci/DT_API_KEY_SETUP.md`; после fix CI job при 401 выходит **0** (WARN), Lab 6 OK |
| `Cannot connect to Docker daemon` | Retry; не добавлять `CI_REGISTRY_*` |
| `build_app` dind timeout | Retry pipeline; ensure runner `shared` on VM-101 is online |
| `sbom-upload-dt` HTTP 401 | Regenerate `DEPENDENCYTRACK_API_KEY` (job is `allow_failure` — does not block ZAP) |
| ZAP "target not reachable" | Check `build_app` green and `APP_IMAGE` push line in log |
| No `full.xml` in DefectDojo | Run pipeline with `RUN_ZAP_FULL=true` |
