<#
.SYNOPSIS
    Motore di scansione, hashing e gestione della cache per Cerca Doppioni PRO.
.DESCRIPTION
    Questo modulo contiene la logica core del programma.
.NOTES
    Autore: Luca Negri
    Versione: 7.9
    Progetto: Cerca Doppioni PRO
#>

function Start-DuplicatiAnalysis {
    param(
        [Parameter(Mandatory=$true)]
        [hashtable]$SyncHash,
        [Parameter(Mandatory=$true)]
        [string[]]$Cartelle,
        [Parameter(Mandatory=$true)]
        [string]$BaseDir
    )
    
    function Log($msg) { $SyncHash.LogQueue.Enqueue($msg) }
    
    try {
        $Cartelle = @($Cartelle | Where-Object { -not [string]::IsNullOrWhiteSpace($_) })
        if ($Cartelle.Count -eq 0) { Log "ERRORE: Nessuna cartella valida."; $SyncHash.Result = $null; return }

        $cachePath = Join-Path $BaseDir "output\cache_hash.csv"
        $cache = @{}
        if (Test-Path $cachePath) {
            Log "Caricamento cache..."
            $cachedRows = Import-Csv -LiteralPath $cachePath
            foreach ($row in $cachedRows) { $cache[$row.Path] = $row }
            Log "Cache caricata: $($cache.Count) file."
        }
        
        Log "Fase 1: Ricerca file..."
        $files = @()
        $count = 0
        foreach ($cartella in $Cartelle) {
            if ($SyncHash.Cancelled) { break }
            Log "Scansione: $cartella"
            $fileList = Get-ChildItem -LiteralPath $cartella -Recurse -File -Include *.mp3,*.flac,*.m4a,*.wav,*.jpg,*.png,*.mp4 -Force -ErrorAction SilentlyContinue
            foreach ($f in $fileList) {
                if ($SyncHash.Cancelled) { break }
                $files += $f
                $count++
                $SyncHash.ScannedCount = $count
            }
        }
        if ($SyncHash.Cancelled) { Log "Annullato."; return }
        
        Log "Fase 2: Raggruppamento per dimensione..."
        $gruppiDimensione = $files | Group-Object Length | Where-Object Count -gt 1
        $totaleDaProcessare = ($gruppiDimensione | Measure-Object -Property Count -Sum).Sum
        
        $SyncHash.Total = $totaleDaProcessare
        Log "Fase 3: Calcolo Hash per $totaleDaProcessare file..."
        
        $duplicatiEsatti = @(); $cont = 0
        foreach ($g in $gruppiDimensione) {
            if ($SyncHash.Cancelled) { break }
            $hashMap = @{}
            foreach ($f in $g.Group) {
                if ($SyncHash.Cancelled) { break }
                $cont++; $SyncHash.Progress = $cont
                
                $h = $null
                $dataModifica = $f.LastWriteTime.ToString("yyyyMMddHHmmss")
                if ($cache.ContainsKey($f.FullName) -and $cache[$f.FullName].Data -eq $dataModifica) {
                    $h = $cache[$f.FullName].Hash
                } else {
                    try {
                        $h = (Get-FileHash -LiteralPath $f.FullName -Algorithm SHA256 -ErrorAction Stop).Hash
                        if ($h) { $cache[$f.FullName] = [PSCustomObject]@{ Path = $f.FullName; Data = $dataModifica; Hash = $h } }
                    } catch {}
                }
                if ($h) {
                    if (-not $hashMap.ContainsKey($h)) { $hashMap[$h] = @() }
                    $hashMap[$h] += $f
                }
            }
            foreach ($k in $hashMap.Keys) { if ($hashMap[$k].Count -gt 1) { $duplicatiEsatti += , $hashMap[$k] } }
        }
        
        Log "Fase 4: Ricerca file con stesso nome ma dimensioni diverse..."
        $duplicatiSimili = @()
        $nomiDaCercare = $files | Group-Object Name | Where-Object Count -gt 1
        foreach ($g in $nomiDaCercare) {
            $dimensioniUniche = ($g.Group.Length | Select-Object -Unique).Count
            if ($dimensioniUniche -gt 1) { $duplicatiSimili += , $g.Group }
        }
        Log "Trovati $($duplicatiSimili.Count) gruppi simili."

        Log "Salvataggio cache..."
        if (-not (Test-Path (Split-Path -Parent $cachePath))) { New-Item -ItemType Directory -Path (Split-Path -Parent $cachePath) -Force | Out-Null }
        $cache.Values | Export-Csv -Path $cachePath -NoTypeInformation -Encoding UTF8
        
        Log "Analisi completata! Trovati $($duplicatiEsatti.Count) gruppi identici."
        $SyncHash.Result = @{ Esatti = $duplicatiEsatti; Simili = $duplicatiSimili }
        
    } catch { Log "ERRORE: $_" } finally { $SyncHash.IsWorking = $false }
}

function Get-BestFile {
    param([Parameter(Mandatory=$true)][array]$Files)
    
    $candidati = $Files | ForEach-Object {
        $score = 0
        $name = $_.Name
        
        # Penalità per nomi "sporchi" o duplicati
        if ($name -match '\(\d+\)') { $score += 100 }
        if ($_.FullName -match 'vecchi')  { $score += 50 }
        if ($name -match 'Copia')   { $score += 30 }
        if ($name -match '\d{8} - '){ $score += 20 }

        # Penalità per nomi che sembrano registrazioni grezze
        if ($name -match '^(VID|IMG|AUD|REC|MVI|DSC|PXL|GOPR|DJI|MOBILE|PTT)_?[-_0-9]') { $score += 80 }
        if ($name -match '^\d{8}[_-]\d{6}') { $score += 80 }
        if ($name -match '^\d{8}[-_]\d+') { $score += 60 }
        if ($name -match '^(WhatsApp|WA|Screen Recording|Registrazione|Audio)') { $score += 40 }
        if ($name -match 'Y2Mate') { $score += 100 }
        
        # Penalità per nomi composti solo da numeri
        $letters = ($name -replace '[^a-zA-Z]', '').Length
        $digits = ($name -replace '[^0-9]', '').Length
        if ($digits -gt 0 -and $letters -eq 0) { $score += 100 }
        elseif ($digits -gt $letters -and $digits -gt 3) { $score += 30 }

        # Bonus per titoli con spazi
        if ($name -match ' ') { $score -= 20 }

        [PSCustomObject]@{ 
            File = $_; 
            Score = $score; 
            Size = $_.Length; 
            LastWrite = $_.LastWriteTime; 
            Creation = $_.CreationTime;
            PathLength = $_.FullName.Length 
        }
    }
    
    # ORDINE DI PRIORITÀ CORRETTO:
    # 1. Dimensione (Qualità)
    # 2. Data Modifica
    # 3. Data Creazione
    # 4. Punteggio Titolo (Score)
    # 5. Lunghezza Percorso
    $best = $candidati | Sort-Object -Property `
        @{Expression="Size";Descending=$true}, `
        @{Expression="LastWrite";Descending=$true}, `
        @{Expression="Creation";Descending=$true}, `
        @{Expression="Score";Descending=$false}, `
        @{Expression="PathLength";Descending=$false} | Select-Object -First 1
        
    return $best.File
}
Export-ModuleMember -Function Start-DuplicatiAnalysis, Get-BestFile
