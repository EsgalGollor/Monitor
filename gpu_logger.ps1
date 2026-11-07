# Визначаємо папку, з якої реально запустили наш EXE
$currentDir = [System.IO.Directory]::GetCurrentDirectory()
$logPath = "$currentDir\log.txt"

if (-not (Test-Path $logPath)) {
    Write-Output "=== START GPU LOG: $(Get-Date) ===" | Out-File $logPath -Append
    Write-Output "Time                | Process              | GPU (%) | Executable Path" | Out-File $logPath -Append
    Write-Output "------------------------------------------------------------------------------------" | Out-File $logPath -Append
}

while ($true) {
    $gpuStats = Get-Counter -Counter "\GPU Engine(*)\Utilization Percentage" -ErrorAction SilentlyContinue

    if ($gpuStats) {
        $processes = $gpuStats.CounterSamples | 
            Where-Object { $_.CookedValue -gt 1 } | 
            Group-Object -Property {
                if ($_.Path -match "pid_(\d+)") {
                    $processId = $Matches[1]
                    try { (Get-Process -Id $processId).ProcessName } catch { "Unknown" }
                } else {
                    $_.InstanceName
                }
            }

        foreach ($group in $processes) {
            $totalGpu = [math]::Round(($group.Group | Measure-Object -Property CookedValue -Sum).Sum, 2)
            
            if ($totalGpu -gt 10) { 
                $time = (Get-Date).ToString("yyyy-MM-dd HH:mm:ss")
                $pName = $group.Name
                
                $pPath = try { 
                    (Get-Process -Name $pName -ErrorAction SilentlyContinue | Select-Object -First 1 -ExpandProperty Path) 
                } catch { 
                    "Access Denied / Not Found" 
                }
                
                if (-not $pPath) { $pPath = "Unknown" }

                $logLine = "{0} | {1,-20} | {2,-7} | {3}" -f $time, $pName, $totalGpu, $pPath
                Write-Output $logLine | Out-File $logPath -Append
            }
        }
    }
    Start-Sleep -Seconds 2
}
