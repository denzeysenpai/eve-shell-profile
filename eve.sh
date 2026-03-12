# ================================
# EVE Utility Toolkit By 17 year old Mark, rewritten by older Mark
# ================================

function Write-EveHeader($title) {
    Write-Host ""
    Write-Host "========================================" -ForegroundColor DarkCyan
    Write-Host "  EVE :: $title" -ForegroundColor Cyan
    Write-Host "========================================" -ForegroundColor DarkCyan
}

function Write-EveError {
    $responses = @(
        "That command made no sense to me. Try 'eve help'.",
        "Syntax error detected. My circuits are confused.",
        "Did you type that with your elbows? Try 'eve help'.",
        "I searched the void and found... nothing.",
        "That command wandered into the wilderness.",
        "The bits rebelled. Try 'eve help'.",
        "Error 404: Your logic not found.",
        "Even my AI brain couldn't parse that.",
        "That command tripped over itself.",
        "The command gremlins stole your syntax.",
        "Nice try, but that command is illegal in 47 galaxies.",
        "My processor is laughing. Try again.",
        "You invented a new command. Sadly I don't support it.",
        "The command gods disapprove.",
        "Your syntax requires coffee.",
        "That command exists only in alternate timelines.",
        "This isn't the command you're looking for.",
        "I checked twice. Still nonsense.",
        "Command denied by the council of terminals.",
        "Somewhere a developer cried.",
        "My logs say: 'what?'",
        "That input triggered my sarcasm module."
    )

    $msg = Get-Random $responses
    Write-Host $msg -ForegroundColor Yellow
    Write-Host "Suggestion: eve help" -ForegroundColor DarkGray
}


function eve_help {
    Write-EveHeader "So you finally asked?"

    function Write-EveRow($cmd,$desc) {
        $pad = 30
        $left = $cmd.PadRight($pad)
        Write-Host $left -ForegroundColor Green -NoNewline
        Write-Host " | " -ForegroundColor DarkGray -NoNewline
        Write-Host $desc
    }

    Write-Host ""
    Write-Host "FILE UTILITIES" -ForegroundColor Cyan
    Write-Host ""

    Write-EveRow "eve tidy" "Organize Downloads folder by file type. Apartheid for downloaded files."
    Write-EveRow "eve notemp" "Clears temporary files. No temp files no more."
    Write-EveRow "eve find file <name>" "Search for a file recursively."
    Write-EveRow "eve find dir <name>" "Search for a directory recursively."

    Write-Host ""
    Write-Host "SYSTEM" -ForegroundColor Cyan
    Write-Host ""

    Write-EveRow "eve procs" "List running processes."
    Write-EveRow "eve disk" "Show disk usage statistics."
    Write-EveRow "eve doctor" "Run full system diagnostics."
    Write-EveRow "eve genocide" "Force terminate user applications."

    Write-Host ""
    Write-Host "NETWORK" -ForegroundColor Cyan
    Write-Host ""

    Write-EveRow "eve net test" "Run network latency diagnostics."
    Write-EveRow "eve net scan" "Scan local network and discover devices."

    Write-Host ""
    Write-Host "INFORMATION" -ForegroundColor Cyan
    Write-Host ""

    Write-EveRow "eve info ips" "Show local and public IP information."
    Write-EveRow "eve info ports" "List active TCP ports."
    Write-EveRow "eve info system" "Display system hardware information."
    Write-EveRow "eve info for=<path>" "Show detailed information about a file or directory."

    Write-Host ""
    Write-Host "HELP" -ForegroundColor Cyan
    Write-Host ""

    Write-EveRow "eve help" "Displays this command reference."

    Write-Host ""
    Write-Host "Tip: Commands are case-insensitive." -ForegroundColor DarkGray
}


function eve_tidy {

    Write-EveHeader "Download Organizer"

    $downloads = "$env:USERPROFILE\Downloads"

    Get-ChildItem $downloads -File | ForEach-Object {

        $ext = $_.Extension.Replace(".","")

        if (!$ext) { $ext = "misc" }

        $folder = Join-Path $downloads $ext

        if (!(Test-Path $folder)) {
            New-Item -ItemType Directory -Path $folder | Out-Null
        }

        Move-Item $_.FullName $folder -ErrorAction SilentlyContinue
    }

    Write-Host "Downloads organized successfully." -ForegroundColor Green
}


