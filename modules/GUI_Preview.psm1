Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

function Show-PreviewWindow {
    param($AnteprimaEsatti, $AnteprimaSimili)
    
    $formAnt = New-Object System.Windows.Forms.Form
    $formAnt.Text = "Preview: Select what to delete"
    $formAnt.Size = New-Object System.Drawing.Size(1350, 750) 
    $formAnt.StartPosition = "CenterParent"
    $formAnt.FormBorderStyle = "Sizable"
    $formAnt.MaximizeBox = $true
    $formAnt.MinimumSize = New-Object System.Drawing.Size(1000, 600)
    
    $lblInfo = New-Object System.Windows.Forms.Label
    $lblInfo.Text = "Double-click '▶ Open' to view file. Double-click 'Path' to open folder."
    $lblInfo.Location = New-Object System.Drawing.Point(10, 10); $lblInfo.AutoSize = $true; $lblInfo.ForeColor = [System.Drawing.Color]::Blue
    $lblInfo.Anchor = "Top, Left"
    $formAnt.Controls.Add($lblInfo)

    $btnSelAll = New-Object System.Windows.Forms.Button
    $btnSelAll.Text = "Select All"; $btnSelAll.Location = New-Object System.Drawing.Point(10, 30); $btnSelAll.Size = New-Object System.Drawing.Size(120, 30); $btnSelAll.UseVisualStyleBackColor = $true
    $btnSelAll.Anchor = "Top, Left"
    $formAnt.Controls.Add($btnSelAll)

    $btnDeselAll = New-Object System.Windows.Forms.Button
    $btnDeselAll.Text = "Deselect All"; $btnDeselAll.Location = New-Object System.Drawing.Point(140, 30); $btnDeselAll.Size = New-Object System.Drawing.Size(120, 30); $btnDeselAll.UseVisualStyleBackColor = $true
    $btnDeselAll.Anchor = "Top, Left"
    $formAnt.Controls.Add($btnDeselAll)

    $chkShowSimilar = New-Object System.Windows.Forms.CheckBox
    $chkShowSimilar.Text = "Show similar files (same name, different sizes)"
    $chkShowSimilar.Location = New-Object System.Drawing.Point(280, 35); $chkShowSimilar.Size = New-Object System.Drawing.Size(350, 20)
    $chkShowSimilar.Font = New-Object System.Drawing.Font("Segoe UI", 9, [System.Drawing.FontStyle]::Bold); $chkShowSimilar.Checked = $false; $chkShowSimilar.UseVisualStyleBackColor = $true
    $chkShowSimilar.Anchor = "Top, Left"
    $formAnt.Controls.Add($chkShowSimilar)

    $chkBoldOriginal = New-Object System.Windows.Forms.CheckBox
    $chkBoldOriginal.Text = "Bold originals"; $chkBoldOriginal.Location = New-Object System.Drawing.Point(650, 35); $chkBoldOriginal.Size = New-Object System.Drawing.Size(200, 20); $chkBoldOriginal.Checked = $true; $chkBoldOriginal.UseVisualStyleBackColor = $true
    $chkBoldOriginal.Anchor = "Top, Left"
    $formAnt.Controls.Add($chkBoldOriginal)

    $lblSummary = New-Object System.Windows.Forms.Label
    $lblSummary.Text = "Calculating summary..."; $lblSummary.Location = New-Object System.Drawing.Point(860, 35); $lblSummary.Size = New-Object System.Drawing.Size(460, 20)
    $lblSummary.Font = New-Object System.Drawing.Font("Segoe UI", 10, [System.Drawing.FontStyle]::Bold); $lblSummary.ForeColor = [System.Drawing.Color]::DarkSlateGray; $lblSummary.TextAlign = "MiddleRight"
    $lblSummary.Anchor = "Top, Right"
    $formAnt.Controls.Add($lblSummary)

    $lblSearch = New-Object System.Windows.Forms.Label
    $lblSearch.Text = "Search by name:"; $lblSearch.Location = New-Object System.Drawing.Point(10, 70); $lblSearch.AutoSize = $true
    $formAnt.Controls.Add($lblSearch)

    $txtSearch = New-Object System.Windows.Forms.TextBox
    $txtSearch.Location = New-Object System.Drawing.Point(110, 68); $txtSearch.Size = New-Object System.Drawing.Size(250, 20)
    $txtSearch.Anchor = "Top, Left"
    $formAnt.Controls.Add($txtSearch)

    $listView = New-Object System.Windows.Forms.ListView
    $listView.Location = New-Object System.Drawing.Point(10, 100); $listView.Size = New-Object System.Drawing.Size(1310, 470)
    $listView.View = "Details"; $listView.CheckBoxes = $true; $listView.FullRowSelect = $true; $listView.GridLines = $true; $listView.HideSelection = $false
    $listView.Anchor = "Top, Bottom, Left, Right"
    
    $imgList = New-Object System.Windows.Forms.ImageList
    $imgList.ImageSize = New-Object System.Drawing.Size(24,24); $imgList.ColorDepth = [System.Windows.Forms.ColorDepth]::Depth32Bit
    $iconCache = @{}
    
    $listView.SmallImageList = $imgList
    
    $listView.Columns.Add("Select", 70) | Out-Null
    $listView.Columns.Add("Group", 60) | Out-Null
    $listView.Columns.Add("Action", 170) | Out-Null
    $listView.Columns.Add("Actions", 80) | Out-Null 
    $listView.Columns.Add("File Name", 280) | Out-Null 
    $listView.Columns.Add("Type", 70) | Out-Null 
    $listView.Columns.Add("Size", 100) | Out-Null; 
    $listView.Columns.Add("Modified", 100) | Out-Null
    $listView.Columns.Add("Created", 100) | Out-Null
    $listView.Columns.Add("Path", 350) | Out-Null
    
    $script:lastClickX = 0; $script:lastClickY = 0; $script:searchText = ""

    $updateSummary = {
        $selezionati = @($listView.Items | Where-Object { $_.Checked })
        $totEsatti = 0; $totSimili = 0; $byteTotali = 0
        foreach ($lv in $selezionati) {
            if ($lv.Tag.Tipo -eq "Exact") { $totEsatti++ } else { $totSimili++ }
            $byteTotali += $lv.Tag.OggettoOriginale.Length
        }
        $mbTotali = [math]::Round($byteTotali / 1MB, 2); $gbTotali = [math]::Round($byteTotali / 1GB, 2)
        $testoSpazio = if ($gbTotali -ge 1) { "$gbTotali GB" } else { "$mbTotali MB" }
        $lblSummary.Text = "Selected: $($selezionati.Count) files (Exact: $totEsatti, Similar: $totSimili)  |  Space to free: $testoSpazio"
    }

    $populateList = {
        $listView.BeginUpdate(); $listView.Items.Clear()
        $itemsToShow = @(); $itemsToShow += $AnteprimaEsatti
        if ($chkShowSimilar.Checked) { $itemsToShow += $AnteprimaSimili }
        if ($script:searchText -ne "") { $itemsToShow = $itemsToShow | Where-Object { $_.Nome -like "*$($script:searchText)*" -or $_.Percorso -like "*$($script:searchText)*" } }
        $itemsToShow = $itemsToShow | Sort-Object -Property @{Expression="Gruppo";Descending=$false}, @{Expression="IsOriginal";Descending=$true}

        foreach ($item in $itemsToShow) {
            $lvItem = New-Object System.Windows.Forms.ListViewItem("")
            
            $ext = [System.IO.Path]::GetExtension($item.Percorso).ToLower()
            $tipoFile = $ext.TrimStart('.').ToUpper()
            if ([string]::IsNullOrWhiteSpace($tipoFile)) { $tipoFile = "FILE" }
            
            if (-not $iconCache.ContainsKey($ext)) {
                try { $ico = [System.Drawing.Icon]::ExtractAssociatedIcon($item.Percorso); $imgList.Images.Add($ico); $iconCache[$ext] = $imgList.Images.Count - 1 } catch { $iconCache[$ext] = -1 }
            }
            $lvItem.ImageIndex = $iconCache[$ext]
            
            $lvItem.SubItems.Add($item.Gruppo.ToString()) | Out-Null
            $lvItem.SubItems.Add($item.Azione) | Out-Null
            $lvItem.SubItems.Add("▶ Open") | Out-Null
            $lvItem.SubItems.Add($item.Nome) | Out-Null
            $lvItem.SubItems.Add($tipoFile) | Out-Null
            $lvItem.SubItems.Add($item.Dimensione) | Out-Null
            $lvItem.SubItems.Add($item.Modifica) | Out-Null
            $lvItem.SubItems.Add($item.Creazione) | Out-Null
            $lvItem.SubItems.Add($item.Percorso) | Out-Null
            
            if ($item.IsOriginal) { 
                $lvItem.ForeColor = [System.Drawing.Color]::Green 
                if ($chkBoldOriginal.Checked) { $lvItem.Font = New-Object System.Drawing.Font($listView.Font, [System.Drawing.FontStyle]::Bold) }
            } elseif ($item.Tipo -eq "Similar") { $lvItem.ForeColor = [System.Drawing.Color]::DarkOrange }
            else { $lvItem.ForeColor = [System.Drawing.Color]::Red }
            
            if (-not $item.IsOriginal -and $item.Tipo -eq "Exact") { $lvItem.Checked = $true }
            $lvItem.Tag = $item; $listView.Items.Add($lvItem) | Out-Null
        }
        $listView.EndUpdate(); & $updateSummary
    }

    $listView.Add_MouseDown({ param($sender, $e); $script:lastClickX = $e.X; $script:lastClickY = $e.Y })
    
    $listView.Add_MouseDoubleClick({
        param($sender, $e)
        $hit = $listView.HitTest($e.X, $e.Y)
        if ($hit.Item -and $hit.SubItem) {
            $colIndex = $hit.Item.SubItems.IndexOf($hit.SubItem)
            $filePath = $hit.Item.Tag.Percorso
            if ($colIndex -eq 3) { try { Start-Process $filePath } catch { } }
            elseif ($colIndex -eq 9) { Start-Process explorer.exe -ArgumentList "/select,`"$filePath`"" }
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
    $menuOpenFile = $contextMenu.Items.Add("▶ Open File"); $menuOpenFolder = $contextMenu.Items.Add("📁 Open Folder"); $menuCopyPath = $contextMenu.Items.Add("📋 Copy Path")
    $listView.ContextMenuStrip = $contextMenu
    $menuOpenFile.Add_Click({ if ($listView.SelectedItems.Count -gt 0) { Start-Process $listView.SelectedItems[0].Tag.Percorso } })
    $menuOpenFolder.Add_Click({ if ($listView.SelectedItems.Count -gt 0) { Start-Process explorer.exe -ArgumentList "/select,`"$($listView.SelectedItems[0].Tag.Percorso)`"" } })
    $menuCopyPath.Add_Click({ if ($listView.SelectedItems.Count -gt 0) { Set-Clipboard -Value $listView.SelectedItems[0].Tag.Percorso } })

    $btnSelAll.Add_Click({ foreach ($lvItem in $listView.Items) { if (-not $lvItem.Tag.IsOriginal) { $lvItem.Checked = $true } }; & $updateSummary })
    $btnDeselAll.Add_Click({ foreach ($lvItem in $listView.Items) { $lvItem.Checked = $false }; & $updateSummary })
    $chkShowSimilar.Add_CheckedChanged({ & $populateList }); $chkBoldOriginal.Add_CheckedChanged({ & $populateList })
    $txtSearch.Add_TextChanged({ $script:searchText = $txtSearch.Text; & $populateList })

    $formAnt.Controls.Add($listView)
    
    $btnProcedi = New-Object System.Windows.Forms.Button
    $btnProcedi.Text = "PROCEED WITH SELECTED"; $btnProcedi.Location = New-Object System.Drawing.Point(10, 580); $btnProcedi.Size = New-Object System.Drawing.Size(500, 40); $btnProcedi.BackColor = [System.Drawing.Color]::LightGreen
    $btnProcedi.Font = New-Object System.Drawing.Font("Segoe UI", 10, [System.Drawing.FontStyle]::Bold); $btnProcedi.UseVisualStyleBackColor = $true
    $btnProcedi.Anchor = "Bottom, Left"
    $formAnt.Controls.Add($btnProcedi)
    
    $btnAnnAnt = New-Object System.Windows.Forms.Button
    $btnAnnAnt.Text = "CANCEL"; $btnAnnAnt.Location = New-Object System.Drawing.Point(550, 580); $btnAnnAnt.Size = New-Object System.Drawing.Size(770, 40); $btnAnnAnt.BackColor = [System.Drawing.Color]::LightCoral; $btnAnnAnt.UseVisualStyleBackColor = $true
    $btnAnnAnt.Anchor = "Bottom, Right"
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
    return $script:selezionati
}
Export-ModuleMember -Function Show-PreviewWindow
