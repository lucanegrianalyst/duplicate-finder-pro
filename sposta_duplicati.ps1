[CmdletBinding()]
param(
    [string]$CsvFile,
    [string]$Destinazione = "C:\cerca doppioni\output\cestino",
    [switch]$Auto,
    [switch]$DryRun,
    [switch]$Delete
)

if (-not $CsvFile) {
    $CsvFile = Get-ChildItem "C:\cerca doppioni\output\report_*.csv" -ErrorAction SilentlyContinue |
               Sort-Object LastWriteTime -Descending |
               Select-Object -First 1 -ExpandProperty FullName
}
if (-not $CsvFile -or -not (Test-Path -LiteralPath $CsvFile)) {
    Write-Host "Nessun CSV trovato. Esegui prima .\cerca_doppioni.ps1" -ForegroundColor Red
    exit 1
}

Write-Host "CSV: $CsvFile" -ForegroundColor Cyan
if ($Delete) {
    Write-Host "MODALITA ELIMINAZIONE DEFINITIVA ATTIVA" -ForegroundColor Red
} elseif ($DryRun) {
    Write-Host "MODALITA DRY-RUN: nessun file verra toccato." -ForegroundColor Yellow
} else {
    Write-Host "MODALITA CESTINO: i file verranno spostati (reversibile)." -ForegroundColor Green
}
Write-Host ""

$righeCsv = Import-Csv -LiteralPath $CsvFile -Encoding UTF8
$hash = $righeCsv | Where-Object { $_.Categoria -eq "DUPLICATI PER HASH" }
if (-not $hash) {
    Write-Host "Nessun duplicato per hash nel CSV." -ForegroundColor Red
    exit 0
}
$gruppi = $hash | Group-Object Chiave
Write-Host ("Gruppi hash: {0}   File totali: {1}" -f $gruppi.Count, $hash.Count) -ForegroundColor Green
Write-Host ""

$timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
$cestinoCorrente = Join-Path $Destinazione $timestamp
$logFile = Join-Path $Destinazione "log_$timestamp.txt"

if (-not $DryRun) {
    if ($Delete) {
        if (-not (Test-Path -LiteralPath $Destinazione)) {
            New-Item -ItemType Directory -Path $Destinazione -Force | Out-Null
        }
    } else {
        New-Item -ItemType Directory -Path $cestinoCorrente -Force | Out-Null
    }
    $intestazione = if ($Delete) { "ELIMINAZIONE DUPLICATI - $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')" } else { "SPOSTAMENTO DUPLICATI - $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')" }
    $intestazione | Set-Content -LiteralPath $logFile -Encoding UTF8
}

function Scegli-Migliore {
    param([array]$Percorsi)
    $candidati = $Percorsi | ForEach-Object {
        $p = $_
        $score = 0
        if ($p -match '\(\d+\)')   { $score += 100 }
        if ($p -match 'vecchi')    { $score += 50 }
        if ($p -match 'Schwazer')  { $score += 30 }
        if ($p -match '\d{8} - ')  { $score += 20 }
        [PSCustomObject]@{ Percorso = $p; Score = $score; Lunghezza = $p.Length }
    }
    return ($candidati | Sort-Object Score, Lunghezza | Select-Object -First 1).Percorso
}

$daGestire = @()
$contatore = 0
$quit = $false

foreach ($g in $gruppi) {
    if ($quit) { break }
    $contatore++
    $percorsi = $g.Group.Percorso
    $dimensione = [int64]$g.Group[0].Dimensione
    Write-Host ("=== GRUPPO {0}/{1} ({2:N2} MB) ===" -f $contatore, $gruppi.Count, ($dimensione/1MB)) -ForegroundColor Yellow
    for ($i = 0; $i -lt $percorsi.Count; $i++) {
        Write-Host ("  [{0}] {1}" -f ($i + 1), $percorsi[$i]) -ForegroundColor Gray
    }
    if ($Auto -or $DryRun) {
        $tieni = Scegli-Migliore -Percorsi $percorsi
        $scarta = $percorsi | Where-Object { $_ -ne $tieni }
        Write-Host ("  Tengo:  {0}" -f $tieni) -ForegroundColor Green
        foreach ($s in $scarta) {
            $azione = if ($Delete) { "Elimino" } else { "Sposto" }
            Write-Host ("  {0}: {1}" -f $azione, $s) -ForegroundColor Magenta
            $daGestire += [PSCustomObject]@{ File = $s; Tengo = $tieni; Dimensione = $dimensione }
        }
        Write-Host ""
        continue
    }
    while ($true) {
        $scelta = Read-Host "Quale tenere? [1-$($percorsi.Count)/k=entrambi/s=skip/q=quit]"
        if ($scelta -eq 'q') { $quit = $true; break }
        if ($scelta -eq 's') { break }
        if ($scelta -eq 'k') { break }
        $n = 0
        if ([int]::TryParse($scelta, [ref]$n) -and $n -ge 1 -and $n -le $percorsi.Count) {
            $tieni = $percorsi[$n - 1]
            $scarta = $percorsi | Where-Object { $_ -ne $tieni }
            foreach ($s in $scarta) {
                $daGestire += [PSCustomObject]@{ File = $s; Tengo = $tieni; Dimensione = $dimensione }
            }
            Write-Host ("  Tieni: {0}" -f $tieni) -ForegroundColor Green
            Write-Host ""
            break
        }
        Write-Host "  Scelta non valida." -ForegroundColor Red
    }
}

