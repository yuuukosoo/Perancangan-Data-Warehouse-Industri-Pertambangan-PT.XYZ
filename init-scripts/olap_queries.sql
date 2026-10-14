-- ====================================================================
-- OLAP ANALYTICAL QUERIES - PT XYZ DATA WAREHOUSE
-- Mendukung Operasi Multidimensional:
-- 1. Slice (Pemotongan data pada 1 dimensi)
-- 2. Dice (Sub-cube multi dimensi)
-- 3. Roll-up (Agregasi hierarki)
-- 4. Drill-down (Rincian mendalam)
-- 5. Pivot (Cross-tabulation Matriks)
-- ====================================================================

USE PTXYZ_DataWarehouse;
GO

SET NOCOUNT ON;
PRINT '====================================================================';
PRINT '         EKSEKUSI KUERI MULTIDIMENSIONAL OLAP & ANALITIK           ';
PRINT '====================================================================';
PRINT '';

-- 1. SLICE: Memotong data hanya untuk Wilayah 'Sumatera'
PRINT '>>> 1. OPERASI SLICE (Wilayah = ''Sumatera'')';
SELECT 
    s.region AS [Wilayah],
    m.material_name AS [Material],
    COUNT(*) AS [Total_Operasi],
    ROUND(SUM(f.produced_volume), 2) AS [Total_Volume_Produksi]
FROM fact.FactProduction f
JOIN dim.DimSite s ON f.site_key = s.site_key
JOIN dim.DimMaterial m ON f.material_key = m.material_key
WHERE s.region = 'Sumatera'
GROUP BY s.region, m.material_name
ORDER BY Total_Volume_Produksi DESC;
PRINT '';

-- 2. DICE: Memilih sub-cube berdasarkan 2 kriteria (Wilayah 'Kalimantan' & Shift 'Shift 1')
PRINT '>>> 2. OPERASI DICE (Wilayah = ''Kalimantan'' DAN Shift = ''Shift 1'')';
SELECT 
    s.region AS [Wilayah],
    sh.shift_name AS [Shift],
    m.material_type AS [Tipe_Material],
    ROUND(SUM(f.produced_volume), 2) AS [Volume_Produksi],
    ROUND(AVG(f.unit_cost), 2) AS [Rata_Rata_Unit_Cost]
FROM fact.FactProduction f
JOIN dim.DimSite s ON f.site_key = s.site_key
JOIN dim.DimShift sh ON f.shift_key = sh.shift_key
JOIN dim.DimMaterial m ON f.material_key = m.material_key
WHERE s.region = 'Kalimantan' AND sh.shift_name = 'Shift 1'
GROUP BY s.region, sh.shift_name, m.material_type;
PRINT '';

-- 3. ROLL-UP: Agregasi Hierarki Waktu (Tahun -> Kuartal -> Bulan)
PRINT '>>> 3. OPERASI ROLL-UP (Hierarki Waktu: Tahun -> Kuartal -> Bulan)';
SELECT 
    t.year AS [Tahun],
    t.quarter AS [Kuartal],
    t.month_name AS [Bulan],
    ROUND(SUM(f.produced_volume), 2) AS [Volume_Produksi]
FROM fact.FactProduction f
JOIN dim.DimTime t ON f.time_key = t.time_key
GROUP BY ROLLUP (t.year, t.quarter, t.month_name)
ORDER BY t.year, t.quarter, t.month_name;
PRINT '';

-- 4. DRILL-DOWN: Rincian Detail Produksi per Pegawai & Site
PRINT '>>> 4. OPERASI DRILL-DOWN (Produksi per Site -> Nama Karyawan -> Shift)';
SELECT TOP 10
    s.site_name AS [Nama_Site],
    e.employee_name AS [Nama_Karyawan],
    e.position AS [Jabatan],
    sh.shift_name AS [Shift],
    ROUND(SUM(f.produced_volume), 2) AS [Total_Produksi]
FROM fact.FactProduction f
JOIN dim.DimSite s ON f.site_key = s.site_key
JOIN dim.DimEmployee e ON f.employee_key = e.employee_key
JOIN dim.DimShift sh ON f.shift_key = sh.shift_key
GROUP BY s.site_name, e.employee_name, e.position, sh.shift_name
ORDER BY Total_Produksi DESC;
PRINT '';

-- 5. PIVOT: Matriks Volume Produksi (Wilayah x Tipe Material)
PRINT '>>> 5. OPERASI PIVOT (Cross-Tabulation: Wilayah vs Tipe Material)';
SELECT 
    Wilayah,
    ISNULL([Metal], 0) AS [Produksi_Metal],
    ISNULL([Ore], 0) AS [Produksi_Ore],
    (ISNULL([Metal], 0) + ISNULL([Ore], 0)) AS [Total_Kumulatif]
FROM (
    SELECT 
        s.region AS Wilayah,
        m.material_type AS Tipe_Material,
        f.produced_volume AS Volume
    FROM fact.FactProduction f
    JOIN dim.DimSite s ON f.site_key = s.site_key
    JOIN dim.DimMaterial m ON f.material_key = m.material_key
) AS SourceTable
PIVOT (
    SUM(Volume)
    FOR Tipe_Material IN ([Metal], [Ore])
) AS PivotTable
ORDER BY Total_Kumulatif DESC;

PRINT '====================================================================';
PRINT '                 EKSEKUSI KUERI OLAP SELESAI                        ';
PRINT '====================================================================';
GO
