$currentDir = [System.IO.Directory]::GetCurrentDirectory()
$gpuLog = "$currentDir\log.txt"
$cpuLog = "$currentDir\cpu_log.txt"
$diskLog = "$currentDir\disk_log.txt"

# Створення заголовків для файлів логів
function Init-Log($path, $title, $header) {
    if (-not (Test-Path $path)) {
        Write-Output "=== START $title LOG: $(Get-Date) ===" | Out-File $path -Append
        Write-Output $header | Out-File $path -Append
        Write-Output "------------------------------------------------------------------------------------" | Out-File $path -Append
    }
}

Init-Log $gpuLog "GPU" "Time                | Process              | GPU (%) | Executable Path"
Init-Log $cpuLog "CPU" "Time                | Process              | CPU (%) | Executable Path"
Init-Log $diskLog "DISK" "Time                | Process              | Disk (%)| Executable Path"

while ($true) {
    # 1. МОНІТОРИНГ GPU
    $gpuStats = Get-Counter -Counter "\GPU Engine(*)\Utilization Percentage" -ErrorAction SilentlyContinue
    if ($gpuStats) {
        $processes = $gpuStats.CounterSamples | Where-Object { $_.CookedValue -gt 1 } | Group-Object -Property {
            if ($_.Path -match "pid_(\d+)") {
                $processId = $Matches[1]
                try { (Get-Process -Id $processId).ProcessName } catch { "Unknown" }
            } else { $_.InstanceName }
        }
        foreach ($group in $processes) {
            $totalGpu = [math]::Round(($group.Group | Measure-Object -Property CookedValue -Sum).Sum, 2)
            if ($totalGpu -gt 10) {
                $pName = $group.Name
                $pPath = try { (Get-Process -Name $pName -ErrorAction SilentlyContinue | Select-Object -First 1 -ExpandProperty Path) } catch { "Access Denied" }
                if (-not $pPath) { $pPath = "Unknown" }
                "{0} | {1,-20} | {2,-7} | {3}" -f (Get-Date).ToString("yyyy-MM-dd HH:mm:ss"), $pName, $totalGpu, $pPath | Out-File $gpuLog -Append
            }
        }
    }

    # 2. МОНІТОРИНГ CPU
    $cpuStats = Get-Counter -Counter "\Process(*)\% Processor Time" -ErrorAction SilentlyContinue
    if ($cpuStats) {
        foreach ($sample in $cpuStats.CounterSamples) {
            $cores = [Environment]::ProcessorCount
            $totalCpu = [math]::Round(($sample.CookedValue / $cores), 2)
            $pName = $sample.InstanceName
            if ($totalCpu -gt 5 -and $pName -notmatch "idle|_total|powershell") {
                $pPath = try { (Get-Process -Name $pName -ErrorAction SilentlyContinue | Select-Object -First 1 -ExpandProperty Path) } catch { "Access Denied" }
                if (-not $pPath) { $pPath = "Unknown" }
                "{0} | {1,-20} | {2,-7} | {3}" -f (Get-Date).ToString("yyyy-MM-dd HH:mm:ss"), $pName, $totalCpu, $pPath | Out-File $cpuLog -Append
            }
        }
    }

    # 3. МОНІТОРИНГ ДИСКА
    $diskStats = Get-Counter -Counter "\Process(*)\% IO Time" -ErrorAction SilentlyContinue
    if ($diskStats) {
        foreach ($sample in $diskStats.CounterSamples) {
            $diskLoad = [math]::Round($sample.CookedValue, 2)
            $pName = $sample.InstanceName
            if ($diskLoad -gt 1 -and $pName -notmatch "idle|_total|powershell") {
                $pPath = try { (Get-Process -Name $pName -ErrorAction SilentlyContinue | Select-Object -First 1 -ExpandProperty Path) } catch { "Access Denied" }
                if (-not $pPath) { $pPath = "Unknown" }
                "{0} | {1,-20} | {2,-7} | {3}" -f (Get-Date).ToString("yyyy-MM-dd HH:mm:ss"), $pName, $diskLoad, $pPath | Out-File $diskLog -Append
            }
        }
    }

    Start-Sleep -Seconds 2
}