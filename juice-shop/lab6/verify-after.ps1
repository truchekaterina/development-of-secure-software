# Lab 6 — verify fixes on http://127.0.0.1:3001 (app built from patched source)
# Prerequisite: npm run build:server && PORT=3001 npm start  (or custom image)

$base = "http://127.0.0.1:3001"

Write-Host "=== SQLi after fix ==="
$payload = "')) union select id,'2','3',email,password,'6','7','8','9' from users--"
$enc = [uri]::EscapeDataString($payload)
$r = curl.exe -s "$base/rest/products/search?q=$enc"
if ($r -match 'admin@juice-sh\.op' -and $r -match '"name":"2"') {
  Write-Host "FAIL: still leaking users"
} else {
  Write-Host "OK: no user leak in response"
}
Write-Host $r.Substring(0, [Math]::Min(500, $r.Length))

Write-Host "`n=== BOLA after fix ==="
$login = curl.exe -s -X POST "$base/rest/user/login" -H "Content-Type: application/json" -d '{\"email\":\"jim@juice-sh.op\",\"password\":\"ncc-1701\"}' | ConvertFrom-Json
$token = $login.authentication.token
$code = curl.exe -s -o $env:TEMP\basket1.json -w "%{http_code}" "$base/rest/basket/1" -H "Authorization: Bearer $token"
Write-Host "GET /rest/basket/1 HTTP $code"
Get-Content $env:TEMP\basket1.json
