# Локальный прогон Semgrep (лаб. №5) — из каталога juice-shop/
param(
    [ValidateSet('before', 'after')]
    [string]$Phase = 'before'
)

$ErrorActionPreference = 'Stop'
$ReportDir = 'semgrep/reports'
New-Item -ItemType Directory -Force -Path $ReportDir | Out-Null

$json = "$ReportDir/report-$Phase.json"
$sarif = "$ReportDir/report-$Phase.sarif"
$log = "$ReportDir/scan-$Phase.log"

$sw = [System.Diagnostics.Stopwatch]::StartNew()
$prevEap = $ErrorActionPreference
$ErrorActionPreference = 'Continue'
try {
    docker run --rm `
        -v "${PWD}:/src" `
        -w /src `
        returntocorp/semgrep:1.95.0 `
        semgrep scan `
        --config semgrep/rules/language `
        --config semgrep/rules/owasp `
        --config semgrep/rules/stack `
        --config semgrep/rules/custom `
        --json --output $json `
        --sarif-output $sarif `
        --metrics=off `
        --no-rewrite-rule-ids `
        --verbose `
        . 2>&1 | Tee-Object -FilePath $log
    if ($LASTEXITCODE -ne 0) {
        throw "semgrep scan failed with exit code $LASTEXITCODE"
    }
} finally {
    $ErrorActionPreference = $prevEap
}
$sw.Stop()
"ELAPSED_SEC=$($sw.Elapsed.TotalSeconds)" | Add-Content $log
$prevEap2 = $ErrorActionPreference
$ErrorActionPreference = 'Continue'
docker run --rm -v "${PWD}:/src" -w /src returntocorp/semgrep:1.95.0 semgrep --version 2>&1 | Add-Content $log
$ErrorActionPreference = $prevEap2
Write-Host "Done: $json ($($sw.Elapsed.TotalSeconds)s)"
