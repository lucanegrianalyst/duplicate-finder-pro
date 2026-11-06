<#
.SYNOPSIS
    Test automatico per verificare il corretto funzionamento dei moduli di Cerca Doppioni PRO.
#>
$ErrorActionPreference = "Stop"
$BaseDir = "C:\cerca doppioni"

Write-Host "=== AVVIO TEST DEI MODULI ===" -ForegroundColor Cyan

# 1. Verifica presenza file
$moduli = @("Engine.psm1", "Reporter.psm1", "GUI.psm1")
foreach ($m in $moduli) {
    $path = Join-Path $BaseDir "Modules\$m"
    if (Test-Path $path) { Write-Host "[OK] Modulo trovato: $m" -ForegroundColor Green }
    else { Write-Host "[ERRORE] Modulo mancante: $m" -ForegroundColor Red; exit 1 }
}

# 2. Importa i moduli
Write-Host "`nImportazione moduli in corso..." -ForegroundColor Yellow
Import-Module "$BaseDir\Modules\Engine.psm1" -Force -DisableNameChecking
Import-Module "$BaseDir\Modules\Reporter.psm1" -Force -DisableNameChecking

# 3. Verifica comandi esportati
$comandi = @("Start-DuplicatiAnalysis", "Get-BestFile", "Save-DuplicatiReport", "Invoke-DuplicatiAction")
foreach ($c in $comandi) {
    if (Get-Command $c -ErrorAction SilentlyContinue) { Write-Host "[OK] Funzione caricata: $c" -ForegroundColor Green }
    else { Write-Host "[ERRORE] Funzione mancante: $c" -ForegroundColor Red }
}

# 4. Crea un ambiente di test (cartella con file finti)
$testDir = Join-Path $BaseDir "test_ambiente"
if (Test-Path $testDir) { Remove-Item $testDir -Recurse -Force }
New-Item -ItemType Directory -Path "$testDir\sottocartella" -Force | Out-Null

Write-Host "`nCreazione file di test..." -ForegroundColor Yellow
"Questo è il contenuto originale" | Set-Content "$testDir\originale.mp3"
"Questo è il contenuto originale" | Set-Content "$testDir\copia (1).mp3" # Duplicato esatto
"Video in alta qualità finto..........." | Set-Content "$testDir\video.mp4"
"Video in bassa qualità finto" | Set-Content "$testDir\sottocartella\video.mp4" # Simile (stesso nome, dim. diversa)

# 5. Test del Motore (Engine)
Write-Host "`nAvvio test Motore (Engine)..." -ForegroundColor Yellow
$syncHash = [hashtable]::Synchronized(@{})
$syncHash.LogQueue = [System.Collections.Concurrent.ConcurrentQueue[string]]::new()
$syncHash.IsWorking = $true
$syncHash.Cancelled = $false

Start-DuplicatiAnalysis -SyncHash $syncHash -Cartelle @($testDir) -BaseDir $BaseDir

# Attende la fine dell'analisi (essendo sincrona in questo caso, è immediata)
while ($syncHash.IsWorking) { Start-Sleep -Milliseconds 100 }

$risultati = $syncHash.Result
if ($risultati.Esatti.Count -eq 1) { Write-Host "[OK] Trovato 1 gruppo di duplicati esatti." -ForegroundColor Green }
else { Write-Host "[ERRORE] Numero errato di duplicati esatti." -ForegroundColor Red }

if ($risultati.Simili.Count -eq 1) { Write-Host "[OK] Trovato 1 gruppo di file simili." -ForegroundColor Green }
else { Write-Host "[ERRORE] Numero errato di file simili." -ForegroundColor Red }

# 6. Test della logica di scelta (Get-BestFile)
Write-Host "`nTest logica di scelta 'Originale'..." -ForegroundColor Yellow
$gruppoEsatto = $risultati.Esatti[0]
$migliore = Get-BestFile -Files $gruppoEsatto
if ($migliore.Name -eq "originale.mp3") { Write-Host "[OK] Scelto il file corretto come originale: $($migliore.Name)" -ForegroundColor Green }
else { Write-Host "[ERRORE] Scelto il file sbagliato: $($migliore.Name)" -ForegroundColor Red }

# 7. Test del Reporter
Write-Host "`nTest del Reporter..." -ForegroundColor Yellow
$fintiFile = @([PSCustomObject]@{ Tipo="Esatto"; Nome="test.mp3"; Dimensione="1.00 MB"; Percorso="C:\test.mp3" })
$percorsoReport = Save-DuplicatiReport -Anteprima $fintiFile -BaseDir $BaseDir
if (Test-Path $percorsoReport) { 
    Write-Host "[OK] Report CSV creato correttamente: $percorsoReport" -ForegroundColor Green 
    Remove-Item $percorsoReport -Force # Pulizia
} else { 
    Write-Host "[ERRORE] Impossibile creare il report CSV." -ForegroundColor Red 
}

# 8. Pulizia finale
Remove-Item $testDir -Recurse -Force
Write-Host "`n=== TEST COMPLETATI ===" -ForegroundColor Cyan
