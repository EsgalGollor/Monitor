$logPath = "$PSScriptRoot\cpu_log.txt"

if (-not (Test-Path $logPath)) {
    Write-Output "=== START CPU LOG: $(Get-Date) ===" | Out-File $logPath -Append
    Write-Output "Time                | Process              | CPU (%)" | Out-File $logPath -Append
    Write-Output "----------------------------------------------------" | Out-File $logPath -Append
}

while ($true) {
    $cpuStats = Get-Counter -Counter "\Process(*)\% Processor Time" -ErrorAction SilentlyContinue

    if ($cpuStats) {
        foreach ($sample in $cpuStats.CounterSamples) {
            $cores = [Environment]::ProcessorCount
            $totalCpu = [math]::Round(($sample.CookedValue / $cores), 2)
            $pName = $sample.InstanceName

            if ($totalCpu -gt 5 -and $pName -notmatch "idle|_total|powershell") { 
                $time = (Get-Date).ToString("yyyy-MM-dd HH:mm:ss")
                $logLine = "{0} | {1,-20} | {2}" -f $time, $pName, $totalCpu
                Write-Output $logLine | Out-File $logPath -Append
            }
        }
    }
    Start-Sleep -Seconds 2
}