Write-Host ""
Write-Host ("=" * 70) -ForegroundColor Cyan
$azione = if ($Delete) { "da eliminare" } else { "da spostare" }
Write-Host (" File {0}: {1}" -f $azione, $daGestire.Count) -ForegroundColor Cyan
Write-Host (" Spazio: {0:N2} MB" -f (($daGestire | Measure-Object Dimensione -Sum).Sum / 1MB)) -ForegroundColor Cyan
Write-Host ("=" * 70) -ForegroundColor Cyan

if ($daGestire.Count -eq 0) {
    Write-Host "Niente da fare." -ForegroundColor Yellow
    exit 0
}
if ($DryRun) {
    Write-Host ""
    Write-Host "DRY-RUN: nessun file toccato. Rilancia senza -DryRun per applicare." -ForegroundColor Yellow
    exit 0
}
if (-not $Auto) {
    $conf = Read-Host "Confermi? [s/N]"
    if ($conf -ne 's') { Write-Host "Annullato." -ForegroundColor Yellow; exit 0 }
}
if ($Delete) {
    Write-Host ""
    Write-Host ("STAI PER ELIMINARE DEFINITIVAMENTE {0} FILE." -f $daGestire.Count) -ForegroundColor Red
    Write-Host "Questa azione NON e reversibile." -ForegroundColor Red
    $conf2 = Read-Host "Scrivi ELIMINA (tutto maiuscolo) per confermare"
    if ($conf2 -ne 'ELIMINA') {
        Write-Host "Annullato (conferma non valida)." -ForegroundColor Yellow
        exit 0
    }
}

$ok = 0
$ko = 0
foreach ($item in $daGestire) {
    $src = $item.File
    if (-not (Test-Path -LiteralPath $src)) {
        Write-Host ("  Non trovato: {0}" -f $src) -ForegroundColor DarkYellow
        "NON TROVATO: $src" | Add-Content -LiteralPath $logFile -Encoding UTF8
        $ko++
        continue
    }
    try {
        if ($Delete) {
            Remove-Item -LiteralPath $src -Force -ErrorAction Stop
            Write-Host ("  Eliminato: {0}" -f $src) -ForegroundColor Red
            "ELIMINATO: $src" | Add-Content -LiteralPath $logFile -Encoding UTF8
        } else {
            $relativo = $src -replace '^[A-Za-z]:\\[^\\]+\\', ''
            $dest = Join-Path $cestinoCorrente $relativo
            $destDir = Split-Path -Parent $dest
            if (-not (Test-Path -LiteralPath $destDir)) {
                New-Item -ItemType Directory -Path $destDir -Force | Out-Null
            }
            Move-Item -LiteralPath $src -Destination $dest -Force -ErrorAction Stop
            Write-Host ("  Spostato: {0}" -f $relativo) -ForegroundColor Green
            "SPOSTATO: $src -> $dest" | Add-Content -LiteralPath $logFile -Encoding UTF8
        }
        $ok++
    } catch {
        Write-Host ("  Errore su {0}: {1}" -f $src, $_) -ForegroundColor Red
        "ERRORE: $src -> $_" | Add-Content -LiteralPath $logFile -Encoding UTF8
        $ko++
    }
}

Write-Host ""
Write-Host ("=" * 70) -ForegroundColor Cyan
if ($Delete) {
    Write-Host (" Eliminati: {0}   Errori: {1}" -f $ok, $ko) -ForegroundColor Green
    Write-Host (" Log: {0}" -f $logFile) -ForegroundColor Cyan
} else {
    Write-Host (" Spostati: {0}   Errori: {1}" -f $ok, $ko) -ForegroundColor Green
    Write-Host (" Cestino: {0}" -f $cestinoCorrente) -ForegroundColor Cyan
    Write-Host (" Log: {0}" -f $logFile) -ForegroundColor Cyan
}
