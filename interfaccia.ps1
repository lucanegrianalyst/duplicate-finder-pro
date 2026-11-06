Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

$form = New-Object System.Windows.Forms.Form
$form.Text = "Trova e Gestisci Duplicati v1.0"
$form.Size = New-Object System.Drawing.Size(650, 550)
$form.StartPosition = "CenterScreen"
$form.FormBorderStyle = "FixedDialog"
$form.MaximizeBox = $false

$label = New-Object System.Windows.Forms.Label
$label.Text = "Cartella da analizzare:"
$label.Location = New-Object System.Drawing.Point(20, 20)
$label.AutoSize = $true
$form.Controls.Add($label)

$txtPercorso = New-Object System.Windows.Forms.TextBox
$txtPercorso.Location = New-Object System.Drawing.Point(20, 45)
$txtPercorso.Size = New-Object System.Drawing.Size(480, 20)
$form.Controls.Add($txtPercorso)

$btnSfoglia = New-Object System.Windows.Forms.Button
$btnSfoglia.Text = "Sfoglia..."
$btnSfoglia.Location = New-Object System.Drawing.Point(510, 43)
$btnSfoglia.Size = New-Object System.Drawing.Size(100, 25)
$form.Controls.Add($btnSfoglia)

$chkElimina = New-Object System.Windows.Forms.CheckBox
$chkElimina.Text = "Elimina definitivamente (se non spuntato, sposta nel cestino)"
$chkElimina.Location = New-Object System.Drawing.Point(20, 80)
$chkElimina.AutoSize = $true
$form.Controls.Add($chkElimina)

$btnAvvia = New-Object System.Windows.Forms.Button
$btnAvvia.Text = "AVVIA ANALISI E PULIZIA"
$btnAvvia.Location = New-Object System.Drawing.Point(20, 110)
$btnAvvia.Size = New-Object System.Drawing.Size(590, 40)
$btnAvvia.BackColor = [System.Drawing.Color]::LightGreen
$btnAvvia.Font = New-Object System.Drawing.Font("Segoe UI", 10, [System.Drawing.FontStyle]::Bold)
$form.Controls.Add($btnAvvia)

$txtLog = New-Object System.Windows.Forms.TextBox
$txtLog.Location = New-Object System.Drawing.Point(20, 160)
$txtLog.Size = New-Object System.Drawing.Size(590, 330)
$txtLog.Multiline = $true
$txtLog.ScrollBars = "Vertical"
$txtLog.ReadOnly = $true
$txtLog.Font = New-Object System.Drawing.Font("Consolas", 9)
$form.Controls.Add($txtLog)

function Scegli-Migliore {
    param([array]$Files)
    $candidati = $Files | ForEach-Object {
        $score = 0
        if ($_.FullName -match '\(\d+\)') { $score += 100 }
        if ($_.FullName -match 'vecchi')  { $score += 50 }
        if ($_.FullName -match 'Copia')   { $score += 30 }
        if ($_.FullName -match '\d{8} - '){ $score += 20 }
        [PSCustomObject]@{ File = $_; Score = $score; Lunghezza = $_.FullName.Length }
    }
    return ($candidati | Sort-Object Score, Lunghezza | Select-Object -First 1).File
}

$btnSfoglia.Add_Click({
    $folderBrowser = New-Object System.Windows.Forms.FolderBrowserDialog
    if ($folderBrowser.ShowDialog() -eq "OK") { $txtPercorso.Text = $folderBrowser.SelectedPath }
})

$btnAvvia.Add_Click({
    $cartella = $txtPercorso.Text
    if (-not (Test-Path $cartella)) { [System.Windows.Forms.MessageBox]::Show("Cartella non valida!"); return }
    $elimina = $chkElimina.Checked
    $btnAvvia.Enabled = $false
    $txtLog.Clear()
    
    $txtLog.AppendText("Analisi in corso in: $cartella...`r`n")
    $form.Refresh()
    
    $files = Get-ChildItem -LiteralPath $cartella -Recurse -File -Include *.mp3,*.flac,*.m4a,*.wav,*.jpg,*.png,*.mp4 -ErrorAction SilentlyContinue
    $txtLog.AppendText("Trovati $($files.Count) file. Ricerca dei candidati...`r`n")
    $form.Refresh()
    
    $gruppiDimensione = $files | Group-Object Length | Where-Object Count -gt 1
    $duplicati = @()
    $cont = 0
    
    foreach ($g in $gruppiDimensione) {
        $cont++
        $txtLog.AppendText("Calcolo hash per gruppo dimensione $cont di $($gruppiDimensione.Count)...`r`n")
        [System.Windows.Forms.Application]::DoEvents()
        
        $hashMap = @{}
        foreach ($f in $g.Group) {
            $h = (Get-FileHash -LiteralPath $f.FullName -Algorithm SHA256).Hash
            if (-not $hashMap.ContainsKey($h)) { $hashMap[$h] = @() }
            $hashMap[$h] += $f
        }
        foreach ($k in $hashMap.Keys) {
            if ($hashMap[$k].Count -gt 1) { $duplicati += , $hashMap[$k] }
        }
    }
    
    $txtLog.AppendText("Trovati $($duplicati.Count) gruppi di file identici (SHA-256).`r`n" + ("=" * 50) + "`r`n")
    $form.Refresh()
    
    $fileGestiti = 0
    $spazioLiberato = 0
    $cestinoBase = "C:\cerca doppioni\output\cestino\$(Get-Date -Format 'yyyyMMdd_HHmmss')"
    
    foreach ($gruppo in $duplicati) {
        $daTenere = Scegli-Migliore -Files $gruppo
        $daScartare = $gruppo | Where-Object { $_.FullName -ne $daTenere.FullName }
        
        foreach ($scarto in $daScartare) {
            $spazioLiberato += $scarto.Length
            if ($elimina) {
                Remove-Item -LiteralPath $scarto.FullName -Force -ErrorAction SilentlyContinue
                $txtLog.AppendText("[ELIMINATO] $($scarto.FullName)`r`n")
            } else {
                if (-not (Test-Path $cestinoBase)) { New-Item -ItemType Directory -Path $cestinoBase -Force | Out-Null }
                $nomeUnico = "$(Get-Random)_$($scarto.Name)"
                Move-Item -LiteralPath $scarto.FullName -Destination (Join-Path $cestinoBase $nomeUnico) -Force -ErrorAction SilentlyContinue
                $txtLog.AppendText("[NEL CESTINO] $($scarto.FullName)`r`n")
            }
            $fileGestiti++
            $txtLog.SelectionStart = $txtLog.Text.Length
            $txtLog.ScrollToCaret()
            [System.Windows.Forms.Application]::DoEvents()
        }
    }
    
    $mb = [math]::Round($spazioLiberato / 1MB, 2)
    $txtLog.AppendText("`r`n" + ("=" * 50) + "`r`n")
    $txtLog.AppendText("FINITO! File gestiti: $fileGestiti`r`nSpazio recuperato: $mb MB`r`n")
    $txtLog.SelectionStart = $txtLog.Text.Length
    $txtLog.ScrollToCaret()
    $btnAvvia.Enabled = $true
})

$form.Add_Shown({ $form.Activate() })
[void]$form.ShowDialog()
