# Runs Yash ERP on this PC WITHOUT Docker, using the Supabase database from .env.
#   Right-click > Run with PowerShell, or:  powershell -ExecutionPolicy Bypass -File .\run-supabase.ps1
# Opens two windows (API on :8000, website on :3000). Close them to stop the app.
$ErrorActionPreference = "Stop"
$root = $PSScriptRoot

# --- read .env ---
$cfg = @{}
foreach ($line in Get-Content (Join-Path $root ".env")) {
    if ($line -match '^\s*([A-Z_]+)\s*=(.*)$') { $cfg[$Matches[1]] = $Matches[2].Trim().Trim('"') }
}
if (-not $cfg.SUPABASE_DB_URL -or $cfg.SUPABASE_DB_URL -notmatch '^postgres') { throw "SUPABASE_DB_URL in .env must start with postgresql://" }
if (-not $cfg.SUPABASE_DB_PASSWORD) { throw "SUPABASE_DB_PASSWORD in .env is empty - type your Supabase database password there and save." }

# Insert the URL-encoded password: postgresql://user@host  ->  postgresql://user:pass@host
$pw = [uri]::EscapeDataString($cfg.SUPABASE_DB_PASSWORD)
$dbUrl = $cfg.SUPABASE_DB_URL -replace '^(postgres(?:ql)?://[^:@/]+)@', "`$1:$pw@"

$env:DATABASE_URL = $dbUrl
$env:STORAGE = "db"
$env:JWT_SECRET = $cfg.JWT_SECRET
$env:ADMIN_EMAIL = $cfg.ADMIN_EMAIL
$env:ADMIN_PASSWORD = $cfg.ADMIN_PASSWORD
$env:UPLOAD_DIR = Join-Path $root "backend\uploads"

# --- Python environment (Python 3.11) ---
$py = Join-Path $root "backend\.venv\Scripts\python.exe"
if (-not (Test-Path $py)) {
    Write-Host "Creating Python environment..."
    py -3.11 -m venv (Join-Path $root "backend\.venv")
    & $py -m pip install --quiet -r (Join-Path $root "backend\requirements.txt")
}

foreach ($port in 8000, 3000) {
    if (Get-NetTCPConnection -State Listen -LocalPort $port -ErrorAction SilentlyContinue) {
        throw "Port $port is already in use. Stop whatever is running there (e.g. Docker 'yash-api' or an old window) and retry."
    }
}

# --- database tables + admin account in Supabase ---
Push-Location (Join-Path $root "backend")
try {
    Write-Host "Updating Supabase database tables..."
    & $py -m alembic upgrade head
    if ($LASTEXITCODE -ne 0) { throw "Database migration failed (check the password in .env)." }
    & $py -m app.seed
    if ($LASTEXITCODE -ne 0) { throw "Seeding failed." }
} finally { Pop-Location }

# --- start API and website in their own windows (they inherit the env vars above) ---
Start-Process powershell -WorkingDirectory (Join-Path $root "backend") -ArgumentList "-NoExit", "-Command",
    "`$host.UI.RawUI.WindowTitle='Yash ERP API (Supabase)'; & '$py' -m uvicorn app.main:app --host 127.0.0.1 --port 8000"

$web = Join-Path $root "web"
if (-not (Test-Path (Join-Path $web "node_modules"))) { Push-Location $web; npm install; Pop-Location }
if (-not (Test-Path (Join-Path $web ".next\BUILD_ID"))) { Push-Location $web; npm run build; Pop-Location }
Start-Process powershell -WorkingDirectory $web -ArgumentList "-NoExit", "-Command",
    "`$host.UI.RawUI.WindowTitle='Yash ERP Website'; npm run start"

Write-Host ""
Write-Host "Yash ERP is starting: open http://localhost:3000  (login: $($cfg.ADMIN_EMAIL))" -ForegroundColor Green
