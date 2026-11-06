<#
.SYNOPSIS
    Interfaccia Grafica per Cerca Doppioni PRO.
.DESCRIPTION
    Modulo che gestisce la UI, le colonne, i colori, le date e la protezione dei clic.
.NOTES
    Autore: Luca Negri
    Versione: 7.7
    Progetto: Cerca Doppioni PRO
#>

Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

function Show-MainWindow {
    param([string]$BaseDir)

    Import-Module "$BaseDir\Modules\Engine.psm1" -Force -DisableNameChecking

    $form = New-Object System.Windows.Forms.Form
    $form.Text = "Cerca Doppioni PRO v7.7 (Originale in cima)"
    $form.Size = New-Object System.Drawing.Size(700, 700)
    $form.StartPosition = "CenterScreen"
    $form.FormBorderStyle = "FixedDialog"
    $form.MaximizeBox = $false

    $lblTitle = New-Object System.Windows.Forms.Label
    $lblTitle.Text = "Cartelle da analizzare:"
    $lblTitle.Location = New-Object System.Drawing.Point(20, 15)
    $lblTitle.Font = New-Object System.Drawing.Font("Segoe UI", 9, [System.Drawing.FontStyle]::Bold)
    $lblTitle.AutoSize = $true
    $form.Controls.Add($lblTitle)

    $listBox = New-Object System.Windows.Forms.ListBox
    $listBox.Location = New-Object System.Drawing.Point(20, 40)
    $listBox.Size = New-Object System.Drawing.Size(530, 90)
    $form.Controls.Add($listBox)

    $btnAggiungi = New-Object System.Windows.Forms.Button
    $btnAggiungi.Text = "+ Aggiungi"; $btnAggiungi.Location = New-Object System.Drawing.Point(560, 40); $btnAggiungi.Size = New-Object System.Drawing.Size(100, 30)
    $form.Controls.Add($btnAggiungi)

    $btnRimuovi = New-Object System.Windows.Forms.Button
    $btnRimuovi.Text = "- Rimuovi"; $btnRimuovi.Location = New-Object System.Drawing.Point(560, 75); $btnRimuovi.Size = New-Object System.Drawing.Size(100, 30)
    $form.Controls.Add($btnRimuovi)

    $chkElimina = New-Object System.Windows.Forms.CheckBox
    $chkElimina.Text = "Elimina definitivamente (altrimenti sposta nel cestino)"
    $chkElimina.Location = New-Object System.Drawing.Point(20, 145)
    $chkElimina.AutoSize = $true
    $form.Controls.Add($chkElimina)

    $btnAvvia = New-Object System.Windows.Forms.Button
    $btnAvvia.Text = "1. ANALIZZA CARTELLE"
    $btnAvvia.Location = New-Object System.Drawing.Point(20, 175)
    $btnAvvia.Size = New-Object System.Drawing.Size(640, 40)
    $btnAvvia.BackColor = [System.Drawing.Color]::LightBlue
    $btnAvvia.Font = New-Object System.Drawing.Font("Segoe UI", 10, [System.Drawing.FontStyle]::Bold)
    $form.Controls.Add($btnAvvia)

    $btnAnnulla = New-Object System.Windows.Forms.Button
    $btnAnnulla.Text = "ANNULLA"; $btnAnnulla.Location = New-Object System.Drawing.Point(20, 225); $btnAnnulla.Size = New-Object System.Drawing.Size(100, 30); $btnAnnulla.Enabled = $false
    $form.Controls.Add($btnAnnulla)

    $lblCounter = New-Object System.Windows.Forms.Label
    $lblCounter.Text = "In attesa..."; $lblCounter.Location = New-Object System.Drawing.Point(130, 233); $lblCounter.Size = New-Object System.Drawing.Size(200, 20)
    $form.Controls.Add($lblCounter)

    $pb = New-Object System.Windows.Forms.ProgressBar
    $pb.Location = New-Object System.Drawing.Point(340, 230); $pb.Size = New-Object System.Drawing.Size(320, 20)
    $form.Controls.Add($pb)

    $txtLog = New-Object System.Windows.Forms.TextBox
    $txtLog.Location = New-Object System.Drawing.Point(20, 270); $txtLog.Size = New-Object System.Drawing.Size(640, 380)
    $txtLog.Multiline = $true; $txtLog.ScrollBars = "Vertical"; $txtLog.ReadOnly = $true
    $txtLog.Font = New-Object System.Drawing.Font("Consolas", 9)
    $form.Controls.Add($txtLog)

    $SyncHash = [hashtable]::Synchronized(@{})
    $SyncHash.LogQueue = [System.Collections.Concurrent.ConcurrentQueue[string]]::new()
    $SyncHash.IsWorking = $false; $SyncHash.Cancelled = $false; $SyncHash.Progress = 0; $SyncHash.Total = 0; $SyncHash.ScannedCount = 0; $SyncHash.Result = $null

    $btnAggiungi.Add_Click({
        $fb = New-Object System.Windows.Forms.FolderBrowserDialog
        if ($fb.ShowDialog() -eq "OK" -and -not $listBox.Items.Contains($fb.SelectedPath)) { $listBox.Items.Add($fb.SelectedPath) | Out-Null }
    })
    $btnRimuovi.Add_Click({ if ($listBox.SelectedIndex -ge 0) { $listBox.Items.RemoveAt($listBox.SelectedIndex) } })
    $btnAnnulla.Add_Click({ $SyncHash.Cancelled = $true; $txtLog.AppendText("`r`nAnnullamento...`r`n") })

    $timer = New-Object System.Windows.Forms.Timer
    $timer.Interval = 200
    $timer.Add_Tick({
        $msg = ""; $hasNewLog = $false
        while ($SyncHash.LogQueue.TryDequeue([ref]$msg)) { $txtLog.AppendText("$msg`r`n"); $hasNewLog = $true }
        if ($hasNewLog) {
            if ($txtLog.Lines.Count -gt 5000) { $txtLog.Text = ($txtLog.Lines | Select-Object -Last 4000) -join "`r`n" }
            $txtLog.SelectionStart = $txtLog.Text.Length; $txtLog.ScrollToCaret()
        }
        
        if ($SyncHash.ScannedCount -gt 0 -and $SyncHash.Total -eq 0) { $lblCounter.Text = "Scansione: $($SyncHash.ScannedCount) file..." }
        if ($SyncHash.Total -gt 0) {
            if ($pb.Style -ne "Blocks") { $pb.Style = "Blocks" }
            $pb.Maximum = $SyncHash.Total; $pb.Value = [math]::Min($SyncHash.Progress, $SyncHash.Total)
            $lblCounter.Text = "Hash: $($SyncHash.Progress) di $($SyncHash.Total)"
        }

        if (-not $SyncHash.IsWorking -and $null -ne $SyncHash.Result) {
            $timer.Stop()
            $btnAvvia.Enabled = $true; $btnAnnulla.Enabled = $false; $btnAggiungi.Enabled = $true; $btnRimuovi.Enabled = $true
            $lblCounter.Text = "Completato!"; $pb.Value = $pb.Maximum
            
            $esatti = $SyncHash.Result.Esatti
            $simili = $SyncHash.Result.Simili
            $SyncHash.Result = $null
            
            if ($esatti.Count -eq 0 -and $simili.Count -eq 0) { [System.Windows.Forms.MessageBox]::Show("Nessun duplicato!"); return }
            
            $anteprimaEsatti = @()
            $anteprimaSimili = @()
            $groupIndex = 1
            
            foreach ($gruppo in $esatti) {
                $daTenere = Get-BestFile -Files $gruppo
                
                foreach ($file in $gruppo) {
                    $isOriginal = ($file.FullName -eq $daTenere.FullName)
                    $dataMod = $file.LastWriteTime.ToString("dd/MM/yy HH:mm")
                    $dataCre = $file.CreationTime.ToString("dd/MM/yy HH:mm")
                    
                    $anteprimaEsatti += [PSCustomObject]@{
                        Gruppo = $groupIndex
                        Azione = if ($isOriginal) { "TENERE (Originale)" } else { "ELIMINARE (Copia)" }
                        Nome = $file.Name; Dimensione = "{0:N2} MB" -f ($file.Length / 1MB)
                        Modifica = if ($isOriginal) { "$dataMod ★" } else { $dataMod }
                        Creazione = if ($isOriginal) { "$dataCre ★" } else { $dataCre }
                        Percorso = $file.FullName; OggettoOriginale = $file
                        Tipo = "Esatto"; IsOriginal = $isOriginal
                    }
                }
                $groupIndex++
            }
            
            foreach ($gruppo in $simili) {
                $bestSimilar = $gruppo | Sort-Object Length -Descending | Select-Object -First 1
                $sizeMax = $bestSimilar.Length
                
                foreach ($file in $gruppo) {
                    $isBest = ($file.FullName -eq $bestSimilar.FullName)
                    $dataMod = $file.LastWriteTime.ToString("dd/MM/yy HH:mm")
                    $dataCre = $file.CreationTime.ToString("dd/MM/yy HH:mm")
                    
                    $diffPerc = 0
                    if (-not $isBest) { $diffPerc = [math]::Round(($file.Length - $sizeMax) / $sizeMax * 100) }
                    
                    $dimensioneStr = "{0:N2} MB" -f ($file.Length / 1MB)
                    if (-not $isBest) { $dimensioneStr += " ($diffPerc%)" }
                    
                    $anteprimaSimili += [PSCustomObject]@{
                        Gruppo = $groupIndex
                        Azione = if ($isBest) { "TENERE (Qualità Maggiore)" } else { "VALUTA (Qualità Minore)" }
                        Nome = $file.Name; Dimensione = $dimensioneStr
                        Modifica = $dataMod
                        Creazione = $dataCre
                        Percorso = $file.FullName; OggettoOriginale = $file
                        Tipo = "Simile"; IsOriginal = $isBest
                    }
                }
                $groupIndex++
            }
            
            $formAnt = New-Object System.Windows.Forms.Form
            $formAnt.Text = "Anteprima: Seleziona cosa vuoi eliminare"
            $formAnt.Size = New-Object System.Drawing.Size(1350, 700)
            $formAnt.StartPosition = "CenterParent"
            
            $lblInfo = New-Object System.Windows.Forms.Label
            $lblInfo.Text = "Doppio clic per APRIRE il file. La spunta si attiva SOLO cliccando sul quadratino a sinistra."
            $lblInfo.Location = New-Object System.Drawing.Point(10, 10); $lblInfo.AutoSize = $true; $lblInfo.ForeColor = [System.Drawing.Color]::Blue
            $formAnt.Controls.Add($lblInfo)

            $btnSelAll = New-Object System.Windows.Forms.Button
            $btnSelAll.Text = "Seleziona Tutti"; $btnSelAll.Location = New-Object System.Drawing.Point(10, 30); $btnSelAll.Size = New-Object System.Drawing.Size(120, 25)
            $formAnt.Controls.Add($btnSelAll)

            $btnDeselAll = New-Object System.Windows.Forms.Button
            $btnDeselAll.Text = "Deseleziona Tutti"; $btnDeselAll.Location = New-Object System.Drawing.Point(140, 30); $btnDeselAll.Size = New-Object System.Drawing.Size(120, 25)
            $formAnt.Controls.Add($btnDeselAll)

            $chkShowSimilar = New-Object System.Windows.Forms.CheckBox
            $chkShowSimilar.Text = "Mostra file simili (stesso nome, dimensioni diverse)"
            $chkShowSimilar.Location = New-Object System.Drawing.Point(280, 32)
            $chkShowSimilar.AutoSize = $true
            $chkShowSimilar.Font = New-Object System.Drawing.Font("Segoe UI", 9, [System.Drawing.FontStyle]::Bold)
            $chkShowSimilar.Checked = $false
            $formAnt.Controls.Add($chkShowSimilar)

            # NUOVA OPZIONE GRASSETTO
            $chkBoldOriginal = New-Object System.Windows.Forms.CheckBox
            $chkBoldOriginal.Text = "Grassetto sugli originali"
            $chkBoldOriginal.Location = New-Object System.Drawing.Point(600, 32)
            $chkBoldOriginal.AutoSize = $true
            $chkBoldOriginal.Checked = $true
            $formAnt.Controls.Add($chkBoldOriginal)

            $lblSummary = New-Object System.Windows.Forms.Label
            $lblSummary.Text = "Calcolo riepilogo..."
            $lblSummary.Location = New-Object System.Drawing.Point(780, 35)
            $lblSummary.Size = New-Object System.Drawing.Size(540, 20)
            $lblSummary.Font = New-Object System.Drawing.Font("Segoe UI", 10, [System.Drawing.FontStyle]::Bold)
            $lblSummary.ForeColor = [System.Drawing.Color]::DarkSlateGray
            $lblSummary.TextAlign = "MiddleRight"
            $formAnt.Controls.Add($lblSummary)

            $listView = New-Object System.Windows.Forms.ListView
            $listView.Location = New-Object System.Drawing.Point(10, 65)
            $listView.Size = New-Object System.Drawing.Size(1310, 500)
            $listView.View = "Details"; $listView.CheckBoxes = $true; $listView.FullRowSelect = $true; $listView.GridLines = $true; $listView.HideSelection = $false
            
            $imgList = New-Object System.Windows.Forms.ImageList
            $imgList.ImageSize = New-Object System.Drawing.Size(24,24)
            $imgList.ColorDepth = [System.Windows.Forms.ColorDepth]::Depth32Bit
            $iconCache = @{}
            
            $listView.SmallImageList = $imgList
            $listView.Columns.Add("Seleziona", 70) | Out-Null 
            $listView.Columns.Add("Gruppo", 60) | Out-Null
            $listView.Columns.Add("Azione", 170) | Out-Null
            $listView.Columns.Add("Nome File", 250) | Out-Null; 
            $listView.Columns.Add("Dimensione", 100) | Out-Null; 
            $listView.Columns.Add("Modifica", 100) | Out-Null
            $listView.Columns.Add("Creazione", 100) | Out-Null
            $listView.Columns.Add("Percorso", 450) | Out-Null
            
            $script:lastClickX = 0
            $script:lastClickY = 0

            $updateSummary = {
                $selezionati = @($listView.Items | Where-Object { $_.Checked })
                $totEsatti = 0; $totSimili = 0; $byteTotali = 0
                foreach ($lv in $selezionati) {
                    if ($lv.Tag.Tipo -eq "Esatto") { $totEsatti++ } else { $totSimili++ }
                    $byteTotali += $lv.Tag.OggettoOriginale.Length
                }
                $mbTotali = [math]::Round($byteTotali / 1MB, 2)
                $gbTotali = [math]::Round($byteTotali / 1GB, 2)
                $testoSpazio = if ($gbTotali -ge 1) { "$gbTotali GB" } else { "$mbTotali MB" }
                $lblSummary.Text = "Selezionati: $($selezionati.Count) file (Esatti: $totEsatti, Simili: $totSimili)  |  Spazio da liberare: $testoSpazio"
            }

            $populateList = {
                $listView.BeginUpdate()
                $listView.Items.Clear()
                
                $itemsToShow = @()
                $itemsToShow += $anteprimaEsatti
                if ($chkShowSimilar.Checked) { $itemsToShow += $anteprimaSimili }

                # ORDINAMENTO: Prima per Gruppo, poi mettiamo l'Originale (True) prima della Copia (False)
                $itemsToShow = $itemsToShow | Sort-Object -Property @{Expression="Gruppo";Descending=$false}, @{Expression="IsOriginal";Descending=$true}

                foreach ($item in $itemsToShow) {
                    $lvItem = New-Object System.Windows.Forms.ListViewItem("")
                    
                    $ext = [System.IO.Path]::GetExtension($item.Percorso).ToLower()
                    if (-not $iconCache.ContainsKey($ext)) {
                        try {
                            $ico = [System.Drawing.Icon]::ExtractAssociatedIcon($item.Percorso)
                            $imgList.Images.Add($ico)
                            $iconCache[$ext] = $imgList.Images.Count - 1
                        } catch { $iconCache[$ext] = -1 }
                    }
                    $lvItem.ImageIndex = $iconCache[$ext]
                    
                    $lvItem.SubItems.Add($item.Gruppo.ToString()) | Out-Null
                    $lvItem.SubItems.Add($item.Azione) | Out-Null
                    $lvItem.SubItems.Add($item.Nome) | Out-Null
                    $lvItem.SubItems.Add($item.Dimensione) | Out-Null
                    $lvItem.SubItems.Add($item.Modifica) | Out-Null
                    $lvItem.SubItems.Add($item.Creazione) | Out-Null
                    $lvItem.SubItems.Add($item.Percorso) | Out-Null
                    
                    # COLORE E GRASSETTO
                    if ($item.IsOriginal) { 
                        $lvItem.ForeColor = [System.Drawing.Color]::Green 
                        if ($chkBoldOriginal.Checked) {
                            $lvItem.Font = New-Object System.Drawing.Font($listView.Font, [System.Drawing.FontStyle]::Bold)
                        }
                    }
                    elseif ($item.Tipo -eq "Simile") { $lvItem.ForeColor = [System.Drawing.Color]::DarkOrange }
                    else { $lvItem.ForeColor = [System.Drawing.Color]::Red }
                    
                    if (-not $item.IsOriginal -and $item.Tipo -eq "Esatto") { $lvItem.Checked = $true }
                    
                    $lvItem.Tag = $item
                    $listView.Items.Add($lvItem) | Out-Null
                }
                $listView.EndUpdate()
                & $updateSummary
            }

            $listView.Add_MouseDown({
                param($sender, $e)
                $script:lastClickX = $e.X
                $script:lastClickY = $e.Y
            })

            $listView.Add_ItemCheck({
                param($sender, $e)
                if ($e.Index -ge 0) {
                    $item = $sender.Items[$e.Index]
                    
                    if ($item.Tag.IsOriginal) { 
                        $e.NewValue = [System.Windows.Forms.CheckState]::Unchecked 
                        return
                    }
                    
                    if ($script:lastClickX -gt 70) {
                        $e.NewValue = $e.CurrentValue 
                        return
                    }
                    
                    $formAnt.BeginInvoke([Action]{ & $updateSummary })
                }
            })
            
            $listView.Add_MouseDoubleClick({
                param($sender, $e)
                $hit = $listView.HitTest($e.X, $e.Y)
                if ($hit.Item) { try { Start-Process $hit.Item.Tag.Percorso } catch { } }
            })

            $contextMenu = New-Object System.Windows.Forms.ContextMenuStrip
            $menuOpenFile = $contextMenu.Items.Add("▶ Apri File")
            $menuOpenFolder = $contextMenu.Items.Add("📁 Apri Cartella")
            $menuCopyPath = $contextMenu.Items.Add("📋 Copia Percorso")
            $listView.ContextMenuStrip = $contextMenu

            $menuOpenFile.Add_Click({ if ($listView.SelectedItems.Count -gt 0) { Start-Process $listView.SelectedItems[0].Tag.Percorso } })
            $menuOpenFolder.Add_Click({ if ($listView.SelectedItems.Count -gt 0) { Start-Process explorer.exe -ArgumentList "/select,`"$($listView.SelectedItems[0].Tag.Percorso)`"" } })
            $menuCopyPath.Add_Click({ if ($listView.SelectedItems.Count -gt 0) { Set-Clipboard -Value $listView.SelectedItems[0].Tag.Percorso } })

            $btnSelAll.Add_Click({ foreach ($lvItem in $listView.Items) { if (-not $lvItem.Tag.IsOriginal) { $lvItem.Checked = $true } }; & $updateSummary })
            $btnDeselAll.Add_Click({ foreach ($lvItem in $listView.Items) { $lvItem.Checked = $false }; & $updateSummary })
            
            # EVENTI PER LE CHECKBOX
            $chkShowSimilar.Add_CheckedChanged({ & $populateList })
            $chkBoldOriginal.Add_CheckedChanged({ & $populateList })

            $formAnt.Controls.Add($listView)
            
            $btnProcedi = New-Object System.Windows.Forms.Button
            $btnProcedi.Text = "PROCEDI CON LE SELEZIONATI"; $btnProcedi.Location = New-Object System.Drawing.Point(10, 575); $btnProcedi.Size = New-Object System.Drawing.Size(500, 40); $btnProcedi.BackColor = [System.Drawing.Color]::LightGreen
            $btnProcedi.Font = New-Object System.Drawing.Font("Segoe UI", 10, [System.Drawing.FontStyle]::Bold)
            $formAnt.Controls.Add($btnProcedi)
            $btnAnnAnt = New-Object System.Windows.Forms.Button
            $btnAnnAnt.Text = "ANNULLA"; $btnAnnAnt.Location = New-Object System.Drawing.Point(550, 575); $btnAnnAnt.Size = New-Object System.Drawing.Size(770, 40); $btnAnnAnt.BackColor = [System.Drawing.Color]::LightCoral
            $formAnt.Controls.Add($btnAnnAnt)
            
            & $populateList

            $script:selezionati = @()
            $btnAnnAnt.Add_Click({ $formAnt.Close() })
            $btnProcedi.Add_Click({
                $script:selezionati = @($listView.Items | Where-Object { $_.Checked } | ForEach-Object { $_.Tag })
                $formAnt.Close()
            })
            
            $formAnt.ShowDialog() | Out-Null
            $formAnt.Dispose()
            
            if ($script:selezionati.Count -gt 0) {
                $res = Invoke-DuplicatiAction -Anteprima $script:selezionati -Elimina $chkElimina.Checked -BaseDir $BaseDir
                foreach ($logLine in $res.Log) { $txtLog.AppendText("$logLine`r`n") }
                $txtLog.AppendText("`r`nFINITO! File gestiti: $($res.Gestiti)`r`n")
                $txtLog.SelectionStart = $txtLog.Text.Length; $txtLog.ScrollToCaret()
            } else {
                $txtLog.AppendText("`r`nNessun file selezionato per la pulizia.`r`n")
            }
        }
    })

    $btnAvvia.Add_Click({
        [string[]]$cartelle = @()
        foreach ($item in $listBox.Items) { if ($item) { $cartelle += $item.ToString() } }
        if ($cartelle.Count -eq 0) { [System.Windows.Forms.MessageBox]::Show("Aggiungi almeno una cartella!"); return }
        
        $btnAvvia.Enabled = $false; $btnAnnulla.Enabled = $true; $btnAggiungi.Enabled = $false; $btnRimuovi.Enabled = $false
        $txtLog.Clear(); $SyncHash.Total = 0; $SyncHash.Progress = 0; $SyncHash.ScannedCount = 0
        $SyncHash.Cancelled = $false; $SyncHash.IsWorking = $true; $SyncHash.Result = $null
        $pb.Style = "Marquee"; $pb.MarqueeAnimationSpeed = 30; $timer.Start()
        
        $PowerShell = [powershell]::Create()
        $PowerShell.Runspace = [runspacefactory]::CreateRunspace(); $PowerShell.Runspace.Open()
        $EnginePath = Join-Path $BaseDir "Modules\Engine.psm1"
        
        $PowerShell.Runspace.SessionStateProxy.SetVariable("SyncHash", $SyncHash)
        $PowerShell.Runspace.SessionStateProxy.SetVariable("Cartelle", $cartelle)
        $PowerShell.Runspace.SessionStateProxy.SetVariable("BaseDir", $BaseDir)
        $PowerShell.Runspace.SessionStateProxy.SetVariable("EnginePath", $EnginePath)
        
        $PowerShell.AddScript({
            Import-Module $EnginePath -Force -DisableNameChecking
            Start-DuplicatiAnalysis -SyncHash $SyncHash -Cartelle $Cartelle -BaseDir $BaseDir
        })
        $PowerShell.BeginInvoke() | Out-Null
    })

    $form.Add_Shown({ $form.Activate(); $timer.Start() })
    [void]$form.ShowDialog()
}
Export-ModuleMember -Function Show-MainWindow
