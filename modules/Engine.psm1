<#
.SYNOPSIS
    Scanning, hashing, and cache engine for Duplicate Finder PRO.
.NOTES
    Version: 11.20 (Fast Stack Traversal & MD5 Hashing)
#>

function Format-SizeLocal {
    param([long]$Bytes)
    if ($Bytes -ge 1GB) { return "{0:N2} GB" -f ($Bytes / 1GB) }
    elseif ($Bytes -ge 1MB) { return "{0:N2} MB" -f ($Bytes / 1MB) }
    else { return "{0:N2} KB" -f ($Bytes / 1KB) }
}

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
            Log "ERROR: No valid folders provided."; 
            $SyncHash.Result = @{ Esatti = @(); Simili = @() }
            return 
        }

        $extensions = @()
        if ($TuttiIFile) {
            Log "UNIVERSAL MODE: Searching for ALL file types."
        } else {
            if ($null -eq $EstensioniSelezionate -or $EstensioniSelezionate.Count -eq 0) {
                Log "ERROR: No file types selected for analysis."
                $SyncHash.Result = @{ Esatti = @(); Simili = @() }
                return
            }
            $extensions = $EstensioniSelezionate | ForEach-Object { if ($_ -notmatch '^\*') { "*$_" } else { $_ } }
            Log "Selected categories: $($extensions -join ', ')"
        }

        $cachePath = Join-Path $BaseDir "output\cache_hash.csv"
        $cache = @{}
        if (Test-Path $cachePath) {
            Log "Loading cache..."
            try {
                $cachedRows = Import-Csv -LiteralPath $cachePath -ErrorAction Stop
                foreach ($row in $cachedRows) { $cache[$row.Path] = $row }
                Log "Cache loaded: $($cache.Count) files."
            } catch {
                Log "WARNING: Could not read cache. Ignoring. ($_)"
            }
        }
        
        Log "Phase 1: Searching files..."
        $files = @()
        $count = 0
        $sysExt = @('.exe','.dll','.sys','.tmp','.log','.ini','.lnk','.bat','.cmd','.msi','.cab','.dat')

        $targetExts = $extensions | ForEach-Object { $_.TrimStart('*') }

        foreach ($cartella in $Cartelle) {
            if ($SyncHash.Cancelled) { break }
            if (-not (Test-Path -LiteralPath $cartella)) { continue }

            Log "Scanning: $cartella"
            
            $stack = New-Object System.Collections.Stack
            $stack.Push($cartella)

            while ($stack.Count -gt 0) {
                if ($SyncHash.Cancelled) { break }
                $currentDir = $stack.Pop()

                try {
                    foreach ($rawPath in [System.IO.Directory]::EnumerateFiles($currentDir, '*')) {
                        if ($SyncHash.Cancelled) { break }
                        $ext = [System.IO.Path]::GetExtension($rawPath).ToLower()
                        $fileName = [System.IO.Path]::GetFileName($rawPath)

                        if ($ext -in $sysExt -or $fileName -like '~*') { continue }
                        if (-not $TuttiIFile -and $ext -notin $targetExts) { continue }

                        $f = New-Object System.IO.FileInfo($rawPath)
                        if ($f.Length -gt 10240 -and -not ($f.Attributes -band [System.IO.FileAttributes]::Offline)) {
                            $files += $f
                            $count++
                            $SyncHash.ScannedCount = $count
                        }
                    }

                    foreach ($dir in [System.IO.Directory]::EnumerateDirectories($currentDir)) {
                        $stack.Push($dir)
                    }
                } catch { }
            }
        }
        if ($SyncHash.Cancelled) { Log "Cancelled."; return }
        
        Log "Phase 2: Grouping by size..."
        $gruppiDimensione = $files | Group-Object Length | Where-Object Count -gt 1
        $totaleDaProcessare = ($gruppiDimensione | Measure-Object -Property Count -Sum).Sum
        
        if ($null -eq $totaleDaProcessare -or $totaleDaProcessare -eq 0) {
            Log "No candidate files found."
            $SyncHash.Result = @{ Esatti = @(); Simili = @() }
            return
        }
        
        $SyncHash.Total = $totaleDaProcessare
        Log "Phase 3: Calculating Hash (MD5) for $totaleDaProcessare files..."
        
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
                        # FIX VELOCITÀ: MD5 al posto di SHA256
                        $h = (Get-FileHash -LiteralPath $f.FullName -Algorithm MD5 -ErrorAction Stop).Hash
                        if ($h) { $cache[$f.FullName] = [PSCustomObject]@{ Path = $f.FullName; Data = $dataModifica; Hash = $h } }
                    } catch {
                        Log "WARNING: Unreadable file: $($f.Name)"
                    }
                }
                if ($h) {
                    if (-not $hashMap.ContainsKey($h)) { $hashMap[$h] = @() }
                    $hashMap[$h] += $f
                }
            }
            foreach ($k in $hashMap.Keys) { if ($hashMap[$k].Count -gt 1) { $duplicatiEsatti += , $hashMap[$k] } }
        }
        
        Log "Phase 4: Searching for files with same name but different sizes..."
        $duplicatiSimili = @()
        $nameMap = @{}
        foreach ($f in $files) {
            if ($SyncHash.Cancelled) { break }
            if (-not $nameMap.ContainsKey($f.Name)) { $nameMap[$f.Name] = @() }
            $nameMap[$f.Name] += $f
        }
        
        if (-not $SyncHash.Cancelled) {
            foreach ($k in $nameMap.Keys) {
                if ($SyncHash.Cancelled) { break }
                $group = $nameMap[$k]
                if ($group.Count -gt 1) {
                    $uniqueSizes = ($group | Select-Object -ExpandProperty Length -Unique).Count
                    if ($uniqueSizes -gt 1) { $duplicatiSimili += , $group }
                }
            }
        }
        Log "Found $($duplicatiSimili.Count) similar groups."

        Log "Saving cache..."
        try {
            if (-not (Test-Path (Split-Path -Parent $cachePath))) { New-Item -ItemType Directory -Path (Split-Path -Parent $cachePath) -Force | Out-Null }
            $cache.Values | Export-Csv -Path $cachePath -NoTypeInformation -Encoding UTF8
        } catch { }

        Log "Preparing preview data..."
        $anteprimaEsatti = @(); $anteprimaSimili = @(); $groupIndex = 1
        
        foreach ($gruppo in $duplicatiEsatti) {
            if ($SyncHash.Cancelled) { break }
            $daTenere = Get-BestFile -Files $gruppo
            foreach ($file in $gruppo) {
                $isOriginal = ($file.FullName -eq $daTenere.FullName)
                $dataMod = $file.LastWriteTime.ToString("MM/dd/yy HH:mm"); $dataCre = $file.CreationTime.ToString("MM/dd/yy HH:mm")
                $anteprimaEsatti += [PSCustomObject]@{
                    Gruppo = $groupIndex; Azione = if ($isOriginal) { "KEEP (Original)" } else { "DELETE (Copy)" }
                    Nome = $file.Name; Dimensione = Format-SizeLocal -Bytes $file.Length
                    Modifica = if ($isOriginal) { "$dataMod *" } else { $dataMod }; Creazione = if ($isOriginal) { "$dataCre *" } else { $dataCre }
                    Percorso = $file.FullName; OggettoOriginale = $file; Tipo = "Exact"; IsOriginal = $isOriginal
                }
            }
            $groupIndex++
        }
        
        foreach ($gruppo in $duplicatiSimili) {
            if ($SyncHash.Cancelled) { break }
            $bestSimilar = $gruppo | Sort-Object Length -Descending | Select-Object -First 1
            $sizeMax = $bestSimilar.Length
            foreach ($file in $gruppo) {
                $isBest = ($file.FullName -eq $bestSimilar.FullName)
                $dataMod = $file.LastWriteTime.ToString("MM/dd/yy HH:mm"); $dataCre = $file.CreationTime.ToString("MM/dd/yy HH:mm")
                $diffPerc = 0; if (-not $isBest) { $diffPerc = [math]::Round(($file.Length - $sizeMax) / $sizeMax * 100) }
                $dimensioneStr = Format-SizeLocal -Bytes $file.Length; if (-not $isBest) { $dimensioneStr += " ($diffPerc%)" }
                $anteprimaSimili += [PSCustomObject]@{
                    Gruppo = $groupIndex; Azione = if ($isBest) { "KEEP (Higher Quality)" } else { "EVALUATE (Lower Quality)" }
                    Nome = $file.Name; Dimensione = $dimensioneStr; Modifica = $dataMod; Creazione = $dataCre
                    Percorso = $file.FullName; OggettoOriginale = $file; Tipo = "Similar"; IsOriginal = $isBest
                }
            }
            $groupIndex++
        }

        Log "Analysis complete! Found $($duplicatiEsatti.Count) exact duplicate groups."
        $SyncHash.Result = @{ Esatti = @($anteprimaEsatti); Simili = @($anteprimaSimili) }
        
    } catch { 
        Log "FATAL ENGINE ERROR: $_" 
        $SyncHash.Result = @{ Esatti = @(); Simili = @() }
    } finally { 
        $SyncHash.HasFinished = $true
        $SyncHash.IsWorking = $false 
        [System.GC]::Collect()
    }
}

