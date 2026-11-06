<#
.SYNOPSIS
    Gestore delle azioni sui file e dei report per Cerca Doppioni PRO.
.DESCRIPTION
    Questo modulo si occupa di salvare i risultati dell'analisi in formato CSV
    e di spostare i file nel cestino o eliminarli definitivamente in base alle
    scelte dell'utente.
.NOTES
    Autore: Luca Negri
    Versione: 7.2
    Progetto: Cerca Doppioni PRO
#>

function Save-DuplicatiReport {
    <#
    .SYNOPSIS
        Esporta l'elenco dei file gestiti in un file CSV.
    .DESCRIPTION
        Prende in input l'array dei file selezionati e crea un report CSV con timestamp nella cartella output.
    .PARAMETER Anteprima
        Array di oggetti contenenti i dettagli dei file selezionati dall'utente.
    .PARAMETER BaseDir
        Percorso base in cui salvare la cartella 'output'.
    .INPUTS
        Nessuno.
    .OUTPUTS
        System.String (Il percorso completo del file CSV generato).
    .EXAMPLE
        $fileSelezionati = @([PSCustomObject]@{ Tipo="Esatto"; Nome="foto.jpg"; Dimensione="1.5 MB"; Percorso="C:\Foto\foto.jpg" })
        $percorsoReport = Save-DuplicatiReport -Anteprima $fileSelezionati -BaseDir "C:\cerca doppioni"
        
        Descrizione:
        Genera un report CSV in "C:\cerca doppioni\output\report_duplicati_YYYYMMDD_HHmmss.csv".
    #>
    param(
        [Parameter(Mandatory=$true)]
        [array]$Anteprima,
        
        [Parameter(Mandatory=$true)]
        [string]$BaseDir
    )
    
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
    <#
    .SYNOPSIS
        Esegue lo spostamento nel cestino o l'eliminazione definitiva dei file.
    .DESCRIPTION
        Elabora l'array di file selezionati e li sposta in una cartella 'cestino' 
        con timestamp, oppure li elimina definitivamente dal disco.
    .PARAMETER Anteprima
        Array di oggetti dei file selezionati dall'utente.
    .PARAMETER Elimina
        Booleano. Se $true, elimina definitivamente; se $false, sposta nel cestino.
    .PARAMETER BaseDir
        Percorso base per la creazione della cartella 'cestino'.
    .INPUTS
        Nessuno.
    .OUTPUTS
        System.Collections.Hashtable (Contiene il conteggio dei file gestiti e il log delle azioni).
    .EXAMPLE
        $fileSelezionati = @([PSCustomObject]@{ OggettoOriginale = (Get-Item "C:\Foto\copia.jpg") })
        $risultato = Invoke-DuplicatiAction -Anteprima $fileSelezionati -Elimina $false -BaseDir "C:\cerca doppioni"
        
        Descrizione:
        Sposta il file "copia.jpg" nella cartella "C:\cerca doppioni\output\cestino\" e restituisce un oggetto con il resoconto.
    #>
    param(
        [Parameter(Mandatory=$true)]
        [array]$Anteprima,
        
        [Parameter(Mandatory=$true)]
        [bool]$Elimina,
        
        [Parameter(Mandatory=$true)]
        [string]$BaseDir
    )
    
    $fileGestiti = 0
    $outDir = Join-Path $BaseDir "output\cestino\$(Get-Date -Format 'yyyyMMdd_HHmmss')"
    $logAzioni = @()
    
    foreach ($item in $Anteprima) {
        $scarto = $item.OggettoOriginale
        try {
            if ($Elimina) {
                Remove-Item -LiteralPath $scarto.FullName -Force -ErrorAction Stop
                $logAzioni += "[ELIMINATO] $($scarto.FullName)"
            } else {
                if (-not (Test-Path $outDir)) { New-Item -ItemType Directory -Path $outDir -Force | Out-Null }
                $nomeUnico = "$(Get-Random)_$($scarto.Name)"
                Move-Item -LiteralPath $scarto.FullName -Destination (Join-Path $outDir $nomeUnico) -Force -ErrorAction Stop
                $logAzioni += "[NEL CESTINO] $($scarto.FullName)"
            }
            $fileGestiti++
        } catch {
            $logAzioni += "[ERRORE] Impossibile spostare $($scarto.FullName): $_"
        }
    }
    return @{ Gestiti = $fileGestiti; Log = $logAzioni }
}
Export-ModuleMember -Function Save-DuplicatiReport, Invoke-DuplicatiAction
