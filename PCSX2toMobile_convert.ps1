Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

# --- Form Configuration ---
$form = New-Object System.Windows.Forms.Form
$form.Text = "PCSX2 to Mobile Hash Renamer"
$form.Size = New-Object System.Drawing.Size(400, 250)
$form.StartPosition = "CenterScreen"
$form.FormBorderStyle = "FixedDialog"
$form.MaximizeBox = $false
# Note: Ensure AppIconLarge.ico is in the same directory or comment out the next two lines
if (Test-Path ".\AppIconLarge.ico") {
    $icon = New-Object System.Drawing.Icon(".\AppIconLarge.ico")
    $form.Icon = $icon
}

# --- Folder Path Label ---
$label = New-Object System.Windows.Forms.Label
$label.Text = "Target Folder:"
$label.Location = New-Object System.Drawing.Point(10, 20)
$label.AutoSize = $true
$form.Controls.Add($label)

# --- Folder Path TextBox ---
$txtPath = New-Object System.Windows.Forms.TextBox
$txtPath.Location = New-Object System.Drawing.Point(10, 40)
$txtPath.Size = New-Object System.Drawing.Size(280, 20)
$txtPath.ReadOnly = $true
$form.Controls.Add($txtPath)

# --- Browse Button ---
$btnBrowse = New-Object System.Windows.Forms.Button
$btnBrowse.Text = "Browse"
$btnBrowse.Location = New-Object System.Drawing.Point(300, 38)
$btnBrowse.Add_Click({
    $folderBrowser = New-Object System.Windows.Forms.FolderBrowserDialog
    if ($folderBrowser.ShowDialog() -eq "OK") {
        $txtPath.Text = $folderBrowser.SelectedPath
    }
})
$form.Controls.Add($btnBrowse)

# --- Recursive Checkbox ---
$chkRecursive = New-Object System.Windows.Forms.CheckBox
$chkRecursive.Text = "Search Subfolders (Recursive)"
$chkRecursive.Location = New-Object System.Drawing.Point(10, 80)
$chkRecursive.Size = New-Object System.Drawing.Size(200, 20)
$chkRecursive.Checked = $true 
$form.Controls.Add($chkRecursive)

# --- Run Button ---
$btnRun = New-Object System.Windows.Forms.Button
$btnRun.Text = "Start Renaming"
$btnRun.Location = New-Object System.Drawing.Point(10, 130)
$btnRun.Size = New-Object System.Drawing.Size(365, 40)
$btnRun.BackColor = [System.Drawing.Color]::LightGreen

$btnRun.Add_Click({
    $path = $txtPath.Text

    if (-not (Test-Path $path)) {
        [System.Windows.Forms.MessageBox]::Show("Please select a valid folder first.", "Error")
        return
    }

    try {
        # Get all files (ignoring folders)
        $files = Get-ChildItem -Path $path -Recurse:($chkRecursive.Checked) | Where-Object { -not $_.PSIsContainer }

        $count = 0

        foreach ($file in $files) {
            # Split by dash: 57e170fada3a0670-5745b0c0657d9605-80001dd3
            $parts = $file.BaseName -split '-'
            
            # Based on your example, the hash we want is the LAST part
            if ($parts.Count -ge 3) {
                $lastIndex = $parts.Count - 1
                $bitsHex = $parts[$lastIndex]

                # Check if it's an 8-character hex string
                if ($bitsHex -match "^[0-9a-fA-F]{8}$") {
                    $bitsInt = [Convert]::ToUInt32($bitsHex, 16)
                    
                    # LOGIC SWAP: If setting the bit does nothing, 
                    # we might need to verify which bit your specific dump version needs.
                    # This line sets Bit 14 (0x4000). 
                    $newBitsInt = $bitsInt -bor 0x4000
                    
                    $newBitsHex = [Convert]::ToString($newBitsInt, 16).PadLeft(8, '0')

                    # DEBUG: If you want to FORCE it to change 80001dd3 to 80005dd3 specifically:
                    # $newBitsHex = $bitsHex -replace '1dd3$', '5dd3'

                    if ($bitsHex -ne $newBitsHex) {
                        $parts[$lastIndex] = $newBitsHex
                        $newName = ($parts -join '-') + $file.Extension
                        
                        Rename-Item -Path $file.FullName -NewName $newName -Force
                        $count++
                    }
                }
            }
        }

        [System.Windows.Forms.MessageBox]::Show("Successfully processed $count files!", "Success")
    }
    catch {
        [System.Windows.Forms.MessageBox]::Show("Error: $($_.Exception.Message)", "Error")
    }
})
$form.Controls.Add($btnRun)

# --- Show the GUI ---
$form.ShowDialog() | Out-Null
