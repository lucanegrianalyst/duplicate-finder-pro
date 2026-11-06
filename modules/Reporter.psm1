<#
.SYNOPSIS
    Actions and reporting manager for Duplicate Finder PRO.
.NOTES
    Version: 11.0 (English Translation)
#>

function Save-DuplicatiReport {
    param([Parameter(Mandatory=$true)][array]$Anteprima, [Parameter(Mandatory=$true)][string]$BaseDir)
    
    $reportRows = @()
    foreach ($item in $Anteprima) {
        $reportRows += [PSCustomObject]@{
            AnalysisDate = (Get-Date -Format "yyyy-MM-dd HH:mm:ss")
            Type = $item.Tipo
            FileName = $item.Nome
            SizeMB = $item.Dimensione.Replace(" MB", "")
            FullPath = $item.Percorso
        }
    }
    if ($reportRows.Count -eq 0) { return "No files selected" }
    $outDir = Join-Path $BaseDir "output"
    if (-not (Test-Path $outDir)) { New-Item -ItemType Directory -Path $outDir -Force | Out-Null }
    $reportPath = Join-Path $outDir "duplicate_report_$(Get-Date -Format 'yyyyMMdd_HHmmss').csv"
    $reportRows | Export-Csv -Path $reportPath -NoTypeInformation -Encoding UTF8
    return $reportPath
}

function Invoke-DuplicatiAction {
    param([Parameter(Mandatory=$true)][array]$Anteprima, [Parameter(Mandatory=$true)][bool]$Elimina, [Parameter(Mandatory=$true)][string]$BaseDir)
    
    $fileGestiti = 0
    $spazioLiberato = 0
    $outDir = Join-Path $BaseDir "output\trash\$(Get-Date -Format 'yyyyMMdd_HHmmss')"
    $logAzioni = @()
    
    $logDir = Join-Path $BaseDir "output"
    if (-not (Test-Path $logDir)) { New-Item -ItemType Directory -Path $logDir -Force | Out-Null }
    $logFile = Join-Path $logDir "operations.log"
    
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    "`n===== OPERATION ON $timestamp (Mode: $(if ($Elimina) { 'DELETE' } else { 'TRASH' })) =====" | Add-Content -LiteralPath $logFile -Encoding UTF8

    foreach ($item in $Anteprima) {
        $scarto = $item.OggettoOriginale
        
        if (-not (Test-Path -LiteralPath $scarto.FullName)) {
            $logAzioni += "[SKIPPED] File not found: $($scarto.FullName)"
            continue
        }

        $spazioLiberato += $scarto.Length
        
        try {
            if ($Elimina) {
                Remove-Item -LiteralPath $scarto.FullName -Force -ErrorAction Stop
                $logAzioni += "[DELETED] $($scarto.FullName)"
                "$timestamp - DELETED: $($scarto.FullName)" | Add-Content -LiteralPath $logFile -Encoding UTF8
            } else {
                if (-not (Test-Path $outDir)) { New-Item -ItemType Directory -Path $outDir -Force | Out-Null }
                $nomeUnico = "$(Get-Random)_$($scarto.Name)"
                $destinazione = Join-Path $outDir $nomeUnico
                Move-Item -LiteralPath $scarto.FullName -Destination $destinazione -Force -ErrorAction Stop
                $logAzioni += "[IN TRASH] $($scarto.FullName)"
                "$timestamp - MOVED TO TRASH: $($scarto.FullName) -> $destinazione" | Add-Content -LiteralPath $logFile -Encoding UTF8
            }
            $fileGestiti++
        } catch {
            $logAzioni += "[ERROR] File in use or locked: $($scarto.Name) - $_"
            "$timestamp - ERROR: $($scarto.FullName) - $_" | Add-Content -LiteralPath $logFile -Encoding UTF8
        }
    }
    
    "$timestamp - Summary: $fileGestiti files processed. Space freed: $spazioLiberato bytes." | Add-Content -LiteralPath $logFile -Encoding UTF8
    
    $destinazioneFinale = if ($Elimina) { "Permanent deletion" } else { $outDir }
    return @{ Gestiti = $fileGestiti; Log = $logAzioni; Spazio = $spazioLiberato; Destinazione = $destinazioneFinale }
}
Export-ModuleMember -Function Save-DuplicatiReport, Invoke-DuplicatiAction
