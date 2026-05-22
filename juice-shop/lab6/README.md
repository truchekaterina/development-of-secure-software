# Lab 6 — local verification

## Patched app on port 3001 (fast Docker build)

Full `docker build .` needs ~20+ min and much RAM. Use the overlay image instead:

```powershell
cd C:\Users\1\Desktop\neurohelp\Development_of_secure_software\juice-shop

# Ensure patched JS exists (from repo or: npx tsc --types node  after npm install)
docker pull bkimminich/juice-shop:v17.0.0
docker build -f lab6/Dockerfile.patched -t juice-shop:lab6 .

docker stop juice-shop-patched 2>$null; docker rm juice-shop-patched 2>$null
docker run -d -p 127.0.0.1:3001:3000 --name juice-shop-patched juice-shop:lab6

.\lab6\verify-after.ps1
```

## Vulnerable app on port 3000 (optional, for "before")

```powershell
docker run -d -p 127.0.0.1:3000:3000 --name juice-shop bkimminich/juice-shop:v17.0.0
```

## GitLab CI (`build_app`)

Job `build_app` builds the same patched overlay image as local testing — **not** the root `Dockerfile`:

- `docker pull bkimminich/juice-shop:v17.0.0` (base layer; avoids opaque dind fetch failures)
- `docker build -f lab6/Dockerfile.patched -t "$APP_IMAGE" .`
- `docker push "$APP_IMAGE"`

Registry variables (defined in `.gitlab-ci.yml`, not GitLab Container Registry / Docker Hub):

| Variable | Value / purpose |
|----------|-----------------|
| `COURSE_REGISTRY` | `10.0.0.11:5000` — course registry on VM-101 |
| `APP_IMAGE` | `10.0.0.11:5000/juice-shop-lab/app:$CI_COMMIT_SHORT_SHA` |
| `REGISTRY_USER` | Optional CI/CD variable — set only if the course registry requires auth |
| `REGISTRY_PASSWORD` | Optional CI/CD variable — paired with `REGISTRY_USER` |

When `REGISTRY_USER` and `REGISTRY_PASSWORD` are unset, the job pushes to the insecure course registry without login (no `registry-1.docker.io` login). ZAP jobs consume `$APP_IMAGE` as the scan target service.

**CI build:** `build_app` uses **Kaniko** (`gcr.io/kaniko-project/executor`), `services: []` — no `docker:dind`. Do not **Retry** old failed jobs (they use old commits). Manual fallback: `lab6/push-app-to-registry.ps1`.
