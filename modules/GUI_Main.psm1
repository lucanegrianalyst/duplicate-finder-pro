Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

function Show-MainWindow {
    param([string]$BaseDir)

    Import-Module "$BaseDir\Modules\Engine.psm1" -Force -DisableNameChecking
    Import-Module "$BaseDir\Modules\GUI_Preview.psm1" -Force -DisableNameChecking
    Import-Module "$BaseDir\Modules\GUI_Utils.psm1" -Force -DisableNameChecking

    $form = New-Object System.Windows.Forms.Form
    $form.Text = "Duplicate Finder PRO v11.22"
    $form.Size = New-Object System.Drawing.Size(700, 820) 
    $form.StartPosition = "CenterScreen"
    $form.FormBorderStyle = "FixedDialog"
    $form.MaximizeBox = $false

    $lblTitle = New-Object System.Windows.Forms.Label
    $lblTitle.Text = "1. Folders to analyze:"; $lblTitle.Location = New-Object System.Drawing.Point(20, 15)
    $lblTitle.Font = New-Object System.Drawing.Font("Segoe UI", 10, [System.Drawing.FontStyle]::Bold); $lblTitle.AutoSize = $true
    $form.Controls.Add($lblTitle)

    $dgvFolders = New-Object System.Windows.Forms.DataGridView
    $dgvFolders.Location = New-Object System.Drawing.Point(20, 40); $dgvFolders.Size = New-Object System.Drawing.Size(530, 90)
    $dgvFolders.AllowUserToAddRows = $false; $dgvFolders.AllowUserToDeleteRows = $false
    $dgvFolders.ReadOnly = $true; $dgvFolders.SelectionMode = "FullRowSelect"
    $dgvFolders.RowHeadersVisible = $false; $dgvFolders.BackgroundColor = [System.Drawing.Color]::White
    $dgvFolders.AllowUserToResizeRows = $false; $dgvFolders.ColumnHeadersVisible = $true

    $colPath = New-Object System.Windows.Forms.DataGridViewTextBoxColumn
    $colPath.Name = "Path"; $colPath.HeaderText = "Folder Path"; $colPath.AutoSizeMode = "Fill"
    $dgvFolders.Columns.Add($colPath) | Out-Null

    $colRemove = New-Object System.Windows.Forms.DataGridViewButtonColumn
    $colRemove.Name = "Remove"; $colRemove.HeaderText = "Action"; $colRemove.Text = "❌ Remove"
    $colRemove.UseColumnTextForButtonValue = $true; $colRemove.Width = 100; $colRemove.FlatStyle = "Flat"
    $colRemove.DefaultCellStyle.ForeColor = [System.Drawing.Color]::DarkRed
    $colRemove.DefaultCellStyle.Font = New-Object System.Drawing.Font("Segoe UI", 9, [System.Drawing.FontStyle]::Bold)
    $dgvFolders.Columns.Add($colRemove) | Out-Null

    $dgvFolders.Add_CellContentClick({
        param($sender, $e)
        if ($e.RowIndex -ge 0 -and $e.ColumnIndex -eq 1) { $sender.Rows.RemoveAt($e.RowIndex) }
    })
    $form.Controls.Add($dgvFolders)

    $btnAggiungi = New-Object System.Windows.Forms.Button
    $btnAggiungi.Text = "+ Add"; $btnAggiungi.Location = New-Object System.Drawing.Point(560, 40); $btnAggiungi.Size = New-Object System.Drawing.Size(100, 90); $btnAggiungi.UseVisualStyleBackColor = $true
    $form.Controls.Add($btnAggiungi)

    $grpFiles = New-Object System.Windows.Forms.GroupBox
    $grpFiles.Text = "2. File types to analyze"; $grpFiles.Location = New-Object System.Drawing.Point(20, 140)
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
    $lblAction.Text = "3. Actions"; $lblAction.Location = New-Object System.Drawing.Point(20, 240)
    $lblAction.Font = New-Object System.Drawing.Font("Segoe UI", 10, [System.Drawing.FontStyle]::Bold); $lblAction.AutoSize = $true
    $form.Controls.Add($lblAction)

    $chkElimina = New-Object System.Windows.Forms.CheckBox
    $chkElimina.Text = "Delete permanently (otherwise move to trash)"; $chkElimina.Location = New-Object System.Drawing.Point(20, 265); $chkElimina.AutoSize = $true; $chkElimina.UseVisualStyleBackColor = $true
    $form.Controls.Add($chkElimina)

    $btnAvvia = New-Object System.Windows.Forms.Button
    $btnAvvia.Text = "START ANALYSIS"; $btnAvvia.Location = New-Object System.Drawing.Point(20, 295)
    $btnAvvia.Size = New-Object System.Drawing.Size(640, 45); $btnAvvia.BackColor = [System.Drawing.Color]::LightGreen
    $btnAvvia.Font = New-Object System.Drawing.Font("Segoe UI", 12, [System.Drawing.FontStyle]::Bold); $btnAvvia.UseVisualStyleBackColor = $true
    $form.Controls.Add($btnAvvia)

    $btnAnnulla = New-Object System.Windows.Forms.Button
    $btnAnnulla.Text = "ABORT"; $btnAnnulla.Location = New-Object System.Drawing.Point(20, 350); $btnAnnulla.Size = New-Object System.Drawing.Size(100, 30)
    $btnAnnulla.Enabled = $false; $btnAnnulla.BackColor = [System.Drawing.Color]::LightCoral
    $btnAnnulla.Font = New-Object System.Drawing.Font("Segoe UI", 9, [System.Drawing.FontStyle]::Bold)
    $form.Controls.Add($btnAnnulla)

    $btnReopenPreview = New-Object System.Windows.Forms.Button
    $btnReopenPreview.Text = "SHOW LAST RESULTS"; $btnReopenPreview.Location = New-Object System.Drawing.Point(130, 350); $btnReopenPreview.Size = New-Object System.Drawing.Size(150, 30); $btnReopenPreview.Enabled = $false; $btnReopenPreview.UseVisualStyleBackColor = $true
    $form.Controls.Add($btnReopenPreview)

    $lblCounter = New-Object System.Windows.Forms.Label
    $lblCounter.Text = "Waiting..."; $lblCounter.Location = New-Object System.Drawing.Point(290, 358); $lblCounter.Size = New-Object System.Drawing.Size(370, 20)
    $lblCounter.Font = New-Object System.Drawing.Font("Segoe UI", 9, [System.Drawing.FontStyle]::Regular)
    $form.Controls.Add($lblCounter)

    $pb = New-Object System.Windows.Forms.ProgressBar
    $pb.Location = New-Object System.Drawing.Point(450, 355); $pb.Size = New-Object System.Drawing.Size(210, 20)
    $form.Controls.Add($pb)

    $txtLog = New-Object System.Windows.Forms.TextBox
    $txtLog.Location = New-Object System.Drawing.Point(20, 390); $txtLog.Size = New-Object System.Drawing.Size(640, 290)
    $txtLog.Multiline = $true; $txtLog.ScrollBars = "Vertical"; $txtLog.ReadOnly = $true; $txtLog.Font = New-Object System.Drawing.Font("Consolas", 9)
    $form.Controls.Add($txtLog)

    $lblResultSummary = New-Object System.Windows.Forms.Label
    $lblResultSummary.Text = ""; $lblResultSummary.Location = New-Object System.Drawing.Point(20, 690); $lblResultSummary.Size = New-Object System.Drawing.Size(640, 50)
    $lblResultSummary.Font = New-Object System.Drawing.Font("Segoe UI", 10, [System.Drawing.FontStyle]::Bold); $lblResultSummary.ForeColor = [System.Drawing.Color]::DarkGreen; $lblResultSummary.TextAlign = "MiddleCenter"
    $form.Controls.Add($lblResultSummary)

    $form.Add_FormClosing({
        param($sender, $e)
        $res = [System.Windows.Forms.MessageBox]::Show("Are you sure you want to exit?", "Confirm Exit", [System.Windows.Forms.MessageBoxButtons]::YesNo, [System.Windows.Forms.MessageBoxIcon]::Question)
        if ($res -ne [System.Windows.Forms.DialogResult]::Yes) { $e.Cancel = $true }
    })

    $script:lastAnteprimaEsatti = $null
    $script:lastAnteprimaSimili = $null
    $script:startTime = $null
    $script:hashStartTime = $null
    $script:estimatedTotalSeconds = $null

    function Show-PreviewAndProcess {
        param($AnteprimaEsatti, $AnteprimaSimili)
        $risultatoGrezzo = Show-PreviewWindow -AnteprimaEsatti $AnteprimaEsatti -AnteprimaSimili $AnteprimaSimili
        $selezionati = @($risultatoGrezzo | Where-Object { $null -ne $_ -and $_.PSObject.Properties.Name -contains 'Percorso' })

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

    $btnReopenPreview.Add_Click({
        if ($null -ne $script:lastAnteprimaEsatti -or $null -ne $script:lastAnteprimaSimili) {
            Show-PreviewAndProcess -AnteprimaEsatti $script:lastAnteprimaEsatti -AnteprimaSimili $script:lastAnteprimaSimili
        }
    })

    $SyncHash = [hashtable]::Synchronized(@{})
    $SyncHash.LogQueue = [System.Collections.Concurrent.ConcurrentQueue[string]]::new()
    $SyncHash.IsWorking = $false; $SyncHash.Cancelled = $false; $SyncHash.Progress = 0; $SyncHash.Total = 0; $SyncHash.ScannedCount = 0; $SyncHash.Result = $null; $SyncHash.HasFinished = $false

    $btnAggiungi.Add_Click({
        $fb = New-Object System.Windows.Forms.FolderBrowserDialog
        if ($fb.ShowDialog() -eq "OK") {
            $exists = $false
            foreach ($row in $dgvFolders.Rows) { if ($row.Cells[0].Value -eq $fb.SelectedPath) { $exists = $true; break } }
            if (-not $exists) { $dgvFolders.Rows.Add($fb.SelectedPath, "❌ Remove") }
        }
    })

    $btnAnnulla.Add_Click({ 
        $SyncHash.Cancelled = $true
        $txtLog.AppendText("`r`nAbort requested. Waiting for current file to finish...`r`n")
        $btnAnnulla.Enabled = $false
    })

    $timer = New-Object System.Windows.Forms.Timer
    $timer.Interval = 200
    $timer.Add_Tick({
        $msg = ""; $hasNewLog = $false
        while ($SyncHash.LogQueue.TryDequeue([ref]$msg)) { $txtLog.AppendText("$msg`r`n"); $hasNewLog = $true }
        if ($hasNewLog) {
            if ($txtLog.Lines.Count -gt 5000) { $txtLog.Text = ($txtLog.Lines | Select-Object -Last 4000) -join "`r`n" }
            $txtLog.SelectionStart = $txtLog.Text.Length; $txtLog.ScrollToCaret()
        }
        
        # LOGICA DEL COUNTDOWN
        if ($script:startTime -ne $null -and $SyncHash.IsWorking) {
            $elapsed = (Get-Date) - $script:startTime
            $elapsedStr = "{0:mm\:ss}" -f $elapsed

            if ($SyncHash.ScannedCount -gt 0 -and $SyncHash.Total -eq 0) {
                $lblCounter.Text = "Scanning files... (Elapsed: $elapsedStr)"
            }
            
            if ($SyncHash.Total -gt 0) {
                if ($pb.Style -ne "Blocks") { $pb.Style = "Blocks" }
                $pb.Maximum = $SyncHash.Total; $pb.Value = [math]::Min($SyncHash.Progress, $SyncHash.Total)
                
                if ($null -eq $script:hashStartTime) { $script:hashStartTime = Get-Date }
                $hashElapsed = (Get-Date) - $script:hashStartTime
                
                if ($SyncHash.Progress -gt 50) {
                    # Calcoliamo la stima TOTALE una sola volta dopo i primi 50 file
                    if ($null -eq $script:estimatedTotalSeconds -and $hashElapsed.TotalSeconds -gt 0) {
                        $speed = $SyncHash.Progress / $hashElapsed.TotalSeconds
                        $remainingFiles = $SyncHash.Total - $SyncHash.Progress
                        $script:estimatedTotalSeconds = $hashElapsed.TotalSeconds + ($remainingFiles / $speed)
                    }
                    
                    if ($null -ne $script:estimatedTotalSeconds) {
                        $currentEta = $script:estimatedTotalSeconds - $hashElapsed.TotalSeconds
                        if ($currentEta -gt 0) {
                            $etaStr = "{0:mm\:ss}" -f [TimeSpan]::FromSeconds($currentEta)
                            $lblCounter.Text = "Hash: $($SyncHash.Progress)/$($SyncHash.Total) | Remaining: $etaStr"
                        } else {
                            $lblCounter.Text = "Hash: $($SyncHash.Progress)/$($SyncHash.Total) | Finishing..."
                        }
                    } else {
                        $lblCounter.Text = "Hash: $($SyncHash.Progress)/$($SyncHash.Total) | Calculating..."
                    }
                } else {
                    $lblCounter.Text = "Hash: $($SyncHash.Progress)/$($SyncHash.Total) | Initializing..."
                }
            }
        }

        if ($SyncHash.HasFinished -eq $true) {
            $timer.Stop(); $SyncHash.HasFinished = $false 
            
            $btnAvvia.Enabled = $true; $btnAnnulla.Enabled = $false; $btnAggiungi.Enabled = $true
            $chkAudio.Enabled = $true; $chkVideo.Enabled = $true; $chkFoto.Enabled = $true; $chkDoc.Enabled = $true
            $lblCounter.Text = "Completed! (Total: $([math]::Round(((Get-Date) - $script:startTime).TotalSeconds, 1)) sec)"
            $pb.Style = "Blocks"; $pb.Value = 0; $lblResultSummary.Text = "" 
            
            if ($SyncHash.Cancelled) { $txtLog.AppendText("`r`nOperation aborted by user.`r`n"); return }
            
            if ($null -eq $SyncHash.Result) {
                $txtLog.AppendText("`r`nOperation finished with an error (Result is null).`r`n")
                [System.Windows.Forms.MessageBox]::Show("Analysis interrupted by a critical error. Please check the log.", "Error", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Error)
                return
            }

            $esatti = @()
            $simili = @()
            if ($null -ne $SyncHash.Result.Esatti) { $esatti = @($SyncHash.Result.Esatti) }
            if ($null -ne $SyncHash.Result.Simili) { $simili = @($SyncHash.Result.Simili) }
            $SyncHash.Result = $null

            if ($esatti.Count -eq 0 -and $simili.Count -eq 0) { 
                [System.Windows.Forms.MessageBox]::Show("No duplicates found!"); 
                return 
            }
            
            $script:lastAnteprimaEsatti = $esatti
            $script:lastAnteprimaSimili = $simili
            $btnReopenPreview.Enabled = $true
            
            Show-PreviewAndProcess -AnteprimaEsatti $esatti -AnteprimaSimili $simili
        }
    })

    $btnAvvia.Add_Click({
        [string[]]$cartelle = @()
        foreach ($row in $dgvFolders.Rows) { 
            if ($row.Cells[0].Value -and -not [string]::IsNullOrWhiteSpace($row.Cells[0].Value.ToString())) { $cartelle += $row.Cells[0].Value.ToString() } 
        }
        if ($cartelle.Count -eq 0) { [System.Windows.Forms.MessageBox]::Show("Please add at least one folder!", "Warning", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Warning); return }

        [string[]]$estensioniScelte = @()
        if ($chkAudio.Checked) { $estensioniScelte += ".mp3", ".wav", ".flac", ".m4a", ".ogg", ".aac", ".wma" }
        if ($chkVideo.Checked) { $estensioniScelte += ".mp4", ".mkv", ".avi", ".mov", ".wmv", ".flv", ".webm" }
        if ($chkFoto.Checked)  { $estensioniScelte += ".jpg", ".jpeg", ".png", ".gif", ".bmp", ".tiff", ".heic" }
        if ($chkDoc.Checked)   { $estensioniScelte += ".pdf", ".doc", ".docx", ".txt", ".xls", ".xlsx", ".ppt", ".pptx" }
        if ($estensioniScelte.Count -eq 0) { [System.Windows.Forms.MessageBox]::Show("Select at least one file category!", "Warning", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Warning); return }
        
        $script:lastAnteprimaEsatti = $null
        $script:lastAnteprimaSimili = $null
        $btnReopenPreview.Enabled = $false
        $script:startTime = Get-Date
        $script:hashStartTime = $null
        $script:estimatedTotalSeconds = $null
        
        $btnAvvia.Enabled = $false; $btnAnnulla.Enabled = $true; $btnAggiungi.Enabled = $false
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