function Get-BestFile {
    param([Parameter(Mandatory=$true)][array]$Files)
    
    $candidati = $Files | ForEach-Object {
        $score = 0; $name = $_.Name
        if ($name -match '\(\d+\)') { $score += 100 }
        if ($_.FullName -match 'old')  { $score += 50 }
        if ($name -match 'Copy')   { $score += 30 }
        if ($name -match '\d{8} - '){ $score += 20 }
        if ($name -match '^(VID|IMG|AUD|REC|MVI|DSC|PXL|GOPR|DJI|MOBILE|PTT)_?[-_0-9]') { $score += 80 }
        if ($name -match '^\d{8}[_-]\d{6}') { $score += 80 }
        if ($name -match '^\d{8}[-_]\d+') { $score += 60 }
        if ($name -match '^(WhatsApp|WA|Screen Recording|Record)') { $score += 40 }
        if ($name -match 'Y2Mate') { $score += 100 }
        $letters = ($name -replace '[^a-zA-Z]', '').Length
        $digits = ($name -replace '[^0-9]', '').Length
        if ($digits -gt 0 -and $letters -eq 0) { $score += 100 }
        elseif ($digits -gt $letters -and $digits -gt 3) { $score += 30 }
        if ($name -match ' ') { $score -= 20 }

        [PSCustomObject]@{ File = $_; Score = $score; Size = $_.Length; LastWrite = $_.LastWriteTime.ToString("yyyyMMddHHmm"); Creation = $_.CreationTime.ToString("yyyyMMddHHmm"); PathLength = $_.FullName.Length }
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
