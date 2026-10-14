# ====================================================================
# ONE-COMMAND RUNNER: PT XYZ DATA WAREHOUSE (END-TO-END AUTOMATION)
# Mata Kuliah: Kecerdasan Bisnis
# Menjalankan seluruh proses dari nol hingga hasil validasi otomatis
# ====================================================================

$ErrorActionPreference = "Stop"

Write-Host "====================================================================" -ForegroundColor Cyan
Write-Host "   PT XYZ DATA WAREHOUSE - ONE-COMMAND REPRODUCIBLE RUNNER          " -ForegroundColor Cyan
Write-Host "====================================================================" -ForegroundColor Cyan
Write-Host ""

# 1. Pastikan file .env ada
if (-not (Test-Path ".env")) {
    Write-Host "[1/5] Membuat file .env dari template..." -ForegroundColor Yellow
    Copy-Item ".env.example" ".env" -Force
} else {
    Write-Host "[1/5] File .env terdeteksi. Menggunakan konfigurasi yang ada." -ForegroundColor Green
}

# 2. Nyalakan Container SQL Server
Write-Host "[2/5] Menyalakan container database SQL Server 2022..." -ForegroundColor Yellow
$env:Path = "C:\Users\Asus\AppData\Local\Programs\DockerDesktop\resources\bin;" + $env:Path
docker compose up -d sqlserver

# 3. Tunggu hingga SQL Server siap menerima koneksi
Write-Host "[3/5] Menunggu kesiapan SQL Server engine..." -ForegroundColor Yellow
$ready = $false
$retries = 0
while (-not $ready -and $retries -lt 30) {
    $retries++
    docker exec ptxyz_sqlserver /opt/mssql-tools18/bin/sqlcmd -S localhost -U sa -P "YourSecurePassword123!" -Q "SELECT 1" -C -N 2>$null | Out-Null
    if ($LASTEXITCODE -eq 0) {
        $ready = $true
        Write-Host "      SQL Server sudah siap dan menerima koneksi!" -ForegroundColor Green
    } else {
        Start-Sleep -Seconds 3
    }
}

# 4. Inisialisasi Database dan Skema Star Schema
Write-Host "[4/5] Menginisialisasi Database dan Skema Star Schema..." -ForegroundColor Yellow
docker exec -it ptxyz_sqlserver /opt/mssql-tools18/bin/sqlcmd -S localhost -U sa -P "YourSecurePassword123!" -C -N -Q "IF NOT EXISTS (SELECT name FROM sys.databases WHERE name = 'PTXYZ_DataWarehouse') CREATE DATABASE PTXYZ_DataWarehouse;"
docker exec -it ptxyz_sqlserver /opt/mssql-tools18/bin/sqlcmd -S localhost -U sa -P "YourSecurePassword123!" -d PTXYZ_DataWarehouse -C -N -i /init-scripts/create-schema.sql
Write-Host "      Skema 14 tabel (dim, fact, staging) berhasil diinisialisasi!" -ForegroundColor Green

# 5. Eksekusi Pipeline ETL
Write-Host "[5/5] Menjalankan Pipeline ETL Data Tambang (standalone_etl.py)..." -ForegroundColor Yellow
python standalone_etl.py
Write-Host "      Pipeline ETL selesai!" -ForegroundColor Green

Write-Host ""
Write-Host "====================================================================" -ForegroundColor Cyan
Write-Host "         MENJALANKAN UJI VALIDASI OTOMATIS (TEST SUITE)             " -ForegroundColor Cyan
Write-Host "====================================================================" -ForegroundColor Cyan
docker exec -it ptxyz_sqlserver /opt/mssql-tools18/bin/sqlcmd -S localhost -U sa -P "YourSecurePassword123!" -d PTXYZ_DataWarehouse -C -N -i /init-scripts/validate.sql

Write-Host ""
Write-Host "🎉 PROSES SELESAI SEMPURNA! Sistem Data Warehouse Siap Digunakan." -ForegroundColor Green
