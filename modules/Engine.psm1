<#
.SYNOPSIS
    Motore di scansione, hashing e gestione della cache per Cerca Doppioni PRO.
.NOTES
    Versione: 10.2 (Filtro file cloud/offline e file troppo piccoli)
#>

function Start-DuplicatiAnalysis {
    param(
        [Parameter(Mandatory=$true)][hashtable]$SyncHash,
        [Parameter(Mandatory=$true)][string[]]$Cartelle,
        [Parameter(Mandatory=$true)][string]$BaseDir,
        [string[]]$EstensioniSelezionate,
        [bool]$TuttiIFile = $false
    )
    
    function Log($msg) { $SyncHash.LogQueue.Enqueue($msg) }
    
    try {
        $Cartelle = @($Cartelle | Where-Object { -not [string]::IsNullOrWhiteSpace($_) })
        if ($Cartelle.Count -eq 0) { 
            Log "ERRORE: Nessuna cartella valida."; 
            $SyncHash.Result = @{ Esatti = @(); Simili = @() }
            return 
        }

        $extensions = @()
        if ($TuttiIFile) {
            Log "MODALITA UNIVERSALE: Ricerca di TUTTI i tipi di file."
        } else {
            if ($null -eq $EstensioniSelezionate -or $EstensioniSelezionate.Count -eq 0) {
                Log "ERRORE: Nessun tipo di file selezionato per l'analisi."
                $SyncHash.Result = @{ Esatti = @(); Simili = @() }
                return
            }
            $extensions = $EstensioniSelezionate | ForEach-Object { if ($_ -notmatch '^\*') { "*$_" } else { $_ } }
            Log "Categorie selezionate: $($extensions -join ', ')"
        }

        $cachePath = Join-Path $BaseDir "output\cache_hash.csv"
        $cache = @{}
        if (Test-Path $cachePath) {
            Log "Caricamento cache..."
            try {
                $cachedRows = Import-Csv -LiteralPath $cachePath -ErrorAction Stop
                foreach ($row in $cachedRows) { $cache[$row.Path] = $row }
                Log "Cache caricata: $($cache.Count) file."
            } catch {
                Log "AVVISO: Impossibile leggere la cache. Verrà ignorata. ($_)"
            }
        }
        
        Log "Fase 1: Ricerca file..."
        $files = @()
        $count = 0
        $sysExt = @('.exe','.dll','.sys','.tmp','.log','.ini','.lnk','.bat','.cmd','.msi','.cab','.dat')

        foreach ($cartella in $Cartelle) {
            if ($SyncHash.Cancelled) { break }
            
            if (-not (Test-Path -LiteralPath $cartella)) {
                Log "ERRORE: La cartella '$cartella' non è raggiungibile. Salto."
                continue
            }

            Log "Scansione: $cartella"
            try {
                if ($TuttiIFile) {
                    $fileList = Get-ChildItem -LiteralPath $cartella -Recurse -File -Force -ErrorAction SilentlyContinue | Where-Object { 
                        $_.Length -gt 10240 -and # Ignora file < 10KB (segnaposto)
                        $_.Extension -notin $sysExt -and 
                        $_.FullName -notmatch '\\Windows\\|\\\$Recycle\.Bin\\|\\System Volume Information\\' -and
                        $_.Name -notlike '~*' -and
                        -not ($_.Attributes -band [System.IO.FileAttributes]::Offline) # Ignora file OneDrive/Cloud non scaricati
                    }
                } else {
                    $fileList = Get-ChildItem -LiteralPath $cartella -Recurse -File -Include $extensions -Force -ErrorAction SilentlyContinue | Where-Object { 
                        $_.Length -gt 10240 -and # Ignora file < 10KB (segnaposto)
                        $_.Name -notlike '~*' -and
                        -not ($_.Attributes -band [System.IO.FileAttributes]::Offline) # Ignora file OneDrive/Cloud non scaricati
                    }
                }

                foreach ($f in $fileList) {
                    if ($SyncHash.Cancelled) { break }
                    $files += $f
                    $count++
                    $SyncHash.ScannedCount = $count
                }
            } catch {
                Log "ERRORE durante la lettura di '$cartella': ($_)"
            }
        }
        if ($SyncHash.Cancelled) { Log "Annullato."; return }
        
        Log "Fase 2: Raggruppamento per dimensione..."
        $gruppiDimensione = $files | Group-Object Length | Where-Object Count -gt 1
        $totaleDaProcessare = ($gruppiDimensione | Measure-Object -Property Count -Sum).Sum
        
        if ($null -eq $totaleDaProcessare -or $totaleDaProcessare -eq 0) {
            Log "Nessun file candidato (o nessun duplicato per dimensione)."
            $SyncHash.Result = @{ Esatti = @(); Simili = @() }
            return
        }
        
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
                    } catch {
                        Log "AVVISO: File non leggibile (in uso o protetto): $($f.Name)"
                    }
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
        try {
            if (-not (Test-Path (Split-Path -Parent $cachePath))) { New-Item -ItemType Directory -Path (Split-Path -Parent $cachePath) -Force | Out-Null }
            $cache.Values | Export-Csv -Path $cachePath -NoTypeInformation -Encoding UTF8
        } catch {
            Log "AVVISO: Impossibile salvare la cache. ($_)"
        }
        
        Log "Analisi completata! Trovati $($duplicatiEsatti.Count) gruppi identici."
        $SyncHash.Result = @{ Esatti = $duplicatiEsatti; Simili = $duplicatiSimili }
        
    } catch { 
        Log "ERRORE FATALE NEL MOTORE: $_" 
        $SyncHash.Result = $null
    } finally { 
        $SyncHash.HasFinished = $true
        $SyncHash.IsWorking = $false 
        [System.GC]::Collect()
    }
}

function Get-BestFile {
    param([Parameter(Mandatory=$true)][array]$Files)
    
    $candidati = $Files | ForEach-Object {
        $score = 0
        $name = $_.Name
        
        if ($name -match '\(\d+\)') { $score += 100 }
        if ($_.FullName -match 'vecchi')  { $score += 50 }
        if ($name -match 'Copia')   { $score += 30 }
        if ($name -match '\d{8} - '){ $score += 20 }

        if ($name -match '^(VID|IMG|AUD|REC|MVI|DSC|PXL|GOPR|DJI|MOBILE|PTT)_?[-_0-9]') { $score += 80 }
        if ($name -match '^\d{8}[_-]\d{6}') { $score += 80 }
        if ($name -match '^\d{8}[-_]\d+') { $score += 60 }
        if ($name -match '^(WhatsApp|WA|Screen Recording|Registrazione|Audio)') { $score += 40 }
        if ($name -match 'Y2Mate') { $score += 100 }
        
        $letters = ($name -replace '[^a-zA-Z]', '').Length
        $digits = ($name -replace '[^0-9]', '').Length
        if ($digits -gt 0 -and $letters -eq 0) { $score += 100 }
        elseif ($digits -gt $letters -and $digits -gt 3) { $score += 30 }

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
    
    $best = $candidati | Sort-Object -Property `
        @{Expression="Size";Descending=$true}, `
        @{Expression="LastWrite";Descending=$true}, `
        @{Expression="Creation";Descending=$true}, `
        @{Expression="Score";Descending=$false}, `
        @{Expression="PathLength";Descending=$false} | Select-Object -First 1
        
    return $best.File
}
Export-ModuleMember -Function Start-DuplicatiAnalysis, Get-BestFile
