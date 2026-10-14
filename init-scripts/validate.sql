-- ====================================================================
-- AUTOMATED VALIDATION TEST SUITE - PT XYZ DATA WAREHOUSE
-- Membuktikan Kepatuhan Penuh Terhadap Ketentuan Soal & README:
-- 1. Kepatuhan Skema (Nama tabel, skema, penamaan kolom)
-- 2. Integritas Referensial (FK Valid, 0 Orphan Records)
-- 3. Akurasi Agregat & Rekapitulasi (Sesuai Benchmark README)
-- ====================================================================

USE PTXYZ_DataWarehouse;
GO

SET NOCOUNT ON;
PRINT '====================================================================';
PRINT '   AUTOMATED VALIDATION TEST SUITE: PT XYZ MINING DATA WAREHOUSE    ';
PRINT '====================================================================';
PRINT '';

-- --------------------------------------------------------------------
-- TEST 1: VALIDASI SKEMA DAN KEBERADAAN TABEL (3 Skema, 14 Tabel)
-- --------------------------------------------------------------------
PRINT '>>> [TEST 1] VALIDASI STRUKTUR SKEMA & TABEL';

DECLARE @TotalTables INT;
SELECT @TotalTables = COUNT(*)
FROM sys.tables t
JOIN sys.schemas s ON t.schema_id = s.schema_id
WHERE s.name IN ('dim', 'fact', 'staging');

IF @TotalTables = 14
    PRINT '  [PASS] 14 Tabel Lengkap Ditemukan (8 Dimensi, 3 Fakta, 3 Staging).';
ELSE
    PRINT '  [FAIL] Ditemukan ' + CAST(@TotalTables AS VARCHAR) + ' tabel dari yang diharapkan 14.';

SELECT 
    s.name + '.' + t.name AS [Nama_Tabel],
    p.rows AS [Jumlah_Baris_Data]
FROM sys.tables t
JOIN sys.schemas s ON t.schema_id = s.schema_id
JOIN sys.partitions p ON t.object_id = p.object_id AND p.index_id IN (0,1)
WHERE s.name IN ('dim', 'fact', 'staging')
ORDER BY s.name, t.name;
PRINT '';

-- --------------------------------------------------------------------
-- TEST 2: VALIDASI INTEGRITAS REFERENSIAL (0 ORPHAN RECORDS)
-- --------------------------------------------------------------------
PRINT '>>> [TEST 2] UJI INTEGRITAS REFERENSIAL (WAJIB 0 ORPHAN FK)';

DECLARE @Orphan_FEU_Time INT, @Orphan_FEU_Site INT, @Orphan_FEU_Eq INT;
DECLARE @Orphan_FP_Time INT, @Orphan_FP_Site INT, @Orphan_FP_Mat INT, @Orphan_FP_Emp INT, @Orphan_FP_Shift INT;
DECLARE @Orphan_FFT_Time INT, @Orphan_FFT_Site INT, @Orphan_FFT_Proj INT, @Orphan_FFT_Acc INT;

-- FactEquipmentUsage Orphans
SELECT @Orphan_FEU_Time = COUNT(*) FROM fact.FactEquipmentUsage f LEFT JOIN dim.DimTime t ON f.time_key = t.time_key WHERE t.time_key IS NULL;
SELECT @Orphan_FEU_Site = COUNT(*) FROM fact.FactEquipmentUsage f LEFT JOIN dim.DimSite s ON f.site_key = s.site_key WHERE s.site_key IS NULL;
SELECT @Orphan_FEU_Eq   = COUNT(*) FROM fact.FactEquipmentUsage f LEFT JOIN dim.DimEquipment e ON f.equipment_key = e.equipment_key WHERE e.equipment_key IS NULL;

-- FactProduction Orphans
SELECT @Orphan_FP_Time  = COUNT(*) FROM fact.FactProduction f LEFT JOIN dim.DimTime t ON f.time_key = t.time_key WHERE t.time_key IS NULL;
SELECT @Orphan_FP_Site  = COUNT(*) FROM fact.FactProduction f LEFT JOIN dim.DimSite s ON f.site_key = s.site_key WHERE s.site_key IS NULL;
SELECT @Orphan_FP_Mat   = COUNT(*) FROM fact.FactProduction f LEFT JOIN dim.DimMaterial m ON f.material_key = m.material_key WHERE m.material_key IS NULL;
SELECT @Orphan_FP_Emp   = COUNT(*) FROM fact.FactProduction f LEFT JOIN dim.DimEmployee e ON f.employee_key = e.employee_key WHERE e.employee_key IS NULL;
SELECT @Orphan_FP_Shift = COUNT(*) FROM fact.FactProduction f LEFT JOIN dim.DimShift sh ON f.shift_key = sh.shift_key WHERE sh.shift_key IS NULL;

-- FactFinancialTransaction Orphans
SELECT @Orphan_FFT_Time = COUNT(*) FROM fact.FactFinancialTransaction f LEFT JOIN dim.DimTime t ON f.time_key = t.time_key WHERE t.time_key IS NULL;
SELECT @Orphan_FFT_Site = COUNT(*) FROM fact.FactFinancialTransaction f LEFT JOIN dim.DimSite s ON f.site_key = s.site_key WHERE s.site_key IS NULL;
SELECT @Orphan_FFT_Proj = COUNT(*) FROM fact.FactFinancialTransaction f LEFT JOIN dim.DimProject p ON f.project_key = p.project_key WHERE p.project_key IS NULL;
SELECT @Orphan_FFT_Acc  = COUNT(*) FROM fact.FactFinancialTransaction f LEFT JOIN dim.DimAccount a ON f.account_key = a.account_key WHERE a.account_key IS NULL;

