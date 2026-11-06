Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

function Show-MainWindow {
    param([string]$BaseDir)

    Import-Module "$BaseDir\Modules\Engine.psm1" -Force -DisableNameChecking
    Import-Module "$BaseDir\Modules\GUI_Preview.psm1" -Force -DisableNameChecking
    Import-Module "$BaseDir\Modules\GUI_Utils.psm1" -Force -DisableNameChecking

    $form = New-Object System.Windows.Forms.Form
    $form.Text = "Duplicate Finder PRO v11.0"
    $form.Size = New-Object System.Drawing.Size(700, 820) 
    $form.StartPosition = "CenterScreen"
    $form.FormBorderStyle = "FixedDialog"
    $form.MaximizeBox = $false

    $lblTitle = New-Object System.Windows.Forms.Label
    $lblTitle.Text = "1. Folders to analyze:"; $lblTitle.Location = New-Object System.Drawing.Point(20, 15)
    $lblTitle.Font = New-Object System.Drawing.Font("Segoe UI", 10, [System.Drawing.FontStyle]::Bold); $lblTitle.AutoSize = $true
    $form.Controls.Add($lblTitle)

    $listBox = New-Object System.Windows.Forms.ListBox
    $listBox.Location = New-Object System.Drawing.Point(20, 40); $listBox.Size = New-Object System.Drawing.Size(530, 70)
    $form.Controls.Add($listBox)

    $btnAggiungi = New-Object System.Windows.Forms.Button
    $btnAggiungi.Text = "+ Add"; $btnAggiungi.Location = New-Object System.Drawing.Point(560, 40); $btnAggiungi.Size = New-Object System.Drawing.Size(100, 30); $btnAggiungi.UseVisualStyleBackColor = $true
    $form.Controls.Add($btnAggiungi)

    $btnRimuovi = New-Object System.Windows.Forms.Button
    $btnRimuovi.Text = "- Remove"; $btnRimuovi.Location = New-Object System.Drawing.Point(560, 75); $btnRimuovi.Size = New-Object System.Drawing.Size(100, 30); $btnRimuovi.UseVisualStyleBackColor = $true
    $form.Controls.Add($btnRimuovi)

    $grpFiles = New-Object System.Windows.Forms.GroupBox
    $grpFiles.Text = "2. File types to analyze"; $grpFiles.Location = New-Object System.Drawing.Point(20, 120)
    $grpFiles.Size = New-Object System.Drawing.Size(640, 90); $grpFiles.Font = New-Object System.Drawing.Font("Segoe UI", 9, [System.Drawing.FontStyle]::Bold)
    $form.Controls.Add($grpFiles)

    $chkAudio = New-Object System.Windows.Forms.CheckBox
    $chkAudio.Text = "🎵 Audio (.mp3, .wav, .flac...)"; $chkAudio.Location = New-Object System.Drawing.Point(20, 25); $chkAudio.AutoSize = $true; $chkAudio.Checked = $true; $chkAudio.Font = New-Object System.Drawing.Font("Segoe UI", 9)
    $grpFiles.Controls.Add($chkAudio)

    $chkVideo = New-Object System.Windows.Forms.CheckBox
    $chkVideo.Text = "🎬 Video (.mp4, .mkv, .avi...)"; $chkVideo.Location = New-Object System.Drawing.Point(20, 55); $chkVideo.AutoSize = $true; $chkVideo.Checked = $true; $chkVideo.Font = New-Object System.Drawing.Font("Segoe UI", 9)
    $grpFiles.Controls.Add($chkVideo)

    $chkFoto = New-Object System.Windows.Forms.CheckBox
    $chkFoto.Text = "🖼️ Images (.jpg, .png, .gif...)"; $chkFoto.Location = New-Object System.Drawing.Point(320, 25); $chkFoto.AutoSize = $true; $chkFoto.Checked = $true; $chkFoto.Font = New-Object System.Drawing.Font("Segoe UI", 9)
    $grpFiles.Controls.Add($chkFoto)

    $chkDoc = New-Object System.Windows.Forms.CheckBox
    $chkDoc.Text = "📄 Documents (.pdf, .doc, .txt...)"; $chkDoc.Location = New-Object System.Drawing.Point(320, 55); $chkDoc.AutoSize = $true; $chkDoc.Checked = $false; $chkDoc.Font = New-Object System.Drawing.Font("Segoe UI", 9)
    $grpFiles.Controls.Add($chkDoc)

    $lblAction = New-Object System.Windows.Forms.Label
    $lblAction.Text = "3. Actions"; $lblAction.Location = New-Object System.Drawing.Point(20, 220)
    $lblAction.Font = New-Object System.Drawing.Font("Segoe UI", 10, [System.Drawing.FontStyle]::Bold); $lblAction.AutoSize = $true
    $form.Controls.Add($lblAction)

    $chkElimina = New-Object System.Windows.Forms.CheckBox
    $chkElimina.Text = "Delete permanently (otherwise move to trash)"; $chkElimina.Location = New-Object System.Drawing.Point(20, 245); $chkElimina.AutoSize = $true; $chkElimina.UseVisualStyleBackColor = $true
    $form.Controls.Add($chkElimina)

    $btnAvvia = New-Object System.Windows.Forms.Button
    $btnAvvia.Text = "START ANALYSIS"; $btnAvvia.Location = New-Object System.Drawing.Point(20, 275)
    $btnAvvia.Size = New-Object System.Drawing.Size(640, 45); $btnAvvia.BackColor = [System.Drawing.Color]::LightGreen
    $btnAvvia.Font = New-Object System.Drawing.Font("Segoe UI", 12, [System.Drawing.FontStyle]::Bold); $btnAvvia.UseVisualStyleBackColor = $true
    $form.Controls.Add($btnAvvia)

    $btnAnnulla = New-Object System.Windows.Forms.Button
    $btnAnnulla.Text = "CANCEL"; $btnAnnulla.Location = New-Object System.Drawing.Point(20, 330); $btnAnnulla.Size = New-Object System.Drawing.Size(100, 30); $btnAnnulla.Enabled = $false; $btnAnnulla.UseVisualStyleBackColor = $true
    $form.Controls.Add($btnAnnulla)

    $lblCounter = New-Object System.Windows.Forms.Label
    $lblCounter.Text = "Waiting..."; $lblCounter.Location = New-Object System.Drawing.Point(130, 338); $lblCounter.Size = New-Object System.Drawing.Size(200, 20)
    $form.Controls.Add($lblCounter)

    $pb = New-Object System.Windows.Forms.ProgressBar
    $pb.Location = New-Object System.Drawing.Point(340, 335); $pb.Size = New-Object System.Drawing.Size(320, 20)
    $form.Controls.Add($pb)

    $txtLog = New-Object System.Windows.Forms.TextBox
    $txtLog.Location = New-Object System.Drawing.Point(20, 370); $txtLog.Size = New-Object System.Drawing.Size(640, 310)
    $txtLog.Multiline = $true; $txtLog.ScrollBars = "Vertical"; $txtLog.ReadOnly = $true; $txtLog.Font = New-Object System.Drawing.Font("Consolas", 9)
    $form.Controls.Add($txtLog)

    $lblResultSummary = New-Object System.Windows.Forms.Label
    $lblResultSummary.Text = ""; $lblResultSummary.Location = New-Object System.Drawing.Point(20, 690); $lblResultSummary.Size = New-Object System.Drawing.Size(640, 50)
    $lblResultSummary.Font = New-Object System.Drawing.Font("Segoe UI", 10, [System.Drawing.FontStyle]::Bold); $lblResultSummary.ForeColor = [System.Drawing.Color]::DarkGreen; $lblResultSummary.TextAlign = "MiddleCenter"
    $form.Controls.Add($lblResultSummary)

    $SyncHash = [hashtable]::Synchronized(@{})
    $SyncHash.LogQueue = [System.Collections.Concurrent.ConcurrentQueue[string]]::new()
    $SyncHash.IsWorking = $false; $SyncHash.Cancelled = $false; $SyncHash.Progress = 0; $SyncHash.Total = 0; $SyncHash.ScannedCount = 0; $SyncHash.Result = $null; $SyncHash.HasFinished = $false

    $btnAggiungi.Add_Click({
        $fb = New-Object System.Windows.Forms.FolderBrowserDialog
        if ($fb.ShowDialog() -eq "OK" -and -not $listBox.Items.Contains($fb.SelectedPath)) { $listBox.Items.Add($fb.SelectedPath) | Out-Null }
    })
    $btnRimuovi.Add_Click({ if ($listBox.SelectedIndex -ge 0) { $listBox.Items.RemoveAt($listBox.SelectedIndex) } })
    $btnAnnulla.Add_Click({ $SyncHash.Cancelled = $true; $txtLog.AppendText("`r`nCancelling...`r`n") })

    $timer = New-Object System.Windows.Forms.Timer
    $timer.Interval = 200
    $timer.Add_Tick({
        $msg = ""; $hasNewLog = $false
        while ($SyncHash.LogQueue.TryDequeue([ref]$msg)) { $txtLog.AppendText("$msg`r`n"); $hasNewLog = $true }
        if ($hasNewLog) {
            if ($txtLog.Lines.Count -gt 5000) { $txtLog.Text = ($txtLog.Lines | Select-Object -Last 4000) -join "`r`n" }
            $txtLog.SelectionStart = $txtLog.Text.Length; $txtLog.ScrollToCaret()
        }
        
        if ($SyncHash.ScannedCount -gt 0 -and $SyncHash.Total -eq 0) { $lblCounter.Text = "Scanning: $($SyncHash.ScannedCount) files..." }
        if ($SyncHash.Total -gt 0) {
            if ($pb.Style -ne "Blocks") { $pb.Style = "Blocks" }
            $pb.Maximum = $SyncHash.Total; $pb.Value = [math]::Min($SyncHash.Progress, $SyncHash.Total)
            $lblCounter.Text = "Hash: $($SyncHash.Progress) of $($SyncHash.Total)"
        }

        if ($SyncHash.HasFinished -eq $true) {
            $timer.Stop(); $SyncHash.HasFinished = $false 
            
            $btnAvvia.Enabled = $true; $btnAnnulla.Enabled = $false; $btnAggiungi.Enabled = $true; $btnRimuovi.Enabled = $true
            $chkAudio.Enabled = $true; $chkVideo.Enabled = $true; $chkFoto.Enabled = $true; $chkDoc.Enabled = $true
            $lblCounter.Text = "Completed!"; $pb.Style = "Blocks"; $pb.Value = 0; $lblResultSummary.Text = "" 
            
            if ($SyncHash.Cancelled) { $txtLog.AppendText("`r`nOperation cancelled by user.`r`n"); return }
            if ($null -eq $SyncHash.Result) {
                [System.Windows.Forms.MessageBox]::Show("Analysis interrupted by a critical error.", "Error", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Error)
                return
            }

            $esatti = $SyncHash.Result.Esatti; $simili = $SyncHash.Result.Simili; $SyncHash.Result = $null
            if ($esatti.Count -eq 0 -and $simili.Count -eq 0) { [System.Windows.Forms.MessageBox]::Show("No duplicates found!"); return }
            
            $anteprimaEsatti = @(); $anteprimaSimili = @(); $groupIndex = 1
            
            foreach ($gruppo in $esatti) {
                $daTenere = Get-BestFile -Files $gruppo
                foreach ($file in $gruppo) {
                    $isOriginal = ($file.FullName -eq $daTenere.FullName)
                    $dataMod = $file.LastWriteTime.ToString("MM/dd/yy HH:mm"); $dataCre = $file.CreationTime.ToString("MM/dd/yy HH:mm")
                    $anteprimaEsatti += [PSCustomObject]@{
                        Gruppo = $groupIndex
                        Azione = if ($isOriginal) { "KEEP (Original)" } else { "DELETE (Copy)" }
                        Nome = $file.Name; Dimensione = Format-Size -Bytes $file.Length
                        Modifica = if ($isOriginal) { "$dataMod *" } else { $dataMod }; Creazione = if ($isOriginal) { "$dataCre *" } else { $dataCre }
                        Percorso = $file.FullName; OggettoOriginale = $file; Tipo = "Exact"; IsOriginal = $isOriginal
                    }
                }
                $groupIndex++
            }
            
            foreach ($gruppo in $simili) {
                $bestSimilar = $gruppo | Sort-Object Length -Descending | Select-Object -First 1
                $sizeMax = $bestSimilar.Length
                foreach ($file in $gruppo) {
                    $isBest = ($file.FullName -eq $bestSimilar.FullName)
                    $dataMod = $file.LastWriteTime.ToString("MM/dd/yy HH:mm"); $dataCre = $file.CreationTime.ToString("MM/dd/yy HH:mm")
                    $diffPerc = 0; if (-not $isBest) { $diffPerc = [math]::Round(($file.Length - $sizeMax) / $sizeMax * 100) }
                    $dimensioneStr = Format-Size -Bytes $file.Length; if (-not $isBest) { $dimensioneStr += " ($diffPerc%)" }
                    
                    $anteprimaSimili += [PSCustomObject]@{
                        Gruppo = $groupIndex
                        Azione = if ($isBest) { "KEEP (Higher Quality)" } else { "EVALUATE (Lower Quality)" }
                        Nome = $file.Name; Dimensione = $dimensioneStr; Modifica = $dataMod; Creazione = $dataCre
                        Percorso = $file.FullName; OggettoOriginale = $file; Tipo = "Similar"; IsOriginal = $isBest
                    }
                }
                $groupIndex++
            }
            
            $selezionati = Show-PreviewWindow -AnteprimaEsatti $anteprimaEsatti -AnteprimaSimili $anteprimaSimili
            
            if ($selezionati.Count -gt 0) {
                $procedi = $true
                if ($chkElimina.Checked) {
                    $msg = "You are about to PERMANENTLY DELETE $($selezionati.Count) files.`n`nThis action is IRREVERSIBLE and files will not go to the trash.`n`nAre you sure?"
                    $res = [System.Windows.Forms.MessageBox]::Show($msg, "Confirm Deletion", [System.Windows.Forms.MessageBoxButtons]::YesNo, [System.Windows.Forms.MessageBoxIcon]::Warning)
                    if ($res -ne [System.Windows.Forms.DialogResult]::Yes) { $procedi = $false }
                }
                
                if ($procedi) {
                    $res = Invoke-DuplicatiAction -Anteprima $selezionati -Elimina $chkElimina.Checked -BaseDir $BaseDir
                    foreach ($logLine in $res.Log) { $txtLog.AppendText("$logLine`r`n") }
                    $txtLog.AppendText("`r`nDONE! Files processed: $($res.Gestiti)`r`n")
                    $txtLog.SelectionStart = $txtLog.Text.Length; $txtLog.ScrollToCaret()
                    
                    $spazioStr = Format-Size -Bytes $res.Spazio
                    $azioneStr = if ($chkElimina.Checked) { "permanently deleted" } else { "moved to trash" }
                    $lblResultSummary.Text = "Operation complete!`r`n$($res.Gestiti) files $azioneStr. Space freed: $spazioStr.`r`nPath: $($res.Destinazione)"
                }
            } else {
                $txtLog.AppendText("`r`nNo files selected for cleanup.`r`n")
            }
        }
    })

    $btnAvvia.Add_Click({
        [string[]]$cartelle = @()
        foreach ($item in $listBox.Items) { if ($item -and -not [string]::IsNullOrWhiteSpace($item.ToString())) { $cartelle += $item.ToString() } }
        if ($cartelle.Count -eq 0) { [System.Windows.Forms.MessageBox]::Show("Please add at least one folder!", "Warning", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Warning); return }

        [string[]]$estensioniScelte = @()
        if ($chkAudio.Checked) { $estensioniScelte += ".mp3", ".wav", ".flac", ".m4a", ".ogg", ".aac", ".wma" }
        if ($chkVideo.Checked) { $estensioniScelte += ".mp4", ".mkv", ".avi", ".mov", ".wmv", ".flv", ".webm" }
        if ($chkFoto.Checked)  { $estensioniScelte += ".jpg", ".jpeg", ".png", ".gif", ".bmp", ".tiff", ".heic" }
        if ($chkDoc.Checked)   { $estensioniScelte += ".pdf", ".doc", ".docx", ".txt", ".xls", ".xlsx", ".ppt", ".pptx" }
        if ($estensioniScelte.Count -eq 0) { [System.Windows.Forms.MessageBox]::Show("Select at least one file category!", "Warning", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Warning); return }
        
        $btnAvvia.Enabled = $false; $btnAnnulla.Enabled = $true; $btnAggiungi.Enabled = $false; $btnRimuovi.Enabled = $false
        $chkAudio.Enabled = $false; $chkVideo.Enabled = $false; $chkFoto.Enabled = $false; $chkDoc.Enabled = $false
        
        $txtLog.Clear(); $SyncHash.Total = 0; $SyncHash.Progress = 0; $SyncHash.ScannedCount = 0
        $SyncHash.Cancelled = $false; $SyncHash.IsWorking = $true; $SyncHash.Result = $null; $SyncHash.HasFinished = $false
        $lblResultSummary.Text = "" ; $pb.Style = "Marquee"; $pb.MarqueeAnimationSpeed = 30; $timer.Start()
        
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