function eve_notemp {

    Write-EveHeader "Temp Cleaner"

    $temp = $env:TEMP
    $count = (Get-ChildItem $temp -Recurse -ErrorAction SilentlyContinue).Count

    Remove-Item "$temp\*" -Recurse -Force -ErrorAction SilentlyContinue

    Write-Host "$count temp files removed." -ForegroundColor Green
}


function eve_net_test {

    Write-EveHeader "Network Diagnostics"

    $targets = @("8.8.8.8","1.1.1.1","google.com")

    foreach ($t in $targets) {

        $result = Test-Connection $t -Count 3 -ErrorAction SilentlyContinue

        if ($result) {

            $avg = ($result | Measure-Object ResponseTime -Average).Average

            Write-Host "$t latency:" -NoNewline
            Write-Host " $avg ms" -ForegroundColor Green
        }
    }

    $speed = Get-NetAdapterStatistics | Select Name,ReceivedBytes,SentBytes

    Write-Host ""
    Write-Host "Network traffic:" -ForegroundColor Cyan
    $speed
}

function eve_procs {

    Write-EveHeader "Running Processes"

    Get-Process |
        Sort-Object CPU -Descending |
        Select-Object -First 20 Name,CPU,Id |
        Format-Table
}

function eve_find($type,$name) {

    Write-EveHeader "Finder"

    if (!$type -or !$name) {
        Write-EveError
        return
    }

    $path = Get-ChildItem -Recurse -ErrorAction SilentlyContinue |
        Where-Object {
            $_.Name -like "*$name*" -and
            (
                ($type -eq "file" -and !$_.PSIsContainer) -or
                ($type -eq "dir" -and $_.PSIsContainer)
            )
        } |
        Select-Object -First 1

    if ($path) {

        Write-Host "FOUND:" -ForegroundColor Green
        Write-Host $path.FullName -ForegroundColor Green

        Write-Host ""
        Write-Host "Sibling files:" -ForegroundColor Cyan

        Get-ChildItem $path.Directory
    }
    else {

        Write-Host "Nothing found matching '$name'." -ForegroundColor Yellow
    }
}

function eve_info_ips {
    Write-EveHeader "IP Addresses"
    Write-Host ""
    Write-Host "Local Network Interfaces" -ForegroundColor Cyan
    Get-NetIPAddress |
        Where-Object {$_.AddressFamily -eq "IPv4" -and $_.IPAddress -ne "127.0.0.1"} |
        Select-Object InterfaceAlias,IPAddress |
        Format-Table

    Write-Host ""
    Write-Host "Public Network Info" -ForegroundColor Cyan

    try {
        $ip = Invoke-RestMethod "https://ipinfo.io/json"

        Write-Host "Public IP :" $ip.ip -ForegroundColor Green
        Write-Host "City      :" $ip.city
        Write-Host "Region    :" $ip.region
        Write-Host "Country   :" $ip.country
        Write-Host "ISP       :" $ip.org
    }
    catch {

        Write-Host "Unable to retrieve public IP information." -ForegroundColor Yellow
    }
}

function eve_info_ports {

    Write-EveHeader "Active Ports"

    Get-NetTCPConnection |
        Select LocalAddress,LocalPort,State,OwningProcess |
        Sort LocalPort
}

function eve_info_for($arg) {

    $path = $arg -replace "for=",""

    if (!(Test-Path $path)) {

        Write-Host "Path not found." -ForegroundColor Yellow
        return
    }

    Write-EveHeader "File Information"

    Get-Item $path | Format-List *

}

function eve_info_system {

    Write-EveHeader "System Information"

    $os = Get-CimInstance Win32_OperatingSystem
    $cpu = Get-CimInstance Win32_Processor
    $ram = [math]::Round($os.TotalVisibleMemorySize/1MB,2)

    Write-Host "Computer :" $env:COMPUTERNAME -ForegroundColor Green
    Write-Host "User     :" $env:USERNAME -ForegroundColor Green
    Write-Host "CPU      :" $cpu.Name -ForegroundColor Green
    Write-Host "RAM      :" "$ram GB" -ForegroundColor Green
    Write-Host "Uptime   :" ((Get-Date) - $os.LastBootUpTime)
}

