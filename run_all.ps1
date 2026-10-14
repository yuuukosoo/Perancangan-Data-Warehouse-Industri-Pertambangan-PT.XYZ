# ====================================================================
# ONE-COMMAND RUNNER: PT XYZ DATA WAREHOUSE (END-TO-END AUTOMATION)
# Mata Kuliah: Kecerdasan Bisnis (Kode: 552010001389)
# Menjalankan seluruh proses dari inisialisasi hingga pengujian otomatis
# ====================================================================

$ErrorActionPreference = "Stop"

Write-Host "====================================================================" -ForegroundColor Cyan
Write-Host "   PT XYZ DATA WAREHOUSE - ONE-COMMAND REPRODUCIBLE RUNNER          " -ForegroundColor Cyan
Write-Host "====================================================================" -ForegroundColor Cyan
Write-Host ""

# 1. Pastikan berkas konfigurasi .env tersedia
if (-not (Test-Path ".env")) {
    Write-Host "[1/6] Menyiapkan berkas .env dari template..." -ForegroundColor Yellow
    Copy-Item ".env.example" ".env" -Force
} else {
    Write-Host "[1/6] Berkas .env terdeteksi. Menggunakan parameter konfigurasi aktif." -ForegroundColor Green
}

# 2. Nyalakan Layanan Kontainer SQL Server
Write-Host "[2/6] Menginisiasi kontainer database Microsoft SQL Server 2022..." -ForegroundColor Yellow
$env:Path = "C:\Users\Asus\AppData\Local\Programs\DockerDesktop\resources\bin;" + $env:Path
docker compose up -d sqlserver

# 3. Tunggu hingga Engine SQL Server Siap Menerima Koneksi
Write-Host "[3/6] Memeriksa kesiapan layanan SQL Server engine (Healthcheck)..." -ForegroundColor Yellow
$ready = $false
$retries = 0
while (-not $ready -and $retries -lt 30) {
    $retries++
    docker exec ptxyz_sqlserver /opt/mssql-tools18/bin/sqlcmd -S localhost -U sa -P "YourSecurePassword123!" -Q "SELECT 1" -C -N 2>$null | Out-Null
    if ($LASTEXITCODE -eq 0) {
        $ready = $true
        Write-Host "      Layanan SQL Server siap dan menerima koneksi!" -ForegroundColor Green
    } else {
        Start-Sleep -Seconds 3
    }
}

# 4. Inisialisasi Basis Data dan Skema Dimensional (14 Tabel)
Write-Host "[4/6] Menjalankan inisialisasi skema basis data (create-schema.sql)..." -ForegroundColor Yellow
docker exec -it ptxyz_sqlserver /opt/mssql-tools18/bin/sqlcmd -S localhost -U sa -P "YourSecurePassword123!" -C -N -Q "IF NOT EXISTS (SELECT name FROM sys.databases WHERE name = 'PTXYZ_DataWarehouse') CREATE DATABASE PTXYZ_DataWarehouse;"
docker exec -it ptxyz_sqlserver /opt/mssql-tools18/bin/sqlcmd -S localhost -U sa -P "YourSecurePassword123!" -d PTXYZ_DataWarehouse -C -N -i /init-scripts/create-schema.sql
Write-Host "      Skema 14 tabel (dim, fact, staging) berhasil diinisialisasi!" -ForegroundColor Green

# 5. Eksekusi Pipeline ETL
Write-Host "[5/6] Menjalankan pipeline ETL ekstraksi dan transformasi data (standalone_etl.py)..." -ForegroundColor Yellow
python standalone_etl.py
Write-Host "      Proses pipeline ETL selesai!" -ForegroundColor Green

# 6. Eksekusi Pengujian Kepatuhan dan Validasi Integritas
Write-Host ""
Write-Host "====================================================================" -ForegroundColor Cyan
Write-Host "   [6/6] MENJALANKAN UJI INTEGRITAS DATA OTOMATIS (TEST SUITE)      " -ForegroundColor Cyan
Write-Host "====================================================================" -ForegroundColor Cyan
docker exec -it ptxyz_sqlserver /opt/mssql-tools18/bin/sqlcmd -S localhost -U sa -P "YourSecurePassword123!" -d PTXYZ_DataWarehouse -C -N -i /init-scripts/validate.sql

# 7. Eksekusi Kueri Analitik Multidimensional OLAP
Write-Host ""
Write-Host "====================================================================" -ForegroundColor Cyan
Write-Host "   MENJALANKAN KUERI ANALITIK MULTIDIMENSIONAL (OLAP SUITE)         " -ForegroundColor Cyan
Write-Host "====================================================================" -ForegroundColor Cyan
docker exec -it ptxyz_sqlserver /opt/mssql-tools18/bin/sqlcmd -S localhost -U sa -P "YourSecurePassword123!" -d PTXYZ_DataWarehouse -C -N -i /init-scripts/olap_queries.sql

Write-Host ""
Write-Host "====================================================================" -ForegroundColor Green
Write-Host "   EKSEKUSI SELESAI: Seluruh tahapan pipeline dan validasi berhasil! " -ForegroundColor Green
Write-Host "====================================================================" -ForegroundColor Green
