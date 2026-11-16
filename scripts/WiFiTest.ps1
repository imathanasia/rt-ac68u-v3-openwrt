<#
.SYNOPSIS
  Wi-Fi test for the ASUS RT-AC68U V3 OpenWrt build.

.DESCRIPTION
  Collects the Windows Wi-Fi link state, ping/latency to the router, the
  router's own status JSON, and (if iperf3 is installed) a TCP throughput
  test in both directions.  Prints one paste-able report.

  Run it once while connected to AC68U-V3-2G and once to AC68U-V3-5G.
  The router must be reachable at 192.168.1.200.

.PARAMETER Router
  Router address (default 192.168.1.200).

.PARAMETER Label
  Free-text tag shown in the report (e.g. "5G-far-room").

.PARAMETER Seconds
  iperf3 duration in seconds (default 10).

.EXAMPLE
  powershell -ExecutionPolicy Bypass -File .\WiFiTest.ps1 -Label "5G-near"

.NOTES
  No admin rights needed.  iperf3 is optional; install it with
      choco install iperf3 -y
  The router runs an iperf3 server on 192.168.1.200:5201.
#>

[CmdletBinding()]
param(
    [string]$Router = "192.168.1.200",
    [string]$Label = "",
    [int]$Seconds = 10
)

$ErrorActionPreference = "Continue"
$ProgressPreference = "SilentlyContinue"
$out = New-Object System.Collections.Generic.List[string]

function Add-Line([string]$s) { $out.Add($s) | Out-Null }
function Section([string]$t) {
    Add-Line ""
    Add-Line "## $t"
}
function Kv([string]$k, $v) {
    Add-Line ("{0,-28} {1}" -f ($k + ":"), $v)
}

# ---------------------------------------------------------------- environment
Add-Line "=== WiFiTest report ==="
Kv "timestamp" (Get-Date).ToString("yyyy-MM-dd HH:mm:ss K")
Kv "label" ($(if ($Label) { $Label } else { "(none)" }))
Kv "router" $Router
try {
    $os = Get-CimInstance Win32_OperatingSystem
    Kv "windows" ("{0} {1} (build {2})" -f $os.Caption, $os.Version, $os.BuildNumber)
} catch { Kv "windows" "unknown" }
Kv "powershell" $PSVersionTable.PSVersion.ToString()

# ---------------------------------------------------------------- wifi link
Section "Windows Wi-Fi link"
$wlan = $null
try {
    $raw = netsh wlan show interfaces 2>$null
    if ($raw -match "There is no wireless interface" -or $raw -match "no wireless") {
        Add-Line "NO WIRELESS INTERFACE (is the PC on Ethernet?)"
    } else {
        $wlan = @{}
        foreach ($line in $raw) {
            if ($line -match "^\s*([^:]+?)\s*:\s*(.+?)\s*$") {
                $k = $matches[1].Trim()
                $v = $matches[2].Trim()
                if (-not $wlan.ContainsKey($k)) { $wlan[$k] = $v }
            }
        }
        if ($wlan.Count -eq 0) {
            Add-Line "could not parse netsh keys - dumping raw"
            foreach ($line in $raw) { Add-Line ("netsh: " + $line) }
        }
        foreach ($k in @("Name","Description","State","SSID","BSSID","Network type","Radio type",
                         "Authentication","Cipher","Connection mode","Band","Channel",
                         "Receive rate (Mbps)","Transmit rate (Mbps)","Signal")) {
            if ($wlan.ContainsKey($k)) { Kv $k $wlan[$k] }
        }
    }
} catch {
    Add-Line ("netsh failed: " + $_.Exception.Message)
}

# ---------------------------------------------------------------- ping
Section "Ping $Router"
try {
    $pings = @()
    for ($i = 0; $i -lt 15; $i++) {
        $r = Test-Connection -ComputerName $Router -Count 1 -ErrorAction SilentlyContinue
        if ($r) { $pings += $r.ResponseTime }
        Start-Sleep -Milliseconds 150
    }
    if ($pings.Count -gt 0) {
        $st = $pings | Measure-Object -Minimum -Maximum -Average
        $jitter = 0
        if ($pings.Count -gt 1) {
            for ($i = 1; $i -lt $pings.Count; $i++) { $jitter += [math]::Abs($pings[$i] - $pings[$i-1]) }
            $jitter = [math]::Round($jitter / ($pings.Count - 1), 1)
        }
        Kv "sent" 15
        Kv "received" $pings.Count
        Kv "loss_pct" ([math]::Round((15 - $pings.Count) / 15 * 100, 1))
        Kv "rtt_min_ms" $st.Minimum
        Kv "rtt_avg_ms" ([math]::Round($st.Average, 1))
        Kv "rtt_max_ms" $st.Maximum
        Kv "jitter_ms" $jitter
    } else {
        Add-Line "no replies (router unreachable on this link)"
    }
} catch { Add-Line ("ping failed: " + $_.Exception.Message) }

