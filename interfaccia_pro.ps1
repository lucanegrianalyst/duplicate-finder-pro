Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

$form = New-Object System.Windows.Forms.Form
$form.Text = "Trova e Gestisci Duplicati PRO v4.0 (Incrementale)"
$form.Size = New-Object System.Drawing.Size(700, 650)
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
$txtPercorso.Size = New-Object System.Drawing.Size(520, 20)
$form.Controls.Add($txtPercorso)

$btnSfoglia = New-Object System.Windows.Forms.Button
$btnSfoglia.Text = "Sfoglia..."
$btnSfoglia.Location = New-Object System.Drawing.Point(550, 43)
$btnSfoglia.Size = New-Object System.Drawing.Size(100, 25)
$form.Controls.Add($btnSfoglia)

$chkElimina = New-Object System.Windows.Forms.CheckBox
$chkElimina.Text = "Elimina definitivamente (se non spuntato, sposta nel cestino)"
$chkElimina.Location = New-Object System.Drawing.Point(20, 80)
$chkElimina.AutoSize = $true
$form.Controls.Add($chkElimina)

$btnAvvia = New-Object System.Windows.Forms.Button
$btnAvvia.Text = "1. ANALIZZA CARTELLA (Trova Duplicati)"
$btnAvvia.Location = New-Object System.Drawing.Point(20, 110)
$btnAvvia.Size = New-Object System.Drawing.Size(630, 40)
$btnAvvia.BackColor = [System.Drawing.Color]::LightBlue
$btnAvvia.Font = New-Object System.Drawing.Font("Segoe UI", 10, [System.Drawing.FontStyle]::Bold)
$form.Controls.Add($btnAvvia)

$btnAnnulla = New-Object System.Windows.Forms.Button
$btnAnnulla.Text = "ANNULLA OPERAZIONE"
$btnAnnulla.Location = New-Object System.Drawing.Point(20, 160)
$btnAnnulla.Size = New-Object System.Drawing.Size(150, 30)
$btnAnnulla.Enabled = $false
$btnAnnulla.BackColor = [System.Drawing.Color]::LightCoral
$form.Controls.Add($btnAnnulla)

$pb = New-Object System.Windows.Forms.ProgressBar
$pb.Location = New-Object System.Drawing.Point(180, 165)
$pb.Size = New-Object System.Drawing.Size(470, 20)
$form.Controls.Add($pb)

$txtLog = New-Object System.Windows.Forms.TextBox
$txtLog.Location = New-Object System.Drawing.Point(20, 210)
$txtLog.Size = New-Object System.Drawing.Size(630, 370)
$txtLog.Multiline = $true
$txtLog.ScrollBars = "Vertical"
$txtLog.ReadOnly = $true
$txtLog.Font = New-Object System.Drawing.Font("Consolas", 9)
$form.Controls.Add($txtLog)

$SyncHash = [hashtable]::Synchronized(@{})
$SyncHash.LogQueue = [System.Collections.Concurrent.ConcurrentQueue[string]]::new()
$SyncHash.IsWorking = $false
$SyncHash.Cancelled = $false
$SyncHash.Progress = 0
$SyncHash.Total = 0
$SyncHash.Result = $null

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

$btnAnnulla.Add_Click({
    $SyncHash.Cancelled = $true
    $txtLog.AppendText("`r`nRichiesta di annullamento immediato...`r`n")
})

