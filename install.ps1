try {
    [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.SecurityProtocolType]3072 -bor [System.Net.SecurityProtocolType]768 -bor [System.Net.SecurityProtocolType]192
} catch {}

try {
    [Console]::OutputEncoding = [System.Text.Encoding]::UTF8
    $OutputEncoding = [System.Text.Encoding]::UTF8
} catch {}

Add-Type -AssemblyName PresentationFramework, PresentationCore, WindowsBase

function Start-WpfInstallerApp {
    $global:CurrentLang = "EN"
    $global:i18n = @{
        EN = @{
            Title        = "FakeMuteDeafen"
            BtnStable    = "Discord"
            BtnPTB       = "Discord PTB"
            BtnCanary    = "Discord Canary"
            BtnAll       = "Install All"
            BtnUninstall = "Uninstall"
            Ready        = "Ready"
            Working      = "Working..."
            Done         = "Done"
            Error        = "Error: {0}"
            LangBtn      = "TH"
        }
        TH = @{
            Title        = "FakeMuteDeafen"
            BtnStable    = "Discord"
            BtnPTB       = "Discord PTB"
            BtnCanary    = "Discord Canary"
            BtnAll       = "ติดตั้งทั้งหมด"
            BtnUninstall = "ถอนการติดตั้ง"
            Ready        = "พร้อมทำงาน"
            Working      = "กำลังทำงาน..."
            Done         = "เสร็จสิ้น"
            Error        = "ผิดพลาด: {0}"
            LangBtn      = "EN"
        }
    }

    [xml]$xaml = @"
<Window xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
        xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml"
        Title="FakeMuteDeafen"
        Height="370" Width="380"
        WindowStartupLocation="CenterScreen"
        WindowStyle="None"
        AllowsTransparency="True"
        Background="Transparent"
        FontFamily="Segoe UI, Leelawadee UI, Tahoma, sans-serif"
        ResizeMode="NoResize">

    <Window.Resources>
        <Style x:Key="Btn" TargetType="Button">
            <Setter Property="Background" Value="#2B2D31"/>
            <Setter Property="Foreground" Value="#F2F3F5"/>
            <Setter Property="FontSize" Value="13"/>
            <Setter Property="FontWeight" Value="SemiBold"/>
            <Setter Property="Height" Value="36"/>
            <Setter Property="Margin" Value="0,0,0,8"/>
            <Setter Property="Cursor" Value="Hand"/>
            <Setter Property="BorderThickness" Value="1"/>
            <Setter Property="BorderBrush" Value="#383A40"/>
            <Setter Property="Template">
                <Setter.Value>
                    <ControlTemplate TargetType="Button">
                        <Border x:Name="bd" Background="{TemplateBinding Background}"
                                BorderBrush="{TemplateBinding BorderBrush}"
                                BorderThickness="{TemplateBinding BorderThickness}"
                                CornerRadius="6">
                            <ContentPresenter HorizontalAlignment="Center" VerticalAlignment="Center"/>
                        </Border>
                        <ControlTemplate.Triggers>
                            <Trigger Property="IsMouseOver" Value="True">
                                <Setter TargetName="bd" Property="Background" Value="#35373C"/>
                            </Trigger>
                            <Trigger Property="IsPressed" Value="True">
                                <Setter TargetName="bd" Property="Background" Value="#1E1F22"/>
                            </Trigger>
                            <Trigger Property="IsEnabled" Value="False">
                                <Setter TargetName="bd" Property="Opacity" Value="0.4"/>
                            </Trigger>
                        </ControlTemplate.Triggers>
                    </ControlTemplate>
                </Setter.Value>
            </Setter>
        </Style>

        <Style x:Key="BtnPrimary" TargetType="Button" BasedOn="{StaticResource Btn}">
            <Setter Property="Background" Value="#5865F2"/>
            <Setter Property="BorderBrush" Value="#4752C4"/>
            <Setter Property="Template">
                <Setter.Value>
                    <ControlTemplate TargetType="Button">
                        <Border x:Name="bd" Background="{TemplateBinding Background}"
                                BorderBrush="{TemplateBinding BorderBrush}"
                                BorderThickness="{TemplateBinding BorderThickness}"
                                CornerRadius="6">
                            <ContentPresenter HorizontalAlignment="Center" VerticalAlignment="Center"/>
                        </Border>
                        <ControlTemplate.Triggers>
                            <Trigger Property="IsMouseOver" Value="True">
                                <Setter TargetName="bd" Property="Background" Value="#4752C4"/>
                            </Trigger>
                            <Trigger Property="IsEnabled" Value="False">
                                <Setter TargetName="bd" Property="Opacity" Value="0.4"/>
                            </Trigger>
                        </ControlTemplate.Triggers>
                    </ControlTemplate>
                </Setter.Value>
            </Setter>
        </Style>

        <Style x:Key="BtnDanger" TargetType="Button" BasedOn="{StaticResource Btn}">
            <Setter Property="Foreground" Value="#F23F43"/>
            <Setter Property="BorderBrush" Value="#DA373C"/>
            <Setter Property="Margin" Value="0"/>
        </Style>

        <Style x:Key="BtnWin" TargetType="Button">
            <Setter Property="Background" Value="Transparent"/>
            <Setter Property="Foreground" Value="#949BA4"/>
            <Setter Property="Width" Value="28"/>
            <Setter Property="Height" Value="24"/>
            <Setter Property="Cursor" Value="Hand"/>
            <Setter Property="Template">
                <Setter.Value>
                    <ControlTemplate TargetType="Button">
                        <Border x:Name="bd" Background="{TemplateBinding Background}" CornerRadius="4">
                            <ContentPresenter HorizontalAlignment="Center" VerticalAlignment="Center"/>
                        </Border>
                        <ControlTemplate.Triggers>
                            <Trigger Property="IsMouseOver" Value="True">
                                <Setter TargetName="bd" Property="Background" Value="#35373C"/>
                                <Setter Property="Foreground" Value="#FFFFFF"/>
                            </Trigger>
                        </ControlTemplate.Triggers>
                    </ControlTemplate>
                </Setter.Value>
            </Setter>
        </Style>
    </Window.Resources>

    <Border Background="#1E1F22" BorderBrush="#313338" BorderThickness="1" CornerRadius="10">
        <Grid>
            <Grid.RowDefinitions>
                <RowDefinition Height="38"/>
                <RowDefinition Height="*"/>
                <RowDefinition Height="Auto"/>
            </Grid.RowDefinitions>

            <Border Grid.Row="0" Name="TitleBar" Background="#18191C" CornerRadius="10,10,0,0">
                <Grid Margin="12,0,8,0">
                    <Grid.ColumnDefinitions>
                        <ColumnDefinition Width="*"/>
                        <ColumnDefinition Width="Auto"/>
                    </Grid.ColumnDefinitions>

                    <TextBlock Name="txtTitle" Text="FakeMuteDeafen" Foreground="#F2F3F5" FontSize="13" FontWeight="SemiBold" VerticalAlignment="Center"/>

                    <StackPanel Grid.Column="1" Orientation="Horizontal" VerticalAlignment="Center">
                        <Button Name="btnLang" Style="{StaticResource BtnWin}" Content="TH" Margin="0,0,4,0"/>
                        <Button Name="btnMin" Style="{StaticResource BtnWin}" Content="-" Margin="0,0,2,0"/>
                        <Button Name="btnClose" Style="{StaticResource BtnWin}" Content="X"/>
                    </StackPanel>
                </Grid>
            </Border>

            <StackPanel Grid.Row="1" Margin="20,16,20,12">
                <Button Name="btnStable" Style="{StaticResource Btn}" Content="Discord"/>
                <Button Name="btnPTB" Style="{StaticResource Btn}" Content="Discord PTB"/>
                <Button Name="btnCanary" Style="{StaticResource Btn}" Content="Discord Canary"/>
                <Button Name="btnAll" Style="{StaticResource BtnPrimary}" Content="Install All"/>
                <Button Name="btnUninstall" Style="{StaticResource BtnDanger}" Content="Uninstall"/>
            </StackPanel>

            <Border Grid.Row="2" Padding="20,0,20,14">
                <StackPanel>
                    <TextBlock Name="lblStatus" Text="Ready" Foreground="#949BA4" FontSize="12" Margin="0,0,0,6"/>
                    <ProgressBar Name="pb" Height="4" Background="#2B2D31" Foreground="#5865F2" BorderThickness="0" Value="0" Maximum="100"/>
                </StackPanel>
            </Border>
        </Grid>
    </Border>
</Window>
"@

    $reader = (New-Object System.Xml.XmlNodeReader $xaml)
    $window = [System.Windows.Markup.XamlReader]::Load($reader)

    $TitleBar     = $window.FindName("TitleBar")
    $txtTitle     = $window.FindName("txtTitle")
    $btnLang      = $window.FindName("btnLang")
    $btnMin       = $window.FindName("btnMin")
    $btnClose     = $window.FindName("btnClose")

    $btnStable    = $window.FindName("btnStable")
    $btnPTB       = $window.FindName("btnPTB")
    $btnCanary    = $window.FindName("btnCanary")
    $btnAll       = $window.FindName("btnAll")
    $btnUninstall = $window.FindName("btnUninstall")

    $lblStatus    = $window.FindName("lblStatus")
    $pb           = $window.FindName("pb")

    $TitleBar.Add_MouseLeftButtonDown({ $window.DragMove() })
    $btnMin.Add_Click({ $window.WindowState = 'Minimized' })
    $btnClose.Add_Click({ $window.Close() })

    $global:BrushConverter = New-Object System.Windows.Media.BrushConverter
    function Get-Brush($hex) {
        return $global:BrushConverter.ConvertFromString($hex)
    }

    function Update-Language {
        $d = $global:i18n[$global:CurrentLang]
        $txtTitle.Text     = $d.Title
        $btnLang.Content   = $d.LangBtn
        $btnStable.Content = $d.BtnStable
        $btnPTB.Content    = $d.BtnPTB
        $btnCanary.Content = $d.BtnCanary
        $btnAll.Content    = $d.BtnAll
        $btnUninstall.Content = $d.BtnUninstall
        $lblStatus.Text    = $d.Ready
    }

    $btnLang.Add_Click({
        if ($global:CurrentLang -eq "EN") { $global:CurrentLang = "TH" } else { $global:CurrentLang = "EN" }
        Update-Language
    })

    function Get-DiscordPaths {
        $res = @{ "Discord" = @(); "DiscordPTB" = @(); "DiscordCanary" = @() }
        $list = @(
            @{ B = "Discord";       P = "$env:LOCALAPPDATA\Discord" },
            @{ B = "DiscordPTB";    P = "$env:LOCALAPPDATA\DiscordPTB" },
            @{ B = "DiscordCanary"; P = "$env:LOCALAPPDATA\DiscordCanary" }
        )
        foreach ($i in $list) {
            if (Test-Path $i.P) { $res[$i.B] += $i.P }
        }
        if (Test-Path "C:\ProgramData") {
            foreach ($k in @("Discord", "DiscordPTB", "DiscordCanary")) {
                $m = Get-ChildItem "C:\ProgramData" -Directory -Recurse -Depth 2 -Filter "*$k*" -ErrorAction SilentlyContinue | Select-Object -ExpandProperty FullName
                if ($m) {
                    foreach ($x in $m) {
                        if ($x -and -not ($res[$k] -contains $x)) { $res[$k] += $x }
                    }
                }
            }
        }
        return $res
    }

    function Set-State($en) {
        $btnStable.IsEnabled    = $en
        $btnPTB.IsEnabled       = $en
        $btnCanary.IsEnabled    = $en
        $btnAll.IsEnabled       = $en
        $btnUninstall.IsEnabled = $en
        $btnLang.IsEnabled      = $en
    }

    function Run-Action($action, $target) {
        Set-State $false
        $pb.Value = 0
        $pb.IsIndeterminate = $true
        $lblStatus.Text = $global:i18n[$global:CurrentLang].Working
        $lblStatus.Foreground = Get-Brush "#949BA4"

        $ctxDir = $null
        if ($PSScriptRoot) { $ctxDir = $PSScriptRoot } elseif ($MyInvocation.MyCommand.Path) { $ctxDir = Split-Path -Parent $MyInvocation.MyCommand.Path }

        $sync = [hashtable]::Synchronized(@{
            Dispatcher  = $window.Dispatcher
            Status      = $lblStatus
            Progress    = $pb
            Lang        = $global:CurrentLang
            i18n        = $global:i18n
            Paths       = (Get-DiscordPaths)
            Action      = $action
            Target      = $target
            LocalDir    = $ctxDir
            RepoUrl     = "https://github.com/phwyverysad/discord-fake-mute-deafen/archive/refs/heads/main.zip"
            CliUrl      = "https://github.com/Vencord/Installer/releases/latest/download/VencordInstallerCli.exe"
            Done        = $false
            Error       = $null
        })

        $worker = {
            param($sync)

            try {
                [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.SecurityProtocolType]3072 -bor [System.Net.SecurityProtocolType]768 -bor [System.Net.SecurityProtocolType]192

                $vDir = "$env:APPDATA\Vencord"
                $tDist = "$vDir\dist"
                $sFile = "$vDir\settings\settings.json"

                $procs = Get-Process | Where-Object { $_.ProcessName -like "*Discord*" -and $_.ProcessName -notlike "*Helper*" }
                if ($procs) {
                    foreach ($p in $procs) { Stop-Process -Id $p.Id -Force -ErrorAction SilentlyContinue }
                    Start-Sleep -Seconds 2
                }

                if ($sync.Action -eq "Uninstall") {
                    $cli = Join-Path $env:TEMP "VencordInstallerCli.exe"
                    if ($sync.LocalDir -and (Test-Path (Join-Path $sync.LocalDir "VencordInstallerCli.exe"))) {
                        $cli = Join-Path $sync.LocalDir "VencordInstallerCli.exe"
                    } elseif (-not (Test-Path $cli)) {
                        (New-Object System.Net.WebClient).DownloadFile($sync.CliUrl, $cli)
                    }

                    $all = @($sync.Paths["Discord"] + $sync.Paths["DiscordPTB"] + $sync.Paths["DiscordCanary"] | Select-Object -Unique)
                    $u = 0
                    foreach ($l in $all) {
                        if (Test-Path $l) { & $cli -uninstall -location $l | Out-Null; $u++ }
                    }
                    if ($u -eq 0) { & $cli -uninstall -branch auto | Out-Null }

                    if (Test-Path $sFile) {
                        try {
                            $c = Get-Content $sFile -Raw | ConvertFrom-Json -AsHashtable
                            if ($c.ContainsKey("plugins") -and $c["plugins"].ContainsKey("FakeMuteDeafen")) {
                                $c["plugins"]["FakeMuteDeafen"]["enabled"] = $false
                                $utf8 = New-Object System.Text.UTF8Encoding($false)
                                [System.IO.File]::WriteAllText($sFile, ($c | ConvertTo-Json -Depth 10), $utf8)
                            }
                        } catch {}
                    }

                    foreach ($p in $all) {
                        $exe = Get-ChildItem $p -Filter "Discord*.exe" -Recurse -ErrorAction SilentlyContinue | Where-Object { $_.Name -notlike "*Update*" -and $_.Name -notlike "*Helper*" } | Select-Object -First 1
                        if ($exe) { Start-Process $exe.FullName; break }
                    }

                    $sync.Done = $true
                    return
                }

                $tmp = Join-Path $env:TEMP ("FMD_" + (Get-Random))
                $src = $null
                $cli = $null

                if ($sync.LocalDir) {
                    $lDist = Join-Path $sync.LocalDir "dist"
                    $lCli  = Join-Path $sync.LocalDir "VencordInstallerCli.exe"
                    if ((Test-Path $lDist) -and (Test-Path $lCli)) {
                        $src = $lDist
                        $cli = $lCli
                    }
                }

                if (-not $src) {
                    New-Item -ItemType Directory -Path $tmp -Force | Out-Null
                    $zip = Join-Path $tmp "p.zip"
                    (New-Object System.Net.WebClient).DownloadFile($sync.RepoUrl, $zip)

                    if (Get-Command Expand-Archive -ErrorAction SilentlyContinue) {
                        Expand-Archive -Path $zip -DestinationPath $tmp -Force
                    } else {
                        Add-Type -AssemblyName System.IO.Compression.FileSystem
                        [System.IO.Compression.ZipFile]::ExtractToDirectory($zip, $tmp)
                    }

                    $ext = Get-ChildItem -Path $tmp -Directory | Where-Object { $_.Name -like "*fake-mute-deafen*" } | Select-Object -First 1
                    if (-not $ext) { $ext = Get-Item $tmp }
                    $src = Join-Path $ext.FullName "dist"
                    $cli = Join-Path $ext.FullName "VencordInstallerCli.exe"

                    if (-not (Test-Path $cli)) {
                        (New-Object System.Net.WebClient).DownloadFile($sync.CliUrl, $cli)
                    }
                }

                $targets = @()
                if ($sync.Target -eq "All") {
                    $targets = @($sync.Paths["Discord"] + $sync.Paths["DiscordPTB"] + $sync.Paths["DiscordCanary"] | Select-Object -Unique)
                } else {
                    $targets = @($sync.Paths[$sync.Target] | Select-Object -Unique)
                }

                $cnt = 0
                foreach ($l in $targets) {
                    if (Test-Path $l) { & $cli -install -location $l | Out-Null; $cnt++ }
                }
                if ($cnt -eq 0) {
                    $b = switch ($sync.Target) { "DiscordPTB" { "ptb" } "DiscordCanary" { "canary" } default { "stable" } }
                    & $cli -install -branch $b | Out-Null
                }

                if (-not (Test-Path $tDist)) { New-Item -ItemType Directory -Path $tDist -Force | Out-Null }
                Copy-Item -Path "$src\*" -Destination "$tDist\" -Recurse -Force

                $theme = "$vDir\themes\midnight.theme.css"
                if (Test-Path $theme) { Remove-Item -Path $theme -Force -ErrorAction SilentlyContinue }

                $sDir = "$vDir\settings"
                if (-not (Test-Path $sDir)) { New-Item -ItemType Directory -Path $sDir -Force | Out-Null }
                $c = @{}
                if (Test-Path $sFile) {
                    try { $c = Get-Content $sFile -Raw | ConvertFrom-Json -AsHashtable } catch { $c = @{} }
                }
                $c["autoUpdate"] = $false
                $c["autoUpdateNotification"] = $false
                if ($c.ContainsKey("enabledThemes") -and $c["enabledThemes"]) {
                    $c["enabledThemes"] = @($c["enabledThemes"] | Where-Object { $_ -ne "midnight.theme.css" })
                }
                if (-not $c.ContainsKey("plugins")) { $c["plugins"] = @{} }
                if (-not $c["plugins"].ContainsKey("FakeMuteDeafen")) { $c["plugins"]["FakeMuteDeafen"] = @{} }
                $c["plugins"]["FakeMuteDeafen"]["enabled"] = $true

                $utf8 = New-Object System.Text.UTF8Encoding($false)
                [System.IO.File]::WriteAllText($sFile, ($c | ConvertTo-Json -Depth 10), $utf8)

                if ($tmp -and (Test-Path $tmp)) { Remove-Item -Path $tmp -Recurse -Force -ErrorAction SilentlyContinue }

                foreach ($p in $targets) {
                    $exe = Get-ChildItem $p -Filter "Discord*.exe" -Recurse -ErrorAction SilentlyContinue | Where-Object { $_.Name -notlike "*Update*" -and $_.Name -notlike "*Helper*" } | Select-Object -First 1
                    if ($exe) { Start-Process $exe.FullName; break }
                }

                $sync.Done = $true
            } catch {
                $sync.Error = $_.Exception.Message
                $sync.Done = $true
            }
        }

        $rs = [RunspaceFactory]::CreateRunspace()
        $rs.ApartmentState = [System.Threading.ApartmentState]::STA
        $rs.Open()

        $ps = [PowerShell]::Create()
        $ps.Runspace = $rs
        $null = $ps.AddScript($worker).AddArgument($sync)
        $h = $ps.BeginInvoke()

        $t = New-Object System.Windows.Threading.DispatcherTimer
        $t.Interval = [TimeSpan]::FromMilliseconds(150)
        $t.Add_Tick({
            if ($h.IsCompleted -or $sync.Done) {
                $t.Stop()
                $pb.IsIndeterminate = $false
                $pb.Value = 100

                $d = $global:i18n[$global:CurrentLang]
                if ($sync.Error) {
                    $lblStatus.Text = [string]::Format($d.Error, $sync.Error)
                    $lblStatus.Foreground = Get-Brush "#F23F43"
                } else {
                    $lblStatus.Text = $d.Done
                    $lblStatus.Foreground = Get-Brush "#23A55A"
                }

                Set-State $true
                try {
                    $ps.EndInvoke($h)
                    $ps.Dispose()
                    $rs.Close()
                    $rs.Dispose()
                } catch {}
            }
        })
        $t.Start()
    }

    $btnStable.Add_Click({ Run-Action "Install" "Discord" })
    $btnPTB.Add_Click({ Run-Action "Install" "DiscordPTB" })
    $btnCanary.Add_Click({ Run-Action "Install" "DiscordCanary" })
    $btnAll.Add_Click({ Run-Action "Install" "All" })
    $btnUninstall.Add_Click({ Run-Action "Uninstall" "All" })

    Update-Language
    $window.ShowDialog() | Out-Null
}

if ([System.Threading.Thread]::CurrentThread.GetApartmentState() -ne [System.Threading.ApartmentState]::STA) {
    $t = New-Object System.Threading.Thread([System.Threading.ThreadStart]{ Start-WpfInstallerApp })
    $t.SetApartmentState([System.Threading.ApartmentState]::STA)
    $t.Start()
    $t.Join()
} else {
    Start-WpfInstallerApp
}