# ---------------------------------------------------------------- http / router state
Section "Router HTTP"
$statusJson = $null
try {
    $sw = [System.Diagnostics.Stopwatch]::StartNew()
    $resp = Invoke-WebRequest -Uri ("http://{0}/cgi-bin/router-status" -f $Router) -UseBasicParsing -TimeoutSec 10
    $sw.Stop()
    Kv "status_cgi" ("HTTP {0} in {1} ms" -f $resp.StatusCode, $sw.ElapsedMilliseconds)
    $statusJson = $resp.Content | ConvertFrom-Json
} catch {
    Add-Line ("status CGI failed: " + $_.Exception.Message)
}
try {
    $r2 = Invoke-WebRequest -Uri ("http://{0}/cgi-bin/luci" -f $Router) -UseBasicParsing -TimeoutSec 10 -ErrorAction Stop
    Kv "luci" ("HTTP {0}" -f $r2.StatusCode)
} catch {
    $sc = $null
    if ($_.Exception.Response) { $sc = [int]$_.Exception.Response.StatusCode }
    Kv "luci" ("HTTP {0} (403 = login required, normal)" -f $sc)
}

if ($statusJson) {
    Section "Router state"
    Kv "uptime_s" $statusJson.uptime_s
    Kv "load" $statusJson.load
    Kv "mem_available_mib" $statusJson.mem_available_mib
    if ($statusJson.temps) {
        foreach ($t in $statusJson.temps) { Kv ("temp " + $t.zone) ($t.celsius + " C") }
    }
    if ($statusJson.wifi) {
        foreach ($w in $statusJson.wifi) {
            Kv ("radio " + $w.phy) ("{0} GHz ch{1} {2} MHz {3} tx={4} dBm" -f $w.band, $w.channel, $w.width, $w.ssid, $w.txpower)
        }
    }
    if ($statusJson.irqs) {
        foreach ($i in $statusJson.irqs) {
            Kv ("irq " + $i.irq + " " + $i.name) ("cpu0={0} cpu1={1}" -f $i.cpu0, $i.cpu1)
        }
    }
}

# ---------------------------------------------------------------- http throughput (sanity)
Section "HTTP sanity throughput (NOT a Wi-Fi limit - CGI caps ~90/170 Mbit/s)"
try {
    $sw = [System.Diagnostics.Stopwatch]::StartNew()
    $dl = Invoke-WebRequest -Uri ("http://{0}/cgi-bin/speed-down?mb=8" -f $Router) -UseBasicParsing -TimeoutSec 30
    $sw.Stop()
    $mbit = [math]::Round(($dl.RawContentLength * 8) / $sw.Elapsed.TotalSeconds / 1e6, 1)
    Kv "http_down_mbit" $mbit
} catch { Add-Line ("http down test failed: " + $_.Exception.Message) }

try {
    $bytes = New-Object byte[] (8 * 1MB)
    $sw = [System.Diagnostics.Stopwatch]::StartNew()
    $up = Invoke-WebRequest -Uri ("http://{0}/cgi-bin/speed-up" -f $Router) -Method Post -Body $bytes -UseBasicParsing -TimeoutSec 30
    $sw.Stop()
    $mbit = [math]::Round(($bytes.Length * 8) / $sw.Elapsed.TotalSeconds / 1e6, 1)
    Kv "http_up_mbit" $mbit
} catch { Add-Line ("http up test failed: " + $_.Exception.Message) }

# ---------------------------------------------------------------- iperf3
Section "iperf3 TCP throughput"
$iperf = $null
$iperfCandidates = @(
    (Get-Command iperf3 -ErrorAction SilentlyContinue).Source,
    "$env:ProgramData\chocolatey\bin\iperf3.exe",
    "$env:ProgramFiles\iperf3\iperf3.exe"
)
foreach ($c in $iperfCandidates) { if ($c -and (Test-Path $c)) { $iperf = $c; break } }
if (-not $iperf) {
    Add-Line "iperf3 NOT FOUND - install it with:  choco install iperf3 -y"
    Add-Line "then run this script again."
} else {
    Kv "iperf3" $iperf
    function Run-Iperf([string[]]$extra, [string]$tag) {
        $iperfArgs = @("-c", $Router, "-t", "$Seconds", "-P", "4", "-J", "--connect-timeout", "3") + $extra
        try {
            $raw = & $iperf @iperfArgs 2>$null
            $j = ($raw -join "`n") | ConvertFrom-Json
            $sent = [math]::Round($j.end.sum_sent.bits_per_second / 1e6, 1)
            $recv = [math]::Round($j.end.sum_received.bits_per_second / 1e6, 1)
            $retr = $j.end.sum_sent.retransmits
            Kv ($tag + "_sent_mbit") $sent
            Kv ($tag + "_recv_mbit") $recv
            Kv ($tag + "_retransmits") $retr
        } catch {
            Add-Line ($tag + " failed: " + $_.Exception.Message)
        }
    }
    # Uplink: PC -> router
    Run-Iperf @() "iperf_up"
    # Downlink: router -> PC
    Run-Iperf @("-R") "iperf_down"
}

Add-Line ""
Add-Line "=== end report ==="

$report = $out -join [Environment]::NewLine
$report | Write-Output
try {
    $path = Join-Path ([Environment]::GetFolderPath("Desktop")) ("wifitest-{0}.txt" -f (Get-Date).ToString("yyyyMMdd-HHmmss"))
    $report | Set-Content -Path $path -Encoding UTF8
    Write-Output ""
    Write-Output ("saved: " + $path)
} catch { }