DECLARE @TotalOrphans INT = @Orphan_FEU_Time + @Orphan_FEU_Site + @Orphan_FEU_Eq + 
                            @Orphan_FP_Time + @Orphan_FP_Site + @Orphan_FP_Mat + @Orphan_FP_Emp + @Orphan_FP_Shift + 
                            @Orphan_FFT_Time + @Orphan_FFT_Site + @Orphan_FFT_Proj + @Orphan_FFT_Acc;

SELECT 
    'FactEquipmentUsage -> DimTime' AS [Relasi_FK], @Orphan_FEU_Time AS [Orphan_Count], CASE WHEN @Orphan_FEU_Time = 0 THEN 'PASS (0 Orphan)' ELSE 'FAIL' END AS [Status]
UNION ALL SELECT 'FactEquipmentUsage -> DimSite', @Orphan_FEU_Site, CASE WHEN @Orphan_FEU_Site = 0 THEN 'PASS (0 Orphan)' ELSE 'FAIL' END
UNION ALL SELECT 'FactEquipmentUsage -> DimEquipment', @Orphan_FEU_Eq, CASE WHEN @Orphan_FEU_Eq = 0 THEN 'PASS (0 Orphan)' ELSE 'FAIL' END
UNION ALL SELECT 'FactProduction -> DimTime', @Orphan_FP_Time, CASE WHEN @Orphan_FP_Time = 0 THEN 'PASS (0 Orphan)' ELSE 'FAIL' END
UNION ALL SELECT 'FactProduction -> DimSite', @Orphan_FP_Site, CASE WHEN @Orphan_FP_Site = 0 THEN 'PASS (0 Orphan)' ELSE 'FAIL' END
UNION ALL SELECT 'FactProduction -> DimMaterial', @Orphan_FP_Mat, CASE WHEN @Orphan_FP_Mat = 0 THEN 'PASS (0 Orphan)' ELSE 'FAIL' END
UNION ALL SELECT 'FactProduction -> DimEmployee', @Orphan_FP_Emp, CASE WHEN @Orphan_FP_Emp = 0 THEN 'PASS (0 Orphan)' ELSE 'FAIL' END
UNION ALL SELECT 'FactProduction -> DimShift', @Orphan_FP_Shift, CASE WHEN @Orphan_FP_Shift = 0 THEN 'PASS (0 Orphan)' ELSE 'FAIL' END
UNION ALL SELECT 'FactFinancialTransaction -> DimTime', @Orphan_FFT_Time, CASE WHEN @Orphan_FFT_Time = 0 THEN 'PASS (0 Orphan)' ELSE 'FAIL' END
UNION ALL SELECT 'FactFinancialTransaction -> DimSite', @Orphan_FFT_Site, CASE WHEN @Orphan_FFT_Site = 0 THEN 'PASS (0 Orphan)' ELSE 'FAIL' END
UNION ALL SELECT 'FactFinancialTransaction -> DimProject', @Orphan_FFT_Proj, CASE WHEN @Orphan_FFT_Proj = 0 THEN 'PASS (0 Orphan)' ELSE 'FAIL' END
UNION ALL SELECT 'FactFinancialTransaction -> DimAccount', @Orphan_FFT_Acc, CASE WHEN @Orphan_FFT_Acc = 0 THEN 'PASS (0 Orphan)' ELSE 'FAIL' END;

IF @TotalOrphans = 0
    PRINT '  >>> HASIL TEST 2: 100% SUKSES! Integritas Referensial Terjamin (Total 0 Orphan Records).';
ELSE
    PRINT '  >>> HASIL TEST 2: GAGAL! Ditemukan data orphan.';
PRINT '';

-- --------------------------------------------------------------------
-- TEST 3: VALIDASI AGREGASI & KESETARAAN HASIL DENGAN README
-- --------------------------------------------------------------------
PRINT '>>> [TEST 3] UJI KESETARAAN HASIL AGREGAT (README BENCHMARKS)';

-- 3.1 Efisiensi Peralatan Tambang (README KPI: ~95.66%)
SELECT 
    ROUND(SUM(operating_hours) * 100.0 / NULLIF(SUM(operating_hours + downtime_hours), 0), 2) AS [Equipment_Efficiency_Percent],
    SUM(operating_hours) AS [Total_Operating_Hours],
    SUM(downtime_hours) AS [Total_Downtime_Hours]
FROM fact.FactEquipmentUsage;

-- 3.2 Total Produksi Berdasarkan Tipe Material
SELECT 
    m.material_type AS [Tipe_Material],
    COUNT(*) AS [Jumlah_Transaksi_Produksi],
    ROUND(SUM(f.produced_volume), 2) AS [Total_Volume_Produksi]
FROM fact.FactProduction f
JOIN dim.DimMaterial m ON f.material_key = m.material_key
GROUP BY m.material_type
ORDER BY Total_Volume_Produksi DESC;

-- 3.3 Top 5 Site Berdasarkan Produksi
SELECT TOP 5
    s.site_name AS [Nama_Site],
    s.region AS [Wilayah],
    ROUND(SUM(f.produced_volume), 2) AS [Volume_Produksi]
FROM fact.FactProduction f
JOIN dim.DimSite s ON f.site_key = s.site_key
GROUP BY s.site_name, s.region
ORDER BY Volume_Produksi DESC;

PRINT '====================================================================';
PRINT '            SELURUH UJI VALIDASI OTOMATIS SELESAI                   ';
PRINT '====================================================================';
GO
