<#
.SYNOPSIS
    Interfaccia Grafica per Cerca Doppioni PRO.
.NOTES
    Versione: 9.4 (Fix doppio clic e larghezza colonne)
#>

Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

function Format-Size {
    param([long]$Bytes)
    if ($Bytes -ge 1GB) { return "{0:N2} GB" -f ($Bytes / 1GB) }
    elseif ($Bytes -ge 1MB) { return "{0:N2} MB" -f ($Bytes / 1MB) }
    else { return "{0:N2} KB" -f ($Bytes / 1KB) }
}

function Show-MainWindow {
    param([string]$BaseDir)

    Import-Module "$BaseDir\Modules\Engine.psm1" -Force -DisableNameChecking

    $form = New-Object System.Windows.Forms.Form
    $form.Text = "Cerca Doppioni PRO v9.4"
    $form.Size = New-Object System.Drawing.Size(700, 820) 
    $form.StartPosition = "CenterScreen"
    $form.FormBorderStyle = "FixedDialog"
    $form.MaximizeBox = $false

    # 1. SEZIONE CARTELLE
    $lblTitle = New-Object System.Windows.Forms.Label
    $lblTitle.Text = "1. Cartelle da analizzare:"
    $lblTitle.Location = New-Object System.Drawing.Point(20, 15)
    $lblTitle.Font = New-Object System.Drawing.Font("Segoe UI", 10, [System.Drawing.FontStyle]::Bold)
    $lblTitle.AutoSize = $true
    $form.Controls.Add($lblTitle)

    $listBox = New-Object System.Windows.Forms.ListBox
    $listBox.Location = New-Object System.Drawing.Point(20, 40)
    $listBox.Size = New-Object System.Drawing.Size(530, 70)
    $form.Controls.Add($listBox)

    $btnAggiungi = New-Object System.Windows.Forms.Button
    $btnAggiungi.Text = "+ Aggiungi"; $btnAggiungi.Location = New-Object System.Drawing.Point(560, 40); $btnAggiungi.Size = New-Object System.Drawing.Size(100, 30)
    $btnAggiungi.UseVisualStyleBackColor = $true
    $form.Controls.Add($btnAggiungi)

    $btnRimuovi = New-Object System.Windows.Forms.Button
    $btnRimuovi.Text = "- Rimuovi"; $btnRimuovi.Location = New-Object System.Drawing.Point(560, 75); $btnRimuovi.Size = New-Object System.Drawing.Size(100, 30)
    $btnRimuovi.UseVisualStyleBackColor = $true
    $form.Controls.Add($btnRimuovi)

    # 2. SEZIONE CATEGORIE (GROUPBOX)
    $grpFiles = New-Object System.Windows.Forms.GroupBox
    $grpFiles.Text = "2. Tipi di file da analizzare"
    $grpFiles.Location = New-Object System.Drawing.Point(20, 120)
    $grpFiles.Size = New-Object System.Drawing.Size(640, 90)
    $grpFiles.Font = New-Object System.Drawing.Font("Segoe UI", 9, [System.Drawing.FontStyle]::Bold)
    $form.Controls.Add($grpFiles)

    $chkAudio = New-Object System.Windows.Forms.CheckBox
    $chkAudio.Text = "🎵 Audio (.mp3, .wav, .flac...)"; $chkAudio.Location = New-Object System.Drawing.Point(20, 25); $chkAudio.AutoSize = $true; $chkAudio.Checked = $true; $chkAudio.Font = New-Object System.Drawing.Font("Segoe UI", 9)
    $grpFiles.Controls.Add($chkAudio)

    $chkVideo = New-Object System.Windows.Forms.CheckBox
    $chkVideo.Text = "🎬 Video (.mp4, .mkv, .avi...)"; $chkVideo.Location = New-Object System.Drawing.Point(20, 55); $chkVideo.AutoSize = $true; $chkVideo.Checked = $true; $chkVideo.Font = New-Object System.Drawing.Font("Segoe UI", 9)
    $grpFiles.Controls.Add($chkVideo)

    $chkFoto = New-Object System.Windows.Forms.CheckBox
    $chkFoto.Text = "🖼️ Immagini (.jpg, .png, .gif...)"; $chkFoto.Location = New-Object System.Drawing.Point(320, 25); $chkFoto.AutoSize = $true; $chkFoto.Checked = $true; $chkFoto.Font = New-Object System.Drawing.Font("Segoe UI", 9)
    $grpFiles.Controls.Add($chkFoto)

    $chkDoc = New-Object System.Windows.Forms.CheckBox
    $chkDoc.Text = "📄 Documenti (.pdf, .doc, .txt...)"; $chkDoc.Location = New-Object System.Drawing.Point(320, 55); $chkDoc.AutoSize = $true; $chkDoc.Checked = $false; $chkDoc.Font = New-Object System.Drawing.Font("Segoe UI", 9)
    $grpFiles.Controls.Add($chkDoc)

    # 3. SEZIONE AZIONE
    $lblAction = New-Object System.Windows.Forms.Label
    $lblAction.Text = "3. Azioni"
    $lblAction.Location = New-Object System.Drawing.Point(20, 220)
    $lblAction.Font = New-Object System.Drawing.Font("Segoe UI", 10, [System.Drawing.FontStyle]::Bold)
    $lblAction.AutoSize = $true
    $form.Controls.Add($lblAction)

    $chkElimina = New-Object System.Windows.Forms.CheckBox
    $chkElimina.Text = "Elimina definitivamente (altrimenti sposta nel cestino)"
    $chkElimina.Location = New-Object System.Drawing.Point(20, 245)
    $chkElimina.AutoSize = $true
    $chkElimina.UseVisualStyleBackColor = $true
    $form.Controls.Add($chkElimina)

    $btnAvvia = New-Object System.Windows.Forms.Button
    $btnAvvia.Text = "AVVIA ANALISI"
    $btnAvvia.Location = New-Object System.Drawing.Point(20, 275)
    $btnAvvia.Size = New-Object System.Drawing.Size(640, 45)
    $btnAvvia.BackColor = [System.Drawing.Color]::LightGreen
    $btnAvvia.Font = New-Object System.Drawing.Font("Segoe UI", 12, [System.Drawing.FontStyle]::Bold)
    $btnAvvia.UseVisualStyleBackColor = $true
    $form.Controls.Add($btnAvvia)

    $btnAnnulla = New-Object System.Windows.Forms.Button
    $btnAnnulla.Text = "ANNULLA"; $btnAnnulla.Location = New-Object System.Drawing.Point(20, 330); $btnAnnulla.Size = New-Object System.Drawing.Size(100, 30); $btnAnnulla.Enabled = $false
    $btnAnnulla.UseVisualStyleBackColor = $true
    $form.Controls.Add($btnAnnulla)

    $lblCounter = New-Object System.Windows.Forms.Label
    $lblCounter.Text = "In attesa..."; $lblCounter.Location = New-Object System.Drawing.Point(130, 338); $lblCounter.Size = New-Object System.Drawing.Size(200, 20)
    $form.Controls.Add($lblCounter)

    $pb = New-Object System.Windows.Forms.ProgressBar
    $pb.Location = New-Object System.Drawing.Point(340, 335); $pb.Size = New-Object System.Drawing.Size(320, 20)
    $form.Controls.Add($pb)

    $txtLog = New-Object System.Windows.Forms.TextBox
    $txtLog.Location = New-Object System.Drawing.Point(20, 370); $txtLog.Size = New-Object System.Drawing.Size(640, 310)
    $txtLog.Multiline = $true; $txtLog.ScrollBars = "Vertical"; $txtLog.ReadOnly = $true
    $txtLog.Font = New-Object System.Drawing.Font("Consolas", 9)
    $form.Controls.Add($txtLog)

    $lblResultSummary = New-Object System.Windows.Forms.Label
    $lblResultSummary.Text = ""
    $lblResultSummary.Location = New-Object System.Drawing.Point(20, 690); $lblResultSummary.Size = New-Object System.Drawing.Size(640, 50)
    $lblResultSummary.Font = New-Object System.Drawing.Font("Segoe UI", 10, [System.Drawing.FontStyle]::Bold)
    $lblResultSummary.ForeColor = [System.Drawing.Color]::DarkGreen
    $lblResultSummary.TextAlign = "MiddleCenter"
    $form.Controls.Add($lblResultSummary)

    $SyncHash = [hashtable]::Synchronized(@{})
    $SyncHash.LogQueue = [System.Collections.Concurrent.ConcurrentQueue[string]]::new()
    $SyncHash.IsWorking = $false; $SyncHash.Cancelled = $false; $SyncHash.Progress = 0; $SyncHash.Total = 0; $SyncHash.ScannedCount = 0; $SyncHash.Result = $null; $SyncHash.HasFinished = $false

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

        if ($SyncHash.HasFinished -eq $true) {
            $timer.Stop()
            $SyncHash.HasFinished = $false 
            
            $btnAvvia.Enabled = $true; $btnAnnulla.Enabled = $false; $btnAggiungi.Enabled = $true; $btnRimuovi.Enabled = $true
            $chkAudio.Enabled = $true; $chkVideo.Enabled = $true; $chkFoto.Enabled = $true; $chkDoc.Enabled = $true
            $lblCounter.Text = "Completato!"; $pb.Style = "Blocks"; $pb.Value = 0
            $lblResultSummary.Text = "" 
            
            if ($SyncHash.Cancelled) { $txtLog.AppendText("`r`nOperazione annullata dall'utente.`r`n"); return }
            if ($null -eq $SyncHash.Result) {
                [System.Windows.Forms.MessageBox]::Show("L'analisi è stata interrotta da un errore critico.", "Errore", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Error)
                return
            }

            $esatti = $SyncHash.Result.Esatti
            $simili = $SyncHash.Result.Simili
            $SyncHash.Result = $null
            
            if ($esatti.Count -eq 0 -and $simili.Count -eq 0) { [System.Windows.Forms.MessageBox]::Show("Nessun duplicato trovato!"); return }
            
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
                        Nome = $file.Name; Dimensione = Format-Size -Bytes $file.Length
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
                    $dimensioneStr = Format-Size -Bytes $file.Length
                    if (-not $isBest) { $dimensioneStr += " ($diffPerc%)" }
                    $anteprimaSimili += [PSCustomObject]@{
                        Gruppo = $groupIndex
                        Azione = if ($isBest) { "TENERE (Qualità Maggiore)" } else { "VALUTA (Qualità Minore)" }
                        Nome = $file.Name; Dimensione = $dimensioneStr
                        Modifica = $dataMod; Creazione = $dataCre
                        Percorso = $file.FullName; OggettoOriginale = $file
                        Tipo = "Simile"; IsOriginal = $isBest
                    }
                }
                $groupIndex++
            }
            
            $formAnt = New-Object System.Windows.Forms.Form
            $formAnt.Text = "Anteprima: Seleziona cosa vuoi eliminare"
            $formAnt.Size = New-Object System.Drawing.Size(1350, 750) 
            $formAnt.StartPosition = "CenterParent"
            
            $lblInfo = New-Object System.Windows.Forms.Label
            $lblInfo.Text = "Doppio clic su '▶ Apri' per aprire il file. Doppio clic sul 'Percorso' per aprire la cartella."
            $lblInfo.Location = New-Object System.Drawing.Point(10, 10); $lblInfo.AutoSize = $true; $lblInfo.ForeColor = [System.Drawing.Color]::Blue
            $formAnt.Controls.Add($lblInfo)

            $btnSelAll = New-Object System.Windows.Forms.Button
            $btnSelAll.Text = "Seleziona Tutti"; $btnSelAll.Location = New-Object System.Drawing.Point(10, 30); $btnSelAll.Size = New-Object System.Drawing.Size(120, 30)
            $btnSelAll.UseVisualStyleBackColor = $true
            $formAnt.Controls.Add($btnSelAll)

            $btnDeselAll = New-Object System.Windows.Forms.Button
            $btnDeselAll.Text = "Deseleziona Tutti"; $btnDeselAll.Location = New-Object System.Drawing.Point(140, 30); $btnDeselAll.Size = New-Object System.Drawing.Size(120, 30)
            $btnDeselAll.UseVisualStyleBackColor = $true
            $formAnt.Controls.Add($btnDeselAll)

            $chkShowSimilar = New-Object System.Windows.Forms.CheckBox
            $chkShowSimilar.Text = "Mostra file simili (stesso nome, dimensioni diverse)"
            $chkShowSimilar.Location = New-Object System.Drawing.Point(280, 35)
            $chkShowSimilar.Size = New-Object System.Drawing.Size(350, 20)
            $chkShowSimilar.Font = New-Object System.Drawing.Font("Segoe UI", 9, [System.Drawing.FontStyle]::Bold)
            $chkShowSimilar.Checked = $false
            $chkShowSimilar.UseVisualStyleBackColor = $true
            $formAnt.Controls.Add($chkShowSimilar)

            $chkBoldOriginal = New-Object System.Windows.Forms.CheckBox
            $chkBoldOriginal.Text = "Grassetto sugli originali"
            $chkBoldOriginal.Location = New-Object System.Drawing.Point(650, 35)
            $chkBoldOriginal.Size = New-Object System.Drawing.Size(200, 20)
            $chkBoldOriginal.Checked = $true
            $chkBoldOriginal.UseVisualStyleBackColor = $true
            $formAnt.Controls.Add($chkBoldOriginal)

            $lblSummary = New-Object System.Windows.Forms.Label
            $lblSummary.Text = "Calcolo riepilogo..."
            $lblSummary.Location = New-Object System.Drawing.Point(860, 35)
            $lblSummary.Size = New-Object System.Drawing.Size(460, 20)
            $lblSummary.Font = New-Object System.Drawing.Font("Segoe UI", 10, [System.Drawing.FontStyle]::Bold)
            $lblSummary.ForeColor = [System.Drawing.Color]::DarkSlateGray
            $lblSummary.TextAlign = "MiddleRight"
            $formAnt.Controls.Add($lblSummary)

            $lblSearch = New-Object System.Windows.Forms.Label
            $lblSearch.Text = "Cerca per nome:"
            $lblSearch.Location = New-Object System.Drawing.Point(10, 70); $lblSearch.AutoSize = $true
            $formAnt.Controls.Add($lblSearch)

            $txtSearch = New-Object System.Windows.Forms.TextBox
            $txtSearch.Location = New-Object System.Drawing.Point(110, 68)
            $txtSearch.Size = New-Object System.Drawing.Size(250, 20)
            $formAnt.Controls.Add($txtSearch)

            $chkShowSimilar.BringToFront()
            $chkBoldOriginal.BringToFront()
            $lblSummary.BringToFront()

            $listView = New-Object System.Windows.Forms.ListView
            $listView.Location = New-Object System.Drawing.Point(10, 100)
            $listView.Size = New-Object System.Drawing.Size(1310, 470)
            $listView.View = "Details"; $listView.CheckBoxes = $true; $listView.FullRowSelect = $true; $listView.GridLines = $true; $listView.HideSelection = $false
            
            $imgList = New-Object System.Windows.Forms.ImageList
            $imgList.ImageSize = New-Object System.Drawing.Size(24,24)
            $imgList.ColorDepth = [System.Windows.Forms.ColorDepth]::Depth32Bit
            $iconCache = @{}
            
            $listView.SmallImageList = $imgList
            $listView.Columns.Add("Seleziona", 70) | Out-Null 
            $listView.Columns.Add("Gruppo", 60) | Out-Null
            $listView.Columns.Add("Azione", 170) | Out-Null
            $listView.Columns.Add("Azioni", 80) | Out-Null 
            $listView.Columns.Add("Nome File", 320) | Out-Null
            $listView.Columns.Add("Dimensione", 100) | Out-Null; 
            $listView.Columns.Add("Modifica", 100) | Out-Null
            $listView.Columns.Add("Creazione", 100) | Out-Null
            $listView.Columns.Add("Percorso", 400) | Out-Null
            
            $script:lastClickX = 0
            $script:lastClickY = 0
            $script:searchText = ""

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

                if ($script:searchText -ne "") {
                    $itemsToShow = $itemsToShow | Where-Object { $_.Nome -like "*$($script:searchText)*" -or $_.Percorso -like "*$($script:searchText)*" }
                }

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
                    $lvItem.SubItems.Add("▶ Apri") | Out-Null 
                    $lvItem.SubItems.Add($item.Nome) | Out-Null
                    $lvItem.SubItems.Add($item.Dimensione) | Out-Null
                    $lvItem.SubItems.Add($item.Modifica) | Out-Null
                    $lvItem.SubItems.Add($item.Creazione) | Out-Null
                    $lvItem.SubItems.Add($item.Percorso) | Out-Null
                    
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

            $listView.Add_MouseDoubleClick({
                param($sender, $e)
                $hit = $listView.HitTest($e.X, $e.Y)
                if ($hit.Item -and $hit.SubItem) {
                    $colIndex = $hit.Item.SubItems.IndexOf($hit.SubItem)
                    $filePath = $hit.Item.Tag.Percorso

                    if ($colIndex -eq 3) {
                        try { Start-Process $filePath } catch { }
                    } elseif ($colIndex -eq 8) {
                        Start-Process explorer.exe -ArgumentList "/select,`"$filePath`""
                    }
                }
            })

            $listView.Add_ItemCheck({
                param($sender, $e)
                if ($e.Index -ge 0) {
                    $item = $sender.Items[$e.Index]
                    if ($item.Tag.IsOriginal) { $e.NewValue = [System.Windows.Forms.CheckState]::Unchecked; return }
                    if ($script:lastClickX -gt 70) { $e.NewValue = $e.CurrentValue; return }
                    $formAnt.BeginInvoke([Action]{ & $updateSummary })
                }
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
            $chkShowSimilar.Add_CheckedChanged({ & $populateList })
            $chkBoldOriginal.Add_CheckedChanged({ & $populateList })
            
            $txtSearch.Add_TextChanged({
                $script:searchText = $txtSearch.Text
                & $populateList
            })

            $formAnt.Controls.Add($listView)
            
            $btnProcedi = New-Object System.Windows.Forms.Button
            $btnProcedi.Text = "PROCEDI CON LE SELEZIONATI"; $btnProcedi.Location = New-Object System.Drawing.Point(10, 580); $btnProcedi.Size = New-Object System.Drawing.Size(500, 40); $btnProcedi.BackColor = [System.Drawing.Color]::LightGreen
            $btnProcedi.Font = New-Object System.Drawing.Font("Segoe UI", 10, [System.Drawing.FontStyle]::Bold)
            $btnProcedi.UseVisualStyleBackColor = $true
            $formAnt.Controls.Add($btnProcedi)
            
            $btnAnnAnt = New-Object System.Windows.Forms.Button
            $btnAnnAnt.Text = "ANNULLA"; $btnAnnAnt.Location = New-Object System.Drawing.Point(550, 580); $btnAnnAnt.Size = New-Object System.Drawing.Size(770, 40); $btnAnnAnt.BackColor = [System.Drawing.Color]::LightCoral
            $btnAnnAnt.UseVisualStyleBackColor = $true
            $formAnt.Controls.Add($btnAnnAnt)
            
            & $populateList

            $script:selezionati = @()
            $btnAnnAnt.Add_Click({ $formAnt.Close() })
            
            $btnProcedi.Add_Click({
                $script:selezionati = @($listView.Items | Where-Object { $_.Checked } | ForEach-Object { $_.Tag })
                
                if ($chkElimina.Checked -and $script:selezionati.Count -gt 0) {
                    $msg = "Stai per ELIMINARE DEFINITIVAMENTE $($script:selezionati.Count) file.`n`nQuesta azione è IRREVERSIBILE e i file non finiranno nel cestino.`n`nSei sicuro di voler procedere?"
                    $res = [System.Windows.Forms.MessageBox]::Show($msg, "Conferma Eliminazione", [System.Windows.Forms.MessageBoxButtons]::YesNo, [System.Windows.Forms.MessageBoxIcon]::Warning)
                    if ($res -ne [System.Windows.Forms.DialogResult]::Yes) { return }
                }
                
                $formAnt.Close()
            })
            
            $formAnt.ShowDialog() | Out-Null
            $formAnt.Dispose()
            
            if ($script:selezionati.Count -gt 0) {
                $res = Invoke-DuplicatiAction -Anteprima $script:selezionati -Elimina $chkElimina.Checked -BaseDir $BaseDir
                foreach ($logLine in $res.Log) { $txtLog.AppendText("$logLine`r`n") }
                $txtLog.AppendText("`r`nFINITO! File gestiti: $($res.Gestiti)`r`n")
                $txtLog.SelectionStart = $txtLog.Text.Length; $txtLog.ScrollToCaret()
                
                $spazioStr = Format-Size -Bytes $res.Spazio
                $azioneStr = if ($chkElimina.Checked) { "eliminati definitivamente" } else { "spostati nel cestino" }
                
                $lblResultSummary.Text = "Operazione completata!`r`n$($res.Gestiti) file $azioneStr. Spazio recuperato: $spazioStr.`r`nPercorso: $($res.Destinazione)"
            } else {
                $txtLog.AppendText("`r`nNessun file selezionato per la pulizia.`r`n")
            }
        }
    })

    $btnAvvia.Add_Click({
        [string[]]$cartelle = @()
        foreach ($item in $listBox.Items) { 
            if ($item -and -not [string]::IsNullOrWhiteSpace($item.ToString())) { 
                $cartelle += $item.ToString() 
            } 
        }
        
        if ($cartelle.Count -eq 0) { 
            [System.Windows.Forms.MessageBox]::Show("Per favore, aggiungi almeno una cartella prima di analizzare!", "Attenzione", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Warning)
            return 
        }

        [string[]]$estensioniScelte = @()
        if ($chkAudio.Checked) { $estensioniScelte += ".mp3", ".wav", ".flac", ".m4a", ".ogg", ".aac", ".wma" }
        if ($chkVideo.Checked) { $estensioniScelte += ".mp4", ".mkv", ".avi", ".mov", ".wmv", ".flv", ".webm" }
        if ($chkFoto.Checked)  { $estensioniScelte += ".jpg", ".jpeg", ".png", ".gif", ".bmp", ".tiff", ".heic" }
        if ($chkDoc.Checked)   { $estensioniScelte += ".pdf", ".doc", ".docx", ".txt", ".xls", ".xlsx", ".ppt", ".pptx" }
        
        if ($estensioniScelte.Count -eq 0) {
            [System.Windows.Forms.MessageBox]::Show("Seleziona almeno una categoria di file!", "Attenzione", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Warning)
            return
        }
        
        $btnAvvia.Enabled = $false; $btnAnnulla.Enabled = $true; $btnAggiungi.Enabled = $false; $btnRimuovi.Enabled = $false
        $chkAudio.Enabled = $false; $chkVideo.Enabled = $false; $chkFoto.Enabled = $false; $chkDoc.Enabled = $false
        
        $txtLog.Clear(); $SyncHash.Total = 0; $SyncHash.Progress = 0; $SyncHash.ScannedCount = 0
        $SyncHash.Cancelled = $false; $SyncHash.IsWorking = $true; $SyncHash.Result = $null; $SyncHash.HasFinished = $false
        $lblResultSummary.Text = "" 
        $pb.Style = "Marquee"; $pb.MarqueeAnimationSpeed = 30; $timer.Start()
        
        $PowerShell = [powershell]::Create()
        $PowerShell.Runspace = [runspacefactory]::CreateRunspace(); $PowerShell.Runspace.Open()
        $EnginePath = Join-Path $BaseDir "Modules\Engine.psm1"
        
        $PowerShell.Runspace.SessionStateProxy.SetVariable("SyncHash", $SyncHash)
        $PowerShell.Runspace.SessionStateProxy.SetVariable("Cartelle", $cartelle)
        $PowerShell.Runspace.SessionStateProxy.SetVariable("BaseDir", $BaseDir)
        $PowerShell.Runspace.SessionStateProxy.SetVariable("EnginePath", $EnginePath)
        $PowerShell.Runspace.SessionStateProxy.SetVariable("EstensioniSelezionate", $estensioniScelte)
        
        $PowerShell.AddScript({
            Import-Module $EnginePath -Force -DisableNameChecking
            Start-DuplicatiAnalysis -SyncHash $SyncHash -Cartelle $Cartelle -BaseDir $BaseDir -EstensioniSelezionate $EstensioniSelezionate
        })
        $PowerShell.BeginInvoke() | Out-Null
    })

    $form.Add_Shown({ $form.Activate(); $timer.Start() })
    [void]$form.ShowDialog()
}
Export-ModuleMember -Function Show-MainWindow