function eve_genocide {

    Write-Host ""
    Write-Host "WARNING:" -ForegroundColor Red
    Write-Host "This will forcefully terminate all running applications." -ForegroundColor Yellow
    Write-Host "System services will NOT be affected."
    Write-Host ""

    $confirm = Read-Host "Are you sure? Y/n"

    if ($confirm -ne "Y") {
        Write-Host "Operation cancelled." -ForegroundColor Yellow
        return
    }

    Write-Host ""
    Write-Host "Terminating user applications..." -ForegroundColor Red

    $systemProcesses = @(
        "System","Idle","wininit","csrss","services","lsass",
        "svchost","explorer"
    )

    Get-Process | Where-Object {
        $systemProcesses -notcontains $_.Name
    } | ForEach-Object {

        try {
            Stop-Process $_.Id -Force -ErrorAction SilentlyContinue
            Write-Host "Killed $($_.Name)" -ForegroundColor DarkRed
        }
        catch {}
    }

    Write-Host ""
    Write-Host "User applications terminated." -ForegroundColor Green
}

function eve_disk {

    Write-EveHeader "Disk Usage"

    Get-PSDrive -PSProvider FileSystem | ForEach-Object {

        $used = $_.Used / 1GB
        $free = $_.Free / 1GB
        $total = $used + $free

        $percent = [math]::Round(($used/$total)*100,2)

        Write-Host "$($_.Name): $percent% used  ($([math]::Round($used,2))GB / $([math]::Round($total,2))GB)" -ForegroundColor Cyan
    }
}

function eve_doctor {
    Write-EveHeader "System Diagnostics"

    $cpuLoad = (Get-CimInstance Win32_Processor | Measure-Object LoadPercentage -Average).Average

    if ($cpuLoad -lt 40) { $cpuColor = "Green"; $cpuStatus = "Healthy" }
    elseif ($cpuLoad -lt 75) { $cpuColor = "Yellow"; $cpuStatus = "Busy" }
    else { $cpuColor = "Red"; $cpuStatus = "Overloaded" }

    Write-Host "CPU Load :" -NoNewline
    Write-Host " $cpuLoad% ($cpuStatus)" -ForegroundColor $cpuColor

    $os = Get-CimInstance Win32_OperatingSystem
    $totalRam = [math]::Round($os.TotalVisibleMemorySize / 1MB,2)
    $freeRam = [math]::Round($os.FreePhysicalMemory / 1MB,2)
    $usedRam = [math]::Round($totalRam - $freeRam,2)
    $ramPercent = [math]::Round(($usedRam/$totalRam)*100,2)

    if ($ramPercent -lt 50) { $ramColor = "Green"; $ramStatus = "Healthy" }
    elseif ($ramPercent -lt 80) { $ramColor = "Yellow"; $ramStatus = "Heavy Usage" }
    else { $ramColor = "Red"; $ramStatus = "Critical" }

    Write-Host "RAM Usage:" -NoNewline
    Write-Host " $usedRam GB / $totalRam GB ($ramPercent%) - $ramStatus" -ForegroundColor $ramColor

    Write-Host ""
    Write-Host "Disk Health" -ForegroundColor Cyan

    Get-PSDrive -PSProvider FileSystem | ForEach-Object {

        $used = $_.Used / 1GB
        $free = $_.Free / 1GB
        $total = $used + $free
        $percent = [math]::Round(($used/$total)*100,2)

        if ($percent -lt 70) { $color="Green" }
        elseif ($percent -lt 90) { $color="Yellow" }
        else { $color="Red" }

        Write-Host "$($_.Name): $percent% used" -ForegroundColor $color
    }

    Write-Host ""
    Write-Host "Network Test" -ForegroundColor Cyan

    $ping = Test-Connection 8.8.8.8 -Count 3 -ErrorAction SilentlyContinue

    if ($ping) {

        $latency = ($ping | Measure-Object ResponseTime -Average).Average

        if ($latency -lt 30) { $netColor="Green"; $netStatus="Excellent" }
        elseif ($latency -lt 80) { $netColor="Yellow"; $netStatus="Good" }
        else { $netColor="Red"; $netStatus="Poor" }

        Write-Host "Latency:" -NoNewline
        Write-Host " $latency ms ($netStatus)" -ForegroundColor $netColor
    }
    else {
        Write-Host "Network unreachable." -ForegroundColor Red
    }

    Write-Host ""
    Write-Host "System Info" -ForegroundColor Cyan

    $boot = $os.LastBootUpTime
    $uptime = (Get-Date) - $boot

    Write-Host "Computer :" $env:COMPUTERNAME
    Write-Host "User     :" $env:USERNAME
    Write-Host "Uptime   :" "$($uptime.Days)d $($uptime.Hours)h $($uptime.Minutes)m"


    Write-Host ""
    Write-Host "Top CPU Big Bois" -ForegroundColor Cyan

    Get-Process |
        Sort-Object CPU -Descending |
        Select-Object -First 5 Name,
            @{Name="CPU_Time";Expression={[math]::Round($_.CPU,2)}},
            Id |
        Format-Table

    try {

        $temp = Get-WmiObject MSAcpi_ThermalZoneTemperature -Namespace "root/wmi" |
            Select-Object -First 1

        if ($temp) {

            $celsius = ($temp.CurrentTemperature / 10) - 273.15
            $celsius = [math]::Round($celsius,1)

            Write-Host ""
            Write-Host "CPU Temperature :" -NoNewline

            if ($celsius -lt 65) { $tColor="Green" }
            elseif ($celsius -lt 80) { $tColor="Yellow" }
            else { $tColor="Red" }

            Write-Host " $celsius °C" -ForegroundColor $tColor
        }

    } catch {}

    Write-Host ""
    Write-Host "Diagnostics complete. You are welcome." -ForegroundColor Cyan
}

