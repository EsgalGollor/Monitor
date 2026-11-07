$logPath = "$PSScriptRoot\disk_log.txt"

if (-not (Test-Path $logPath)) {
    Write-Output "=== START DISK LOG: $(Get-Date) ===" | Out-File $logPath -Append
    Write-Output "Time                | Process              | Disk Time (%)" | Out-File $logPath -Append
    Write-Output "----------------------------------------------------" | Out-File $logPath -Append
}

while ($true) {
    $diskStats = Get-Counter -Counter "\Process(*)\% IO Time" -ErrorAction SilentlyContinue

    if ($diskStats) {
        foreach ($sample in $diskStats.CounterSamples) {
            $diskLoad = [math]::Round($sample.CookedValue, 2)
            $pName = $sample.InstanceName

            if ($diskLoad -gt 1 -and $pName -notmatch "idle|_total|powershell") { 
                $time = (Get-Date).ToString("yyyy-MM-dd HH:mm:ss")
                $logLine = "{0} | {1,-20} | {2}" -f $time, $pName, $diskLoad
                Write-Output $logLine | Out-File $logPath -Append
            }
        }
    }
    Start-Sleep -Seconds 2
}
