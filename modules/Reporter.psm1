<#
.SYNOPSIS
    Gestore delle azioni sui file e dei report per Cerca Doppioni PRO.
.NOTES
    Versione: 8.5
#>

function Save-DuplicatiReport {
    param([Parameter(Mandatory=$true)][array]$Anteprima, [Parameter(Mandatory=$true)][string]$BaseDir)
    
    $reportRows = @()
    foreach ($item in $Anteprima) {
        $reportRows += [PSCustomObject]@{
            Data_Analisi = (Get-Date -Format "yyyy-MM-dd HH:mm:ss")
            Tipo = $item.Tipo
            Nome_File = $item.Nome
            Dimensione_MB = $item.Dimensione.Replace(" MB", "")
            Percorso_Completo = $item.Percorso
        }
    }
    if ($reportRows.Count -eq 0) { return "Nessun file selezionato" }
    $outDir = Join-Path $BaseDir "output"
    if (-not (Test-Path $outDir)) { New-Item -ItemType Directory -Path $outDir -Force | Out-Null }
    $reportPath = Join-Path $outDir "report_duplicati_$(Get-Date -Format 'yyyyMMdd_HHmmss').csv"
    $reportRows | Export-Csv -Path $reportPath -NoTypeInformation -Encoding UTF8
    return $reportPath
}

function Invoke-DuplicatiAction {
    param([Parameter(Mandatory=$true)][array]$Anteprima, [Parameter(Mandatory=$true)][bool]$Elimina, [Parameter(Mandatory=$true)][string]$BaseDir)
    
    $fileGestiti = 0
    $spazioLiberato = 0
    $outDir = Join-Path $BaseDir "output\cestino\$(Get-Date -Format 'yyyyMMdd_HHmmss')"
    $logAzioni = @()
    
    $logDir = Join-Path $BaseDir "output"
    if (-not (Test-Path $logDir)) { New-Item -ItemType Directory -Path $logDir -Force | Out-Null }
    $logFile = Join-Path $logDir "operazioni.log"
    
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    "`n===== OPERAZIONE DEL $timestamp (Modalità: $(if ($Elimina) { 'ELIMINA' } else { 'CESTINO' })) =====" | Add-Content -LiteralPath $logFile -Encoding UTF8

    foreach ($item in $Anteprima) {
        $scarto = $item.OggettoOriginale
        
        # Controllo di sicurezza: il file esiste ancora?
        if (-not (Test-Path -LiteralPath $scarto.FullName)) {
            $logAzioni += "[SALTATO] File non trovato: $($scarto.FullName)"
            continue
        }

        $spazioLiberato += $scarto.Length
        
        try {
            if ($Elimina) {
                Remove-Item -LiteralPath $scarto.FullName -Force -ErrorAction Stop
                $logAzioni += "[ELIMINATO] $($scarto.FullName)"
                "$timestamp - ELIMINATO: $($scarto.FullName)" | Add-Content -LiteralPath $logFile -Encoding UTF8
            } else {
                if (-not (Test-Path $outDir)) { New-Item -ItemType Directory -Path $outDir -Force | Out-Null }
                $nomeUnico = "$(Get-Random)_$($scarto.Name)"
                $destinazione = Join-Path $outDir $nomeUnico
                Move-Item -LiteralPath $scarto.FullName -Destination $destinazione -Force -ErrorAction Stop
                $logAzioni += "[NEL CESTINO] $($scarto.FullName)"
                "$timestamp - SPOSTATO: $($scarto.FullName) -> $destinazione" | Add-Content -LiteralPath $logFile -Encoding UTF8
            }
            $fileGestiti++
        } catch {
            # Gestione del file bloccato (es. in uso da un altro programma)
            $logAzioni += "[ERRORE] File in uso o protetto: $($scarto.Name) - $_"
            "$timestamp - ERRORE: $($scarto.FullName) - $_" | Add-Content -LiteralPath $logFile -Encoding UTF8
        }
    }
    
    "$timestamp - Riepilogo: $fileGestiti file gestiti. Spazio recuperato: $spazioLiberato byte." | Add-Content -LiteralPath $logFile -Encoding UTF8
    
    $destinazioneFinale = if ($Elimina) { "Eliminazione definitiva" } else { $outDir }
    return @{ Gestiti = $fileGestiti; Log = $logAzioni; Spazio = $spazioLiberato; Destinazione = $destinazioneFinale }
}
Export-ModuleMember -Function Save-DuplicatiReport, Invoke-DuplicatiAction
