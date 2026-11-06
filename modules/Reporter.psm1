function Write-SezioneConsole {
    param([string]$Titolo, [array]$Gruppi, [int]$MaxGruppi = 30)
    Write-Host ""
    Write-Host ("=" * 70) -ForegroundColor Yellow
    Write-Host " $Titolo" -ForegroundColor Yellow
    Write-Host ("=" * 70) -ForegroundColor Yellow
    if (-not $Gruppi -or $Gruppi.Count -eq 0) { Write-Host "   Nessun duplicato in questa categoria." -ForegroundColor Green; return }
    $i = 0
    foreach ($g in $Gruppi) {
        $i++
        if ($i -gt $MaxGruppi) {
            Write-Host ("   ... altri {0} gruppi non mostrati a schermo (vedi report file)" -f ($Gruppi.Count - $MaxGruppi)) -ForegroundColor DarkGray
            break
        }
        $riga = "[{0}] {1}  -  {2} file" -f $i, $g.Chiave, $g.Conteggio
        Write-Host $riga -ForegroundColor Magenta
        foreach ($path in $g.Files) { Write-Host ("      $path") -ForegroundColor Gray }
    }
    $tot = ($Gruppi | Measure-Object -Property Conteggio -Sum).Sum
    Write-Host ""
    Write-Host ("   Gruppi: {0}   File coinvolti: {1}" -f $Gruppi.Count, $tot) -ForegroundColor Cyan
}
function Save-Report {
    param([string]$Percorso, [string]$CartellaAnalizzata, [hashtable]$Sezioni)
    $dir = Split-Path -Parent $Percorso
    if (-not (Test-Path -LiteralPath $dir)) { New-Item -ItemType Directory -Path $dir -Force | Out-Null }
    $sb = [System.Text.StringBuilder]::new()
    [void]$sb.AppendLine("REPORT DOPPIONI")
    [void]$sb.AppendLine("Data: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')")
    [void]$sb.AppendLine("Cartella: $CartellaAnalizzata")
    [void]$sb.AppendLine(("=" * 70))
    foreach ($nomeSezione in $Sezioni.Keys) {
        [void]$sb.AppendLine("")
        [void]$sb.AppendLine("### $nomeSezione ###")
        $gruppi = $Sezioni[$nomeSezione]
        if (-not $gruppi -or $gruppi.Count -eq 0) { [void]$sb.AppendLine("   Nessun duplicato."); continue }
        foreach ($g in $gruppi) {
            [void]$sb.AppendLine("")
            $riga = "[{0}]  {1} file  ({2} byte)" -f $g.Chiave, $g.Conteggio, $g.Dimensione
            [void]$sb.AppendLine($riga)
            foreach ($p in $g.Files) { [void]$sb.AppendLine("    $p") }
        }
    }
    Set-Content -LiteralPath $Percorso -Value $sb.ToString() -Encoding UTF8
    Write-Host ""
    Write-Host "Report salvato in: $Percorso" -ForegroundColor Cyan
}
function Save-CSV {
    param([string]$Percorso, [hashtable]$Sezioni)
    $rows = @()
    foreach ($nomeSezione in $Sezioni.Keys) {
        foreach ($g in $Sezioni[$nomeSezione]) {
            foreach ($p in $g.Files) {
                $rows += [PSCustomObject]@{
                    Categoria = $nomeSezione; Chiave = $g.Chiave; Conteggio = $g.Conteggio
                    Dimensione = $g.Dimensione; Percorso = $p
                }
            }
        }
    }
    if ($rows.Count -gt 0) {
        $rows | Export-Csv -LiteralPath $Percorso -NoTypeInformation -Encoding UTF8
        Write-Host "CSV salvato in: $Percorso" -ForegroundColor Cyan
    }
}
function Write-RiepilogoFinale {
    param([hashtable]$Sezioni)
    Write-Host ""
    Write-Host ("=" * 70) -ForegroundColor Green
    Write-Host " RIEPILOGO FINALE" -ForegroundColor Green
    Write-Host ("=" * 70) -ForegroundColor Green
    foreach ($nome in $Sezioni.Keys) {
        $gruppi = $Sezioni[$nome]
        if (-not $gruppi -or $gruppi.Count -eq 0) {
            Write-Host ("   {0}: nessun duplicato" -f $nome) -ForegroundColor DarkGray
            continue
        }
        $copie = 0; $spazio = 0
        foreach ($g in $gruppi) { $copie += ($g.Conteggio - 1); $spazio += $g.Dimensione * ($g.Conteggio - 1) }
        Write-Host ("   {0}" -f $nome) -ForegroundColor Cyan
        Write-Host ("      Gruppi: {0}   Copie extra: {1}   Spazio recuperabile: {2:N2} MB" -f $gruppi.Count, $copie, ($spazio/1MB)) -ForegroundColor Gray
    }
}
Export-ModuleMember -Function Write-SezioneConsole, Save-Report, Save-CSV, Write-RiepilogoFinale