$timer = New-Object System.Windows.Forms.Timer
$timer.Interval = 200
$timer.Add_Tick({
    $msg = ""
    while ($SyncHash.LogQueue.TryDequeue([ref]$msg)) {
        $txtLog.AppendText("$msg`r`n")
        $txtLog.SelectionStart = $txtLog.Text.Length
        $txtLog.ScrollToCaret()
    }
    
    if ($SyncHash.Total -gt 0) {
        if ($pb.Style -ne "Blocks") { $pb.Style = "Blocks" }
        $pb.Maximum = $SyncHash.Total
        $pb.Value = [math]::Min($SyncHash.Progress, $SyncHash.Total)
    }

    if (-not $SyncHash.IsWorking -and $SyncHash.Total -gt 0 -and $null -ne $SyncHash.Result) {
        $timer.Stop()
        $btnAvvia.Enabled = $true
        $btnAnnulla.Enabled = $false
        $btnSfoglia.Enabled = $true
        $pb.Value = $pb.Maximum
        
        $duplicati = $SyncHash.Result
        $SyncHash.Result = $null
        
        if ($duplicati.Count -eq 0) {
            [System.Windows.Forms.MessageBox]::Show("Nessun duplicato trovato!")
            return
        }
        
        $anteprima = @()
        $reportRows = @()
        foreach ($gruppo in $duplicati) {
            $daTenere = Scegli-Migliore -Files $gruppo
            foreach ($file in $gruppo) {
                $azione = if ($file.FullName -eq $daTenere.FullName) { "TENERE (Originale)" } else { "ELIMINARE (Copia)" }
                $anteprima += [PSCustomObject]@{
                    Azione = $azione; Nome = $file.Name; Dimensione = "{0:N2} MB" -f ($file.Length / 1MB)
                    Percorso = $file.FullName; Originale = $daTenere.FullName; OggettoOriginale = $file
                }
                $reportRows += [PSCustomObject]@{
                    Data_Analisi = (Get-Date -Format "yyyy-MM-dd HH:mm:ss")
                    Azione = $azione
                    Nome_File = $file.Name
                    Dimensione_MB = [math]::Round($file.Length / 1MB, 2)
                    Percorso_Completo = $file.FullName
                    File_Originale_Consigliato = $daTenere.FullName
                }
            }
        }
        
        # Salva il report CSV
        $reportPath = "C:\cerca doppioni\output\report_duplicati_$(Get-Date -Format 'yyyyMMdd_HHmmss').csv"
        $reportRows | Export-Csv -Path $reportPath -NoTypeInformation -Encoding UTF8
        $txtLog.AppendText("`r`nReport salvato in: $reportPath`r`n")
        
        $formAnteprima = New-Object System.Windows.Forms.Form
        $formAnteprima.Text = "Anteprima: Cosa vuoi fare?"
        $formAnteprima.Size = New-Object System.Drawing.Size(1100, 620)
        $formAnteprima.StartPosition = "CenterParent"
        
        $lblInfo = New-Object System.Windows.Forms.Label
        $lblInfo.Text = "Suggerimento: fai DOPPIO CLIC su una riga rossa per aprire le due cartelle e confrontare i file."
        $lblInfo.Location = New-Object System.Drawing.Point(10, 10)
        $lblInfo.AutoSize = $true
        $lblInfo.ForeColor = [System.Drawing.Color]::Blue
        $formAnteprima.Controls.Add($lblInfo)
        
        $listView = New-Object System.Windows.Forms.ListView
        $listView.Location = New-Object System.Drawing.Point(10, 35)
        $listView.Size = New-Object System.Drawing.Size(1060, 480)
        $listView.View = "Details"
        $listView.FullRowSelect = $true
        $listView.GridLines = $true
        $listView.HideSelection = $false
        
        $listView.Columns.Add("Azione", 150) | Out-Null
        $listView.Columns.Add("Nome File", 350) | Out-Null
        $listView.Columns.Add("Dimensione", 100) | Out-Null
        $listView.Columns.Add("Percorso", 450) | Out-Null
        
        $listView.BeginUpdate()
        foreach ($item in $anteprima) {
            $lvItem = New-Object System.Windows.Forms.ListViewItem($item.Azione)
            $lvItem.SubItems.Add($item.Nome) | Out-Null
            $lvItem.SubItems.Add($item.Dimensione) | Out-Null
            $lvItem.SubItems.Add($item.Percorso) | Out-Null
            if ($item.Azione -like "TENERE*") { $lvItem.ForeColor = [System.Drawing.Color]::Green }
            else { $lvItem.ForeColor = [System.Drawing.Color]::Red }
            $lvItem.Tag = $item
            $listView.Items.Add($lvItem) | Out-Null
        }
        $listView.EndUpdate()
        
        $listView.Add_MouseDoubleClick({
            param($sender, $e)
            $hit = $listView.HitTest($e.X, $e.Y)
            if ($hit.Item) {
                $item = $hit.Item.Tag
                if ($item.Azione -like "ELIMINARE*") {
                    Start-Process explorer.exe -ArgumentList "/select,`"$($item.Percorso)`""
                    Start-Process explorer.exe -ArgumentList "/select,`"$($item.Originale)`""
                }
            }
        })
        
        $formAnteprima.Controls.Add($listView)
        
        $btnProcedi = New-Object System.Windows.Forms.Button
        $btnProcedi.Text = "PROCEDI CON LA PULIZIA"
        $btnProcedi.Location = New-Object System.Drawing.Point(10, 525)
        $btnProcedi.Size = New-Object System.Drawing.Size(500, 40)
        $btnProcedi.BackColor = [System.Drawing.Color]::LightGreen
        $btnProcedi.Font = New-Object System.Drawing.Font("Segoe UI", 10, [System.Drawing.FontStyle]::Bold)
        $formAnteprima.Controls.Add($btnProcedi)
        
        $btnAnnullaAnt = New-Object System.Windows.Forms.Button
        $btnAnnullaAnt.Text = "ANNULLA"
        $btnAnnullaAnt.Location = New-Object System.Drawing.Point(550, 525)
        $btnAnnullaAnt.Size = New-Object System.Drawing.Size(500, 40)
        $btnAnnullaAnt.BackColor = [System.Drawing.Color]::LightCoral
        $btnAnnullaAnt.Font = New-Object System.Drawing.Font("Segoe UI", 10, [System.Drawing.FontStyle]::Bold)
        $formAnteprima.Controls.Add($btnAnnullaAnt)
        
        $script:procedi = $false
        $btnAnnullaAnt.Add_Click({ $formAnteprima.Close() })
        $btnProcedi.Add_Click({ $script:procedi = $true; $formAnteprima.Close() })
        
        $formAnteprima.ShowDialog() | Out-Null
        $formAnteprima.Dispose()
        
        if (-not $script:procedi) { $txtLog.AppendText("Operazione annullata.`r`n"); return }
        
        $elimina = $chkElimina.Checked
        $fileGestiti = 0; $spazioLiberato = 0
        $cestinoBase = "C:\cerca doppioni\output\cestino\$(Get-Date -Format 'yyyyMMdd_HHmmss')"
        
        foreach ($item in $anteprima) {
            if ($item.Azione -like "ELIMINARE*") {
                $scarto = $item.OggettoOriginale
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
                $txtLog.SelectionStart = $txtLog.Text.Length; $txtLog.ScrollToCaret()
                [System.Windows.Forms.Application]::DoEvents()
            }
        }
        $txtLog.AppendText("`r`nFINITO! File gestiti: $fileGestiti`r`n")
    }
})

