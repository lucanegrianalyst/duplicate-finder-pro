[CmdletBinding()]
param(
    [string]$ConfigFile = "$PSScriptRoot\config\settings.json"
)
$ErrorActionPreference = "Stop"
if (-not (Test-Path -LiteralPath $ConfigFile)) { Write-Host "Config non trovata: $ConfigFile" -ForegroundColor Red; exit 1 }
$cfg = Get-Content -LiteralPath $ConfigFile -Raw | ConvertFrom-Json
Import-Module "$PSScriptRoot\modules\Scanner.psm1"  -Force
Import-Module "$PSScriptRoot\modules\Analyzer.psm1" -Force
Import-Module "$PSScriptRoot\modules\Reporter.psm1" -Force

Write-Host ""
Write-Host "Scansione di: $($cfg.Cartella)" -ForegroundColor Cyan
$files = Get-FileAudio -Cartella $cfg.Cartella -Estensioni $cfg.Estensioni

$minSize = 0
if ($cfg.PSObject.Properties.Name -contains "DimensioneMinimaByte") { $minSize = [int64]$cfg.DimensioneMinimaByte }
if ($minSize -gt 0) { $files = $files | Where-Object { $_.Length -ge $minSize } }
Write-Host ("File trovati (dopo filtro): {0}" -f $files.Count) -ForegroundColor Green
if ($files.Count -eq 0) { Write-Host "Nessun file da analizzare." -ForegroundColor Yellow; exit 0 }

$sezioni = [ordered]@{}
if ($cfg.Modalita.PerDimensione) { $sezioni["DUPLICATI PER DIMENSIONE"] = Find-DuplicatiPerDimensione -Files $files }
if ($cfg.Modalita.PerNome)       { $sezioni["DUPLICATI PER NOME"]       = Find-DuplicatiPerNome -Files $files }
if ($cfg.Modalita.PerHash) {
    Write-Host "Calcolo hash (potrebbe richiedere tempo)..." -ForegroundColor DarkYellow
    $sezioni["DUPLICATI PER HASH"] = Find-DuplicatiPerHash -Files $files -HashFunction ${function:Get-FileHashSafe}
}

$maxConsole = 30
if ($cfg.Report.PSObject.Properties.Name -contains "MaxGruppiConsole") { $maxConsole = [int]$cfg.Report.MaxGruppiConsole }

foreach ($nome in $sezioni.Keys) { Write-SezioneConsole -Titolo $nome -Gruppi $sezioni[$nome] -MaxGruppi $maxConsole }
Write-RiepilogoFinale -Sezioni $sezioni

if ($cfg.Report.SalvaSuFile) {
    $timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
    $reportPath = Join-Path $cfg.Report.CartellaOutput "report_$timestamp.txt"
    Save-Report -Percorso $reportPath -CartellaAnalizzata $cfg.Cartella -Sezioni $sezioni
    if ($cfg.Report.PSObject.Properties.Name -contains "SalvaCSV" -and $cfg.Report.SalvaCSV) {
        $csvPath = Join-Path $cfg.Report.CartellaOutput "report_$timestamp.csv"
        Save-CSV -Percorso $csvPath -Sezioni $sezioni
    }
}
Write-Host ""
Write-Host "Completato." -ForegroundColor Green