Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

$currentDir = [System.IO.Directory]::GetCurrentDirectory()
$logPath = "$currentDir\hunter_log.txt"

function Remove-Autorun ($badPath) {
    $runPaths = @("HKCU:\Software\Microsoft\Windows\CurrentVersion\Run", "HKLM:\Software\Microsoft\Windows\CurrentVersion\Run")
    foreach ($path in $runPaths) {
        if (Test-Path $path) {
            Get-ItemProperty -Path $path | Get-Member -MemberType NoteProperty | ForEach-Object {
                if ((Get-ItemProperty -Path $path).$($_.Name) -like "*$badPath*") {
                    Remove-ItemProperty -Path $path -Name $_.Name -ErrorAction SilentlyContinue
                }
            }
        }
    }
}

$form = New-Object System.Windows.Forms.Form
$form.Text = "Process Hunter v1.0"
$form.Size = New-Object System.Drawing.Size(380,200)
$form.StartPosition = "CenterScreen"
$form.FormBorderStyle = "FixedDialog"
$form.MaximizeBox = $false

$label = New-Object System.Windows.Forms.Label
$label.Text = "Введіть назву процесу-шкідника (без .exe):"
$label.Location = New-Object System.Drawing.Point(20,20)
$label.Size = New-Object System.Drawing.Size(320,20)
$form.Controls.Add($label)

$textBox = New-Object System.Windows.Forms.TextBox
$textBox.Text = "print"
$textBox.Location = New-Object System.Drawing.Point(20,50)
$textBox.Size = New-Object System.Drawing.Size(320,25)
$form.Controls.Add($textBox)

$button = New-Object System.Windows.Forms.Button
$button.Text = "Почати полювання (Згорнути у фон)"
$button.Location = New-Object System.Drawing.Point(20,90)
$button.Size = New-Object System.Drawing.Size(320,35)
$button.BackColor = [System.Drawing.Color]::Crimson
$button.ForeColor = [System.Drawing.Color]::White
$button.Font = New-Object System.Drawing.Font("Arial", 10, [System.Drawing.FontStyle]::Bold)
$form.Controls.Add($button)

$button.Add_Click({
    $global:target = $textBox.Text.Trim()
    if ([string]::IsNullOrEmpty($global:target)) {
        [System.Windows.Forms.MessageBox]::Show("Введіть назву процесу!", "Помилка")
        return
    }
    
    $form.Hide()
    
    while ($true) {
        $procCheck = Get-Process -Name $global:target -ErrorAction SilentlyContinue
        if ($procCheck) {
            $pPath = try { $procCheck | Select-Object -First 1 -ExpandProperty Path } catch { $null }
            if ($pPath -and (Test-Path $pPath)) {
                
                # ЛІКВІДАЦІЯ
                Stop-Process -Name $global:target -Force -ErrorAction SilentlyContinue
                Start-Sleep -Milliseconds 500
                Remove-Item -Path $pPath -Force -ErrorAction SilentlyContinue
                Remove-Autorun -badPath $global:target
                
                # Логування успіху
                $time = (Get-Date).ToString("yyyy-MM-dd HH:mm:ss")
                "[{0}] KILLED & DELETED: {1} ({2})" -f $time, $global:target, $pPath | Out-File $logPath -Append
                
                break
            }
        }
        Start-Sleep -Seconds 1
    }
    $form.Close()
})

[System.Windows.Forms.Application]::Run($form)