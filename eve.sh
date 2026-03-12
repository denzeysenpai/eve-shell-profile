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
    Write-EveHeader "Commands"

    Write-Host "eve tidy" -ForegroundColor Green
    Write-Host "  Organize Downloads folder by file type"

    Write-Host "eve notemp" -ForegroundColor Green
    Write-Host "  Clears temporary files"

    Write-Host "eve net test" -ForegroundColor Green
    Write-Host "  Network latency diagnostics"

    Write-Host "eve net scan" -ForegroundColor Green
    Write-Host "  Scan local network devices"

    Write-Host "eve procs" -ForegroundColor Green
    Write-Host "  List running processes"

    Write-Host "eve find file <name>" -ForegroundColor Green
    Write-Host "eve find dir <name>" -ForegroundColor Green

    Write-Host "eve info ips" -ForegroundColor Green
    Write-Host "eve info ports" -ForegroundColor Green
    Write-Host "eve info for=<path>" -ForegroundColor Green
    Write-Host "eve info system" -ForegroundColor Green
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


function eve_net_scan {

    Write-EveHeader "Network Device Scan"

    arp -a | ForEach-Object {

        if ($_ -match "dynamic") {

            Write-Host $_ -ForegroundColor Green
        }
    }
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

function eve {

    param($a,$b,$c)

    switch ($a) {
        "tidy" { eve_tidy }
        "notemp" { eve_notemp }
        "procs" { eve_procs }
        "find" { eve_find $b $c }
        "genocide" { eve_genocide }
        "disk" { eve_disk }

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