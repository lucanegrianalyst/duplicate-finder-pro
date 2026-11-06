<#
.SYNOPSIS
    Scanning, hashing, and cache engine for Duplicate Finder PRO.
.NOTES
    Version: 11.0 (English Translation)
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

        foreach ($cartella in $Cartelle) {
            if ($SyncHash.Cancelled) { break }
            
            if (-not (Test-Path -LiteralPath $cartella)) {
                Log "ERROR: Folder '$cartella' is not reachable. Skipping."
                continue
            }

            Log "Scanning: $cartella"
            try {
                if ($TuttiIFile) {
                    $fileList = Get-ChildItem -LiteralPath $cartella -Recurse -File -Force -ErrorAction SilentlyContinue | Where-Object { 
                        $_.Length -gt 10240 -and 
                        $_.Extension -notin $sysExt -and 
                        $_.FullName -notmatch '\\Windows\\|\\\$Recycle\.Bin\\|\\System Volume Information\\' -and
                        $_.Name -notlike '~*' -and
                        -not ($_.Attributes -band [System.IO.FileAttributes]::Offline)
                    }
                } else {
                    $fileList = Get-ChildItem -LiteralPath $cartella -Recurse -File -Include $extensions -Force -ErrorAction SilentlyContinue | Where-Object { 
                        $_.Length -gt 10240 -and 
                        $_.Name -notlike '~*' -and
                        -not ($_.Attributes -band [System.IO.FileAttributes]::Offline)
                    }
                }

                foreach ($f in $fileList) {
                    if ($SyncHash.Cancelled) { break }
                    $files += $f
                    $count++
                    $SyncHash.ScannedCount = $count
                }
            } catch {
                Log "ERROR reading '$cartella': ($_)"
            }
        }
        if ($SyncHash.Cancelled) { Log "Cancelled."; return }
        
        Log "Phase 2: Grouping by size..."
        $gruppiDimensione = $files | Group-Object Length | Where-Object Count -gt 1
        $totaleDaProcessare = ($gruppiDimensione | Measure-Object -Property Count -Sum).Sum
        
        if ($null -eq $totaleDaProcessare -or $totaleDaProcessare -eq 0) {
            Log "No candidate files found (or no size duplicates)."
            $SyncHash.Result = @{ Esatti = @(); Simili = @() }
            return
        }
        
        $SyncHash.Total = $totaleDaProcessare
        Log "Phase 3: Calculating Hash for $totaleDaProcessare files..."
        
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
                        Log "WARNING: Unreadable file (in use or locked): $($f.Name)"
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
        $nomiDaCercare = $files | Group-Object Name | Where-Object Count -gt 1
        foreach ($g in $nomiDaCercare) {
            $dimensioniUniche = ($g.Group.Length | Select-Object -Unique).Count
            if ($dimensioniUniche -gt 1) { $duplicatiSimili += , $g.Group }
        }
        Log "Found $($duplicatiSimili.Count) similar groups."

        Log "Saving cache..."
        try {
            if (-not (Test-Path (Split-Path -Parent $cachePath))) { New-Item -ItemType Directory -Path (Split-Path -Parent $cachePath) -Force | Out-Null }
            $cache.Values | Export-Csv -Path $cachePath -NoTypeInformation -Encoding UTF8
        } catch {
            Log "WARNING: Could not save cache. ($_)"
        }
        
        Log "Analysis complete! Found $($duplicatiEsatti.Count) exact duplicate groups."
        $SyncHash.Result = @{ Esatti = $duplicatiEsatti; Simili = $duplicatiSimili }
        
    } catch { 
        Log "FATAL ENGINE ERROR: $_" 
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

        [PSCustomObject]@{ 
            File = $_; Score = $score; Size = $_.Length; 
            LastWrite = $_.LastWriteTime; Creation = $_.CreationTime; PathLength = $_.FullName.Length 
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
