# Lab 6 — push patched image to course registry (fallback if CI build_app fails)
# Tag MUST match $CI_COMMIT_SHORT_SHA so zap_baseline can pull APP_IMAGE.
# Usage: .\lab6\push-app-to-registry.ps1
#        .\lab6\push-app-to-registry.ps1 -Tag 0a6b91496

param([string]$Tag = (git rev-parse --short HEAD 2>$null))
if (-not $Tag) { $Tag = "lab6-patched" }

$ErrorActionPreference = "Stop"
# Push to course registry (from PC use 10.0.0.11; CI ZAP pulls localhost:5000 on runner — same registry)
$registry = "10.0.0.11:5000"
$image = "$registry/juice-shop-lab/app:$Tag"
Write-Host "After push, GitLab ZAP uses localhost:5000/juice-shop-lab/app:$Tag on registry-runner"

Write-Host "Building juice-shop:lab6..."
docker pull bkimminich/juice-shop:v17.0.0
docker build -f lab6/Dockerfile.patched -t juice-shop:lab6 .
docker tag juice-shop:lab6 $image
Write-Host "Pushing $image ..."
docker push $image
Write-Host "Done. In GitLab CI set APP_IMAGE or use tag lab6-patched for ZAP."