$btnAvvia.Add_Click({
    $cartella = $txtPercorso.Text
    if (-not (Test-Path $cartella)) { [System.Windows.Forms.MessageBox]::Show("Cartella non valida!"); return }
    
    $btnAvvia.Enabled = $false; $btnAnnulla.Enabled = $true; $btnSfoglia.Enabled = $false
    $txtLog.Clear(); $SyncHash.Total = 0; $SyncHash.Progress = 0
    $SyncHash.Cancelled = $false; $SyncHash.IsWorking = $true; $SyncHash.Result = $null
    
    $pb.Style = "Marquee"
    $pb.MarqueeAnimationSpeed = 30
    $timer.Start()
    
    $PowerShell = [powershell]::Create()
    $PowerShell.Runspace = [runspacefactory]::CreateRunspace()
    $PowerShell.Runspace.Open()
    $PowerShell.Runspace.SessionStateProxy.SetVariable("SyncHash", $SyncHash)
    $PowerShell.Runspace.SessionStateProxy.SetVariable("Cartella", $cartella)
    
    $PowerShell.AddScript({
        function Log($msg) { $SyncHash.LogQueue.Enqueue($msg) }
        try {
            $cachePath = "C:\cerca doppioni\output\cache_hash.csv"
            $cache = @{}
            
            # Carica la cache se esiste
            if (Test-Path $cachePath) {
                Log "Caricamento cache in memoria..."
                $cachedRows = Import-Csv -LiteralPath $cachePath
                foreach ($row in $cachedRows) { $cache[$row.Path] = $row }
                Log "Cache caricata: $($cache.Count) file memorizzati."
            }
            
            Log "Fase 1: Ricerca file in corso in $Cartella..."
            $files = @()
            $count = 0
            $fileList = Get-ChildItem -LiteralPath $Cartella -Recurse -File -Include *.mp3,*.flac,*.m4a,*.wav,*.jpg,*.png,*.mp4 -ErrorAction SilentlyContinue
            
            foreach ($f in $fileList) {
                if ($SyncHash.Cancelled) { break }
                $files += $f
                $count++
                if ($count % 5000 -eq 0) { Log "Scansione: trovati $count file..." }
            }
            
            if ($SyncHash.Cancelled) { Log "Annullato dall'utente."; return }
            
            Log "Fase 1 completata. Trovati $($files.Count) file."
            Log "Fase 2: Raggruppamento per dimensione..."
            
            $gruppiDimensione = $files | Group-Object Length | Where-Object Count -gt 1
            $totaleDaProcessare = ($gruppiDimensione | Measure-Object -Property Count -Sum).Sum
            
            $SyncHash.Total = $totaleDaProcessare
            Log "Fase 3: Avvio calcolo Hash per $totaleDaProcessare file (SHA-256)..."
            
            $duplicati = @(); $cont = 0
            $fromCache = 0; $calculated = 0
            
            foreach ($g in $gruppiDimensione) {
                if ($SyncHash.Cancelled) { break }
                $hashMap = @{}
                foreach ($f in $g.Group) {
                    if ($SyncHash.Cancelled) { break }
                    $cont++; $SyncHash.Progress = $cont
                    if ($cont % 50 -eq 0) { Log "Hash: elaborati $cont di $totaleDaProcessare..." }
                    
                    $h = $null
                    $dataModifica = $f.LastWriteTime.ToString("yyyyMMddHHmmss")
                    
                    if ($cache.ContainsKey($f.FullName) -and $cache[$f.FullName].Data -eq $dataModifica) {
                        $h = $cache[$f.FullName].Hash
                        $fromCache++
                    } else {
                        $h = (Get-FileHash -LiteralPath $f.FullName -Algorithm SHA256 -ErrorAction SilentlyContinue).Hash
                        if ($h) {
                            $cache[$f.FullName] = [PSCustomObject]@{ Path = $f.FullName; Data = $dataModifica; Hash = $h }
                            $calculated++
                        }
                    }
                    
                    if ($h) {
                        if (-not $hashMap.ContainsKey($h)) { $hashMap[$h] = @() }
                        $hashMap[$h] += $f
                    }
                }
                foreach ($k in $hashMap.Keys) { if ($hashMap[$k].Count -gt 1) { $duplicati += , $hashMap[$k] } }
            }
            
            # Salva la cache aggiornata
            Log "Aggiornamento file di cache..."
            $cache.Values | Export-Csv -Path $cachePath -NoTypeInformation -Encoding UTF8
            
            if ($SyncHash.Cancelled) { Log "Operazione annullata dall'utente." }
            else { 
                Log "Analisi completata!"
                Log "File letti dal disco: $calculated"
                Log "File recuperati dalla cache (istantanei): $fromCache"
                Log "Trovati $($duplicati.Count) gruppi di file identici."
                $SyncHash.Result = $duplicati 
            }
        } catch { Log "ERRORE: $_" } finally { $SyncHash.IsWorking = $false }
    })
    $PowerShell.BeginInvoke() | Out-Null
})

$form.Add_Shown({ $form.Activate(); $timer.Start() })
[void]$form.ShowDialog()