function eve_net_scan {
    Write-EveHeader "Network UAV Inbound"

    Write-Host "Scanning local network..." -ForegroundColor Yellow
    # Get local IP
    $localIP = (Get-NetIPAddress -AddressFamily IPv4 |
        Where-Object {$_.IPAddress -notlike "169.*" -and $_.IPAddress -ne "127.0.0.1"} |
        Select-Object -First 1).IPAddress

    if (!$localIP) {
        Write-Host "Unable to detect local network." -ForegroundColor Red
        return
    }

    $subnet = $localIP.Substring(0,$localIP.LastIndexOf("."))

    Write-Host "Scanning subnet $subnet.0/24" -ForegroundColor Cyan
    Write-Host ""

    $results = @()

    for ($i=1;$i -le 254;$i++) {

        $ip = "$subnet.$i"

        Write-Progress -Activity "Network Scan" -Status $ip -PercentComplete (($i/254)*100)

        $ping = Test-Connection $ip -Count 1 -ErrorAction SilentlyContinue

        if ($ping) {
            $latency = $ping.ResponseTime

            try {
                $host = [System.Net.Dns]::GetHostEntry($ip).HostName
            }
            catch {
                $host = "Unknown"
            }

            $arp = arp -a | Select-String $ip

            if ($arp -match "([a-f0-9\-]{17})") {
                $mac = $matches[1]
            }
            else {
                $mac = "Unknown"
            }

            $commonPorts = 22,80,443,445,3389
            $openPorts = @()

            foreach ($p in $commonPorts) {
                try {
                    $tcp = New-Object Net.Sockets.TcpClient
                    $tcp.ConnectAsync($ip,$p).Wait(150)

                    if ($tcp.Connected) {
                        $openPorts += $p
                        $tcp.Close()
                    }
                }
                catch {}
            }

            $results += [PSCustomObject]@{
                IP = $ip
                Host = $host
                MAC = $mac
                Latency = "$latency ms"
                Ports = ($openPorts -join ",")
            }
        }
    }

    Clear-Host
    Write-EveHeader "UAV complete."

    if ($results.Count -eq 0) {
        Write-Host "No devices discovered. We'll get them next time." -ForegroundColor Yellow
        return
    }

    $results | Format-Table -AutoSize
}

function eve {

    param($a,$b,$c)

    switch ($a) {
        "tidy" { eve_tidy }
        "notemp" { eve_notemp }
        "procs" { eve_procs }
        "find" { eve_find $b $c }
        "genocide" { eve_genocide }
        "disk" { eve_disk }
        "doctor" { eve_doctor }


        "net" {
            switch ($b) {
                "test" { eve_net_test }
                "scan" { eve_net_scan }
                default { Write-EveError }
            }
        }

        "info" {
            if ($b -eq "ips") { eve_info_ips }
            elseif ($b -eq "ports") { eve_info_ports }
            elseif ($b -eq "system") { eve_info_system }
            elseif ($b -like "for=*") { eve_info_for $b }
            else { Write-EveError }
        }


        "help" { eve_help }
        default { Write-EveError }
    }
}