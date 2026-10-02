try {
    [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.SecurityProtocolType]3072 -bor [System.Net.SecurityProtocolType]768 -bor [System.Net.SecurityProtocolType]192
} catch {}

try {
    [Console]::OutputEncoding = [System.Text.Encoding]::UTF8
    $OutputEncoding = [System.Text.Encoding]::UTF8
} catch {}

try {
    if (-not ([System.Management.Automation.PSTypeName]'WinUtil.WinUtil').Type) {
        Add-Type -Name WinUtil -Namespace WinUtil -MemberDefinition @"
[System.Runtime.InteropServices.DllImport("user32.dll")]
public static extern bool ShowWindow(System.IntPtr hWnd, int nCmdShow);
[System.Runtime.InteropServices.DllImport("kernel32.dll")]
public static extern System.IntPtr GetConsoleWindow();
"@ -ErrorAction SilentlyContinue
    }
    $ch = [WinUtil.WinUtil]::GetConsoleWindow()
    if ($ch -and $ch -ne [System.IntPtr]::Zero) {
        [WinUtil.WinUtil]::ShowWindow($ch, 0)
    }
    $cp = [System.Diagnostics.Process]::GetCurrentProcess()
    if ($cp -and $cp.MainWindowHandle -ne [System.IntPtr]::Zero) {
        [WinUtil.WinUtil]::ShowWindow($cp.MainWindowHandle, 0)
    }
} catch {}

Add-Type -AssemblyName PresentationFramework, PresentationCore, WindowsBase

function Start-WpfInstallerApp {
    function T($b) {
        return [System.Text.Encoding]::UTF8.GetString([System.Convert]::FromBase64String($b))
    }

    $global:CurrentLang = "EN"
    $global:CurrentTheme = "Dark"

    $global:i18n = @{
        EN = @{
            Title         = "FakeMuteDeafen"
            SelectTargets = "Discord Versions"
            Discord       = "Discord"
            DiscordPTB    = "Discord PTB"
            DiscordCanary = "Discord Canary"
            BtnInstall    = "Install"
            BtnUninstall  = "Uninstall"
            Ready         = "Ready"
            Working       = "Working..."
            Done          = "Done"
            Error         = "Error: {0}"
            SelectOne     = "Please select at least 1 version."
            LogHeader     = "Log"
            ThemeDark     = "Dark"
            ThemeLight    = "Light"
            LangBtn       = "TH"
        }
        TH = @{
            Title         = "FakeMuteDeafen"
            SelectTargets = (T "4LmA4Lil4Li34Lit4LiB4LmA4Lin4Lit4Lij4LmM4LiK4Lix4LiZIERpc2NvcmQ=")
            Discord       = "Discord"
            DiscordPTB    = "Discord PTB"
            DiscordCanary = "Discord Canary"
            BtnInstall    = (T "4LiV4Li04LiU4LiV4Lix4LmJ4LiH")
            BtnUninstall  = (T "4LiW4Lit4LiZ4LiB4Liy4Lij4LiV4Li04LiU4LiV4Lix4LmJ4LiH")
            Ready         = (T "4Lie4Lij4LmJ4Lit4Lih4LmD4LiK4LmJ4LiH4Liy4LiZ")
            Working       = (T "4LiB4Liz4Lil4Lix4LiH4LiU4Liz4LmA4LiZ4Li04LiZ4LiB4Liy4LijLi4u")
            Done          = (T "4LmA4Liq4Lij4LmH4LiI4Liq4Lih4Lia4Li54Lij4LiT4LmM")
            Error         = (T "4LiC4LmJ4Lit4Lic4Li04LiU4Lie4Lil4Liy4LiUOiB7MH0=")
            SelectOne     = (T "4LiB4Lij4Li44LiT4Liy4LmA4Lil4Li34Lit4LiB4Lit4Lii4LmI4Liy4LiH4LiZ4LmJ4Lit4LiiIDEg4LmA4Lin4Lit4Lij4LmM4LiK4Lix4LiZ")
            LogHeader     = (T "4Lia4Lix4LiZ4LiX4Li24LiB4LiB4Liy4Lij4LiX4Liz4LiH4Liy4LiZ")
            ThemeDark     = (T "4Lih4Li34LiU")
            ThemeLight    = (T "4Liq4Lin4LmI4Liy4LiH")
            LangBtn       = "EN"
        }
    }

    $global:Themes = @{
        Dark = @{
            WindowBg     = "#1E1F22"
            WindowBorder = "#313338"
            TitleBg      = "#18191C"
            TitleFg      = "#F2F3F5"
            TextPrimary  = "#F2F3F5"
            TextMuted    = "#949BA4"
            CardBg       = "#2B2D31"
            CardBorder   = "#383A40"
            LogBg        = "#111214"
            LogFg        = "#DBDEE1"
            LogBorder    = "#383A40"
            BtnWinFg     = "#949BA4"
            PbTrack      = "#2B2D31"
        }
        Light = @{
            WindowBg     = "#FFFFFF"
            WindowBorder = "#D1D4D7"
            TitleBg      = "#F2F3F5"
            TitleFg      = "#2E3338"
            TextPrimary  = "#2E3338"
            TextMuted    = "#5C6067"
            CardBg       = "#F2F3F5"
            CardBorder   = "#D1D4D7"
            LogBg        = "#F8F9FA"
            LogFg        = "#2E3338"
            LogBorder    = "#D1D4D7"
            BtnWinFg     = "#5C6067"
            PbTrack      = "#E3E5E8"
        }
    }

    [xml]$xaml = @"
<Window xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
        xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml"
        Title="FakeMuteDeafen"
        Height="500" Width="440"
        WindowStartupLocation="CenterScreen"
        WindowStyle="None"
        AllowsTransparency="True"
        Background="Transparent"
        FontFamily="Segoe UI, Leelawadee UI, Tahoma, sans-serif"
        ResizeMode="NoResize">

    <Window.Resources>
        <Style x:Key="BtnBase" TargetType="Button">
            <Setter Property="FontSize" Value="13"/>
            <Setter Property="FontWeight" Value="SemiBold"/>
            <Setter Property="Height" Value="36"/>
            <Setter Property="Cursor" Value="Hand"/>
            <Setter Property="BorderThickness" Value="1"/>
            <Setter Property="Foreground" Value="#FFFFFF"/>
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
                                <Setter TargetName="bd" Property="Opacity" Value="0.85"/>
                            </Trigger>
                            <Trigger Property="IsPressed" Value="True">
                                <Setter TargetName="bd" Property="Opacity" Value="0.7"/>
                            </Trigger>
                            <Trigger Property="IsEnabled" Value="False">
                                <Setter TargetName="bd" Property="Opacity" Value="0.4"/>
                            </Trigger>
                        </ControlTemplate.Triggers>
                    </ControlTemplate>
                </Setter.Value>
            </Setter>
        </Style>

        <Style x:Key="BtnPrimary" TargetType="Button" BasedOn="{StaticResource BtnBase}">
            <Setter Property="Background" Value="#5865F2"/>
            <Setter Property="BorderBrush" Value="#4752C4"/>
        </Style>

        <Style x:Key="BtnDanger" TargetType="Button" BasedOn="{StaticResource BtnBase}">
            <Setter Property="Background" Value="#DA373C"/>
            <Setter Property="BorderBrush" Value="#BA2F33"/>
        </Style>

        <Style x:Key="BtnWin" TargetType="Button">
            <Setter Property="Background" Value="Transparent"/>
            <Setter Property="Foreground" Value="#949BA4"/>
            <Setter Property="Padding" Value="6,0"/>
            <Setter Property="Height" Value="24"/>
            <Setter Property="Cursor" Value="Hand"/>
            <Setter Property="FontSize" Value="11"/>
            <Setter Property="Template">
                <Setter.Value>
                    <ControlTemplate TargetType="Button">
                        <Border x:Name="bd" Background="{TemplateBinding Background}" CornerRadius="4" Padding="{TemplateBinding Padding}">
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

        <Style x:Key="ChkBase" TargetType="CheckBox">
            <Setter Property="FontSize" Value="13"/>
            <Setter Property="Cursor" Value="Hand"/>
            <Setter Property="VerticalAlignment" Value="Center"/>
            <Setter Property="Margin" Value="0,0,12,0"/>
        </Style>
    </Window.Resources>

    <Border Name="MainBorder" Background="#1E1F22" BorderBrush="#313338" BorderThickness="1" CornerRadius="10">
        <Grid>
            <Grid.RowDefinitions>
                <RowDefinition Height="38"/>
                <RowDefinition Height="*"/>
            </Grid.RowDefinitions>

            <Border Grid.Row="0" Name="TitleBar" Background="#18191C" CornerRadius="10,10,0,0">
                <Grid Margin="12,0,8,0">
                    <Grid.ColumnDefinitions>
                        <ColumnDefinition Width="*"/>
                        <ColumnDefinition Width="Auto"/>
                    </Grid.ColumnDefinitions>

                    <TextBlock Name="txtTitle" Text="FakeMuteDeafen" Foreground="#F2F3F5" FontSize="13" FontWeight="SemiBold" VerticalAlignment="Center"/>

                    <StackPanel Grid.Column="1" Orientation="Horizontal" VerticalAlignment="Center">
                        <Button Name="btnTheme" Style="{StaticResource BtnWin}" Content="Light" Margin="0,0,4,0"/>
                        <Button Name="btnLang" Style="{StaticResource BtnWin}" Content="TH" Margin="0,0,4,0"/>
                        <Button Name="btnMin" Style="{StaticResource BtnWin}" Content="-" Margin="0,0,2,0" Width="26"/>
                        <Button Name="btnClose" Style="{StaticResource BtnWin}" Content="X" Width="26"/>
                    </StackPanel>
                </Grid>
            </Border>

            <StackPanel Grid.Row="1" Margin="18,14,18,14">
                <TextBlock Name="lblSelectTargets" Text="Discord Versions" Foreground="#949BA4" FontSize="12" FontWeight="SemiBold" Margin="0,0,0,6"/>

                <Border Name="CardTargets" Background="#2B2D31" BorderBrush="#383A40" BorderThickness="1" CornerRadius="6" Padding="12,10" Margin="0,0,0,12">
                    <UniformGrid Columns="3">
                        <CheckBox Name="chkStable" Style="{StaticResource ChkBase}" Content="Discord"/>
                        <CheckBox Name="chkPTB" Style="{StaticResource ChkBase}" Content="Discord PTB"/>
                        <CheckBox Name="chkCanary" Style="{StaticResource ChkBase}" Content="Discord Canary"/>
                    </UniformGrid>
                </Border>

                <Grid Margin="0,0,0,12">
                    <Grid.ColumnDefinitions>
                        <ColumnDefinition Width="*"/>
                        <ColumnDefinition Width="*"/>
                    </Grid.ColumnDefinitions>
                    <Button Name="btnInstall" Grid.Column="0" Style="{StaticResource BtnPrimary}" Content="Install" Margin="0,0,6,0"/>
                    <Button Name="btnUninstall" Grid.Column="1" Style="{StaticResource BtnDanger}" Content="Uninstall" Margin="6,0,0,0"/>
                </Grid>

                <TextBlock Name="lblStatus" Text="Ready" Foreground="#949BA4" FontSize="12" Margin="0,0,0,4"/>
                <ProgressBar Name="pb" Height="4" Background="#2B2D31" Foreground="#5865F2" BorderThickness="0" Value="0" Maximum="100" Margin="0,0,0,10"/>

                <TextBlock Name="lblLog" Text="Log" Foreground="#949BA4" FontSize="12" FontWeight="SemiBold" Margin="0,0,0,4"/>
                <Border Name="BorderLog" Background="#111214" BorderBrush="#383A40" BorderThickness="1" CornerRadius="6">
                    <TextBox Name="txtLog" Height="190" IsReadOnly="True" Background="Transparent" Foreground="#DBDEE1" BorderThickness="0" FontFamily="Consolas, monospace" FontSize="11" Padding="8,6" VerticalScrollBarVisibility="Auto" HorizontalScrollBarVisibility="Disabled" TextWrapping="Wrap"/>
                </Border>
            </StackPanel>
        </Grid>
    </Border>
</Window>
"@

    $reader = New-Object System.Xml.XmlNodeReader $xaml
    $window = [System.Windows.Markup.XamlReader]::Load($reader)

    $MainBorder       = $window.FindName("MainBorder")
    $TitleBar         = $window.FindName("TitleBar")
    $txtTitle         = $window.FindName("txtTitle")
    $btnTheme         = $window.FindName("btnTheme")
    $btnLang          = $window.FindName("btnLang")
    $btnMin           = $window.FindName("btnMin")
    $btnClose         = $window.FindName("btnClose")

    $lblSelectTargets = $window.FindName("lblSelectTargets")
    $CardTargets      = $window.FindName("CardTargets")
    $chkStable        = $window.FindName("chkStable")
    $chkPTB           = $window.FindName("chkPTB")
    $chkCanary        = $window.FindName("chkCanary")

    $btnInstall       = $window.FindName("btnInstall")
    $btnUninstall     = $window.FindName("btnUninstall")

    $lblStatus        = $window.FindName("lblStatus")
    $pb               = $window.FindName("pb")

    $lblLog           = $window.FindName("lblLog")
    $BorderLog        = $window.FindName("BorderLog")
    $txtLog           = $window.FindName("txtLog")

    $TitleBar.Add_MouseLeftButtonDown({ $window.DragMove() })
    $btnMin.Add_Click({ $window.WindowState = 'Minimized' })
    $btnClose.Add_Click({ $window.Close() })
    $window.Add_Closed({
        if ($Host.Name -notlike "*ISE*" -and $Host.Name -notlike "*Visual Studio*") {
            [System.Environment]::Exit(0)
        }
    })

    $global:BrushConverter = New-Object System.Windows.Media.BrushConverter
    function Get-Brush($hex) {
        return $global:BrushConverter.ConvertFromString($hex)
    }

    function Update-Theme {
        $thm = $global:Themes[$global:CurrentTheme]
        $MainBorder.Background       = Get-Brush $thm.WindowBg
        $MainBorder.BorderBrush      = Get-Brush $thm.WindowBorder
        $TitleBar.Background         = Get-Brush $thm.TitleBg
        $txtTitle.Foreground         = Get-Brush $thm.TitleFg
        $btnTheme.Foreground         = Get-Brush $thm.BtnWinFg
        $btnLang.Foreground          = Get-Brush $thm.BtnWinFg
        $btnMin.Foreground           = Get-Brush $thm.BtnWinFg
        $btnClose.Foreground          = Get-Brush $thm.BtnWinFg
        $lblSelectTargets.Foreground = Get-Brush $thm.TextMuted
        $CardTargets.Background      = Get-Brush $thm.CardBg
        $CardTargets.BorderBrush     = Get-Brush $thm.CardBorder
        $chkStable.Foreground        = Get-Brush $thm.TextPrimary
        $chkPTB.Foreground           = Get-Brush $thm.TextPrimary
        $chkCanary.Foreground        = Get-Brush $thm.TextPrimary
        $BorderLog.Background        = Get-Brush $thm.LogBg
        $BorderLog.BorderBrush       = Get-Brush $thm.LogBorder
        $txtLog.Foreground           = Get-Brush $thm.LogFg
        $lblLog.Foreground           = Get-Brush $thm.TextMuted
        $pb.Background               = Get-Brush $thm.PbTrack

        Update-ThemeBtnText
    }

    function Update-ThemeBtnText {
        $d = $global:i18n[$global:CurrentLang]
        if ($global:CurrentTheme -eq "Dark") {
            $btnTheme.Content = $d.ThemeLight
        } else {
            $btnTheme.Content = $d.ThemeDark
        }
    }

    function Update-Language {
        $d = $global:i18n[$global:CurrentLang]
        $txtTitle.Text            = $d.Title
        $btnLang.Content          = $d.LangBtn
        $lblSelectTargets.Text    = $d.SelectTargets
        $chkStable.Content        = $d.Discord
        $chkPTB.Content           = $d.DiscordPTB
        $chkCanary.Content        = $d.DiscordCanary
        $btnInstall.Content       = $d.BtnInstall
        $btnUninstall.Content     = $d.BtnUninstall
        $lblStatus.Text           = $d.Ready
        $lblLog.Text              = $d.LogHeader
        Update-ThemeBtnText
    }

    $btnTheme.Add_Click({
        if ($global:CurrentTheme -eq "Dark") { $global:CurrentTheme = "Light" } else { $global:CurrentTheme = "Dark" }
        Update-Theme
    })

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

    $detected = Get-DiscordPaths
    if ($detected["Discord"].Count -gt 0) { $chkStable.IsChecked = $true }
    if ($detected["DiscordPTB"].Count -gt 0) { $chkPTB.IsChecked = $true }
    if ($detected["DiscordCanary"].Count -gt 0) { $chkCanary.IsChecked = $true }
    if (-not $chkStable.IsChecked -and -not $chkPTB.IsChecked -and -not $chkCanary.IsChecked) {
        $chkStable.IsChecked = $true
    }

    function Set-State($en) {
        $btnInstall.IsEnabled   = $en
        $btnUninstall.IsEnabled = $en
        $chkStable.IsEnabled    = $en
        $chkPTB.IsEnabled       = $en
        $chkCanary.IsEnabled    = $en
        $btnTheme.IsEnabled     = $en
        $btnLang.IsEnabled      = $en
    }

    function Run-Action($action) {
        $selected = @()
        if ($chkStable.IsChecked) { $selected += "Discord" }
        if ($chkPTB.IsChecked) { $selected += "DiscordPTB" }
        if ($chkCanary.IsChecked) { $selected += "DiscordCanary" }

        if ($selected.Count -eq 0) {
            $lblStatus.Text = $global:i18n[$global:CurrentLang].SelectOne
            $lblStatus.Foreground = Get-Brush "#F23F43"
            return
        }

        Set-State $false
        $pb.Value = 0
        $pb.IsIndeterminate = $true
        $lblStatus.Text = $global:i18n[$global:CurrentLang].Working
        $lblStatus.Foreground = Get-Brush $global:Themes[$global:CurrentTheme].TextMuted

        $txtLog.AppendText("[$([DateTime]::Now.ToString('HH:mm:ss'))] Starting $action...`r`n")
        $txtLog.ScrollToEnd()

        $ctxDir = $null
        if ($PSScriptRoot) { $ctxDir = $PSScriptRoot } elseif ($MyInvocation.MyCommand.Path) { $ctxDir = Split-Path -Parent $MyInvocation.MyCommand.Path }

        $sync = [hashtable]::Synchronized(@{
            Action   = $action
            Targets  = $selected
            Paths    = (Get-DiscordPaths)
            LocalDir = $ctxDir
            RepoUrl  = "https://github.com/phwyverysad/discord-fake-mute-deafen/archive/refs/heads/main.zip"
            CliUrl   = "https://github.com/Vencord/Installer/releases/latest/download/VencordInstallerCli.exe"
            Logs     = [System.Collections.ArrayList]::Synchronized((New-Object System.Collections.ArrayList))
            Done     = $false
            Error    = $null
        })

        $worker = {
            param($sync)

            function Add-Log($msg) {
                $ts = [DateTime]::Now.ToString("HH:mm:ss")
                $sync.Logs.Add("[$ts] $msg")
            }

            try {
                [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.SecurityProtocolType]3072 -bor [System.Net.SecurityProtocolType]768 -bor [System.Net.SecurityProtocolType]192

                $vDir = "$env:APPDATA\Vencord"
                $tDist = "$vDir\dist"
                $sFile = "$vDir\settings\settings.json"

                Add-Log "Targets: $(($sync.Targets) -join ', ')"

                $procs = Get-Process | Where-Object { $_.ProcessName -like "*Discord*" -and $_.ProcessName -notlike "*Helper*" }
                if ($procs) {
                    Add-Log "Stopping Discord processes..."
                    foreach ($p in $procs) {
                        Stop-Process -Id $p.Id -Force -ErrorAction SilentlyContinue
                    }
                    Start-Sleep -Seconds 1
                }

                $src = $null
                $cli = $null
                $tmp = $null

                if ($sync.LocalDir) {
                    $lDist = Join-Path $sync.LocalDir "dist"
                    $lCli  = Join-Path $sync.LocalDir "VencordInstallerCli.exe"
                    if ((Test-Path $lDist) -and (Test-Path (Join-Path $lDist "patcher.js"))) {
                        $src = $lDist
                    }
                    if (Test-Path $lCli) {
                        $cli = $lCli
                    }
                }

                if ($sync.Action -eq "Uninstall") {
                    if (-not $cli) {
                        $tempCli = Join-Path $env:TEMP "VencordInstallerCli.exe"
                        if (Test-Path $tempCli) {
                            $cli = $tempCli
                        } else {
                            Add-Log "Downloading installer CLI..."
                            $wc = New-Object System.Net.WebClient
                            $wc.Headers.Add("User-Agent", "PowerShell")
                            $wc.DownloadFile($sync.CliUrl, $tempCli)
                            $cli = $tempCli
                        }
                    }

                    foreach ($target in $sync.Targets) {
                        $paths = $sync.Paths[$target]
                        $branch = switch ($target) { "DiscordPTB" { "ptb" } "DiscordCanary" { "canary" } default { "stable" } }

                        if ($paths -and $paths.Count -gt 0) {
                            foreach ($loc in $paths) {
                                if (Test-Path $loc) {
                                    Add-Log "Uninstalling $target at $loc..."
                                    $apps = Get-ChildItem $loc -Directory -Filter "app-*" -ErrorAction SilentlyContinue
                                    $needsUnpatch = $false
                                    foreach ($a in $apps) {
                                        $resDir = Join-Path $a.FullName "resources"
                                        if (Test-Path (Join-Path $resDir "_app.asar")) {
                                            $needsUnpatch = $true
                                            break
                                        }
                                    }

                                    if ($needsUnpatch) {
                                        $pinfo = New-Object System.Diagnostics.ProcessStartInfo
                                        $pinfo.FileName = $cli
                                        $pinfo.Arguments = "-uninstall -location `"$loc`""
                                        $pinfo.RedirectStandardOutput = $true
                                        $pinfo.RedirectStandardError = $true
                                        $pinfo.UseShellExecute = $false
                                        $pinfo.CreateNoWindow = $true
                                        $pr = [System.Diagnostics.Process]::Start($pinfo)
                                        while (-not $pr.HasExited) {
                                            $line = $pr.StandardOutput.ReadLine()
                                            if ($line) { Add-Log $line }
                                        }
                                        $rest = $pr.StandardOutput.ReadToEnd()
                                        if ($rest) { foreach ($l in ($rest -split "`r?`n")) { if ($l.Trim()) { Add-Log $l } } }
                                        $pr.WaitForExit()
                                    } else {
                                        Add-Log "$target is already clean."
                                    }

                                    foreach ($a in $apps) {
                                        $resDir = Join-Path $a.FullName "resources"
                                        $orig = Join-Path $resDir "_app.asar"
                                        $stub = Join-Path $resDir "app.asar"
                                        if (Test-Path $orig) {
                                            if (Test-Path $stub) { Remove-Item $stub -Force -ErrorAction SilentlyContinue }
                                            Rename-Item -Path $orig -NewName "app.asar" -Force -ErrorAction SilentlyContinue
                                        }
                                    }
                                }
                            }
                        } else {
                            Add-Log "Uninstalling $target via branch $branch..."
                            & $cli -uninstall -branch $branch | Out-Null
                        }
                    }

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

                    Add-Log "Relaunching Discord..."
                    foreach ($target in $sync.Targets) {
                        $paths = $sync.Paths[$target]
                        foreach ($loc in $paths) {
                            $upd = Join-Path $loc "Update.exe"
                            $exeName = switch ($target) { "DiscordPTB" { "DiscordPTB.exe" } "DiscordCanary" { "DiscordCanary.exe" } default { "Discord.exe" } }
                            if (Test-Path $upd) {
                                Start-Process $upd -ArgumentList "--processStart", $exeName
                            } else {
                                $exe = Get-ChildItem $loc -Filter $exeName -Recurse -ErrorAction SilentlyContinue | Select-Object -First 1
                                if ($exe) { Start-Process $exe.FullName }
                            }
                        }
                    }

                    Add-Log "Uninstall completed."
                    $sync.Done = $true
                    return
                }

                if (-not $src -or -not $cli) {
                    Add-Log "Downloading package repository..."
                    $tmp = Join-Path $env:TEMP ("FMD_" + (Get-Random))
                    New-Item -ItemType Directory -Path $tmp -Force | Out-Null
                    $zip = Join-Path $tmp "package.zip"
                    $wc = New-Object System.Net.WebClient
                    $wc.Headers.Add("User-Agent", "PowerShell")
                    $wc.DownloadFile($sync.RepoUrl, $zip)

                    if (Get-Command Expand-Archive -ErrorAction SilentlyContinue) {
                        Expand-Archive -Path $zip -DestinationPath $tmp -Force
                    } else {
                        Add-Type -AssemblyName System.IO.Compression.FileSystem
                        [System.IO.Compression.ZipFile]::ExtractToDirectory($zip, $tmp)
                    }

                    $ext = Get-ChildItem -Path $tmp -Directory | Where-Object { $_.Name -like "*fake-mute-deafen*" } | Select-Object -First 1
                    if (-not $ext) { $ext = Get-Item $tmp }
                    if (-not $src) { $src = Join-Path $ext.FullName "dist" }
                    if (-not $cli) { $cli = Join-Path $ext.FullName "VencordInstallerCli.exe" }
                }

                if (-not (Test-Path $cli)) {
                    $tempCli = Join-Path $env:TEMP "VencordInstallerCli.exe"
                    if (-not (Test-Path $tempCli)) {
                        Add-Log "Downloading installer CLI..."
                        $wc = New-Object System.Net.WebClient
                        $wc.Headers.Add("User-Agent", "PowerShell")
                        $wc.DownloadFile($sync.CliUrl, $tempCli)
                    }
                    $cli = $tempCli
                }

                foreach ($target in $sync.Targets) {
                    $paths = $sync.Paths[$target]
                    $branch = switch ($target) { "DiscordPTB" { "ptb" } "DiscordCanary" { "canary" } default { "stable" } }

                    if ($paths -and $paths.Count -gt 0) {
                        foreach ($loc in $paths) {
                            if (Test-Path $loc) {
                                Add-Log "Checking $target integrity at $loc..."
                                $apps = Get-ChildItem $loc -Directory -Filter "app-*" -ErrorAction SilentlyContinue | Sort-Object Name -Descending
                                if ($apps) {
                                    $latest = $apps[0]
                                    $latRes = Join-Path $latest.FullName "resources"
                                    if (-not (Test-Path $latRes)) { New-Item -ItemType Directory -Path $latRes -Force | Out-Null }
                                    $hasAsar = (Test-Path (Join-Path $latRes "app.asar")) -or (Test-Path (Join-Path $latRes "_app.asar"))
                                    if (-not $hasAsar) {
                                        for ($i = 1; $i -lt $apps.Count; $i++) {
                                            $prevRes = Join-Path $apps[$i].FullName "resources"
                                            $prevAsar = (Test-Path (Join-Path $prevRes "app.asar")) -or (Test-Path (Join-Path $prevRes "_app.asar"))
                                            if ($prevAsar) {
                                                Copy-Item (Join-Path $prevRes "*") $latRes -Recurse -Force -ErrorAction SilentlyContinue
                                                break
                                            }
                                        }
                                    }
                                }

                                Add-Log "Patching $target at $loc..."
                                $pinfo = New-Object System.Diagnostics.ProcessStartInfo
                                $pinfo.FileName = $cli
                                $pinfo.Arguments = "-install -location `"$loc`""
                                $pinfo.RedirectStandardOutput = $true
                                $pinfo.RedirectStandardError = $true
                                $pinfo.UseShellExecute = $false
                                $pinfo.CreateNoWindow = $true
                                $pr = [System.Diagnostics.Process]::Start($pinfo)
                                while (-not $pr.HasExited) {
                                    $line = $pr.StandardOutput.ReadLine()
                                    if ($line) { Add-Log $line }
                                }
                                $rest = $pr.StandardOutput.ReadToEnd()
                                if ($rest) { foreach ($l in ($rest -split "`r?`n")) { if ($l.Trim()) { Add-Log $l } } }
                                $pr.WaitForExit()
                            }
                        }
                    } else {
                        Add-Log "Patching $target via branch $branch..."
                        & $cli -install -branch $branch | Out-Null
                    }
                }

                Add-Log "Copying FakeMuteDeafen files..."
                if (-not (Test-Path $tDist)) { New-Item -ItemType Directory -Path $tDist -Force | Out-Null }
                Copy-Item -Path "$src\*" -Destination "$tDist\" -Recurse -Force

                $theme = "$vDir\themes\midnight.theme.css"
                if (Test-Path $theme) { Remove-Item -Path $theme -Force -ErrorAction SilentlyContinue }

                Add-Log "Updating configuration..."
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

                if ($tmp -and (Test-Path $tmp)) {
                    Remove-Item -Path $tmp -Recurse -Force -ErrorAction SilentlyContinue
                }

                Add-Log "Relaunching Discord..."
                foreach ($target in $sync.Targets) {
                    $paths = $sync.Paths[$target]
                    foreach ($loc in $paths) {
                        $upd = Join-Path $loc "Update.exe"
                        $exeName = switch ($target) { "DiscordPTB" { "DiscordPTB.exe" } "DiscordCanary" { "DiscordCanary.exe" } default { "Discord.exe" } }
                        if (Test-Path $upd) {
                            Start-Process $upd -ArgumentList "--processStart", $exeName
                        } else {
                            $exe = Get-ChildItem $loc -Filter $exeName -Recurse -ErrorAction SilentlyContinue | Select-Object -First 1
                            if ($exe) { Start-Process $exe.FullName }
                        }
                    }
                }

                Add-Log "Installation completed successfully."
                $sync.Done = $true
            } catch {
                $sync.Error = $_.Exception.Message
                Add-Log "Error: $($sync.Error)"
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
        $t.Interval = [TimeSpan]::FromMilliseconds(80)
        $t.Add_Tick({
            while ($sync.Logs.Count -gt 0) {
                $entry = $sync.Logs[0]
                $sync.Logs.RemoveAt(0)
                $txtLog.AppendText($entry + "`r`n")
                $txtLog.ScrollToEnd()
            }
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

    $btnInstall.Add_Click({ Run-Action "Install" })
    $btnUninstall.Add_Click({ Run-Action "Uninstall" })

    Update-Language
    Update-Theme

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
