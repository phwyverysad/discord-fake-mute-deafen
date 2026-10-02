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

    $b64Stable = "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"
    $b64PTB    = "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"
    $b64Canary = "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"

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
            WindowBg      = "#1E1F22"
            WindowBorder  = "#313338"
            TitleBg       = "#18191C"
            TitleFg       = "#F2F3F5"
            TextPrimary   = "#F2F3F5"
            TextMuted     = "#949BA4"
            CardBg        = "#2B2D31"
            CardBorder    = "#383A40"
            CardCheckedBg = "#292C44"
            BadgeBorder   = "#4E5058"
            LogBg         = "#111214"
            LogBorder     = "#383A40"
            LogFg         = "#DBDEE1"
            PbTrack       = "#2B2D31"
            BtnWinFg      = "#949BA4"
        }
        Light = @{
            WindowBg      = "#FFFFFF"
            WindowBorder  = "#D1D4D7"
            TitleBg       = "#F2F3F5"
            TitleFg       = "#2E3338"
            TextPrimary   = "#2E3338"
            TextMuted     = "#5C6067"
            CardBg        = "#F2F3F5"
            CardBorder    = "#D1D4D7"
            CardCheckedBg = "#E0E3FA"
            BadgeBorder   = "#949BA4"
            LogBg         = "#F8F9FA"
            LogBorder     = "#D1D4D7"
            LogFg         = "#2E3338"
            PbTrack       = "#E3E5E8"
            BtnWinFg      = "#5C6067"
        }
    }

    [xml]$xaml = @"
<Window xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
        xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml"
        Title="FakeMuteDeafen"
        Height="470" Width="440"
        WindowStartupLocation="CenterScreen"
        WindowStyle="None"
        AllowsTransparency="True"
        Background="Transparent"
        FontFamily="Segoe UI, Leelawadee UI, Tahoma, sans-serif"
        ResizeMode="NoResize">

    <Window.Resources>
        <SolidColorBrush x:Key="CardBg" Color="#2B2D31"/>
        <SolidColorBrush x:Key="CardBorder" Color="#383A40"/>
        <SolidColorBrush x:Key="CardCheckedBg" Color="#292C44"/>
        <SolidColorBrush x:Key="BadgeBorder" Color="#4E5058"/>
        <SolidColorBrush x:Key="TextPrimary" Color="#F2F3F5"/>
        <SolidColorBrush x:Key="LogBg" Color="#111214"/>
        <SolidColorBrush x:Key="LogBorder" Color="#383A40"/>
        <SolidColorBrush x:Key="LogFg" Color="#DBDEE1"/>
        <SolidColorBrush x:Key="PbTrack" Color="#2B2D31"/>

        <Style x:Key="CardCheck" TargetType="CheckBox">
            <Setter Property="Cursor" Value="Hand"/>
            <Setter Property="FocusVisualStyle" Value="{x:Null}"/>
            <Setter Property="Template">
                <Setter.Value>
                    <ControlTemplate TargetType="CheckBox">
                        <Border x:Name="cardBd" Background="{DynamicResource CardBg}" BorderBrush="{DynamicResource CardBorder}" BorderThickness="1.5" CornerRadius="8" Padding="6,8" Margin="4,0" Cursor="Hand">
                            <Grid>
                                <Border x:Name="chkBadge" Width="18" Height="18" CornerRadius="4" BorderThickness="1.5" BorderBrush="{DynamicResource BadgeBorder}" Background="Transparent" HorizontalAlignment="Right" VerticalAlignment="Top" Margin="0,0,0,0">
                                    <Path x:Name="checkMark" Data="M3,7.5 L6.5,11 L12,4" Stroke="#FFFFFF" StrokeThickness="2" StrokeStartLineCap="Round" StrokeEndLineCap="Round" StrokeLineJoin="Round" Visibility="Collapsed" HorizontalAlignment="Center" VerticalAlignment="Center"/>
                                </Border>
                                <ContentPresenter HorizontalAlignment="Center" VerticalAlignment="Center" Margin="0,4,0,0"/>
                            </Grid>
                        </Border>
                        <ControlTemplate.Triggers>
                            <Trigger Property="IsMouseOver" Value="True">
                                <Setter TargetName="cardBd" Property="BorderBrush" Value="#5865F2"/>
                                <Setter TargetName="cardBd" Property="Background" Value="#35373C"/>
                            </Trigger>
                            <Trigger Property="IsChecked" Value="True">
                                <Setter TargetName="cardBd" Property="BorderBrush" Value="#5865F2"/>
                                <Setter TargetName="cardBd" Property="Background" Value="{DynamicResource CardCheckedBg}"/>
                                <Setter TargetName="chkBadge" Property="Background" Value="#5865F2"/>
                                <Setter TargetName="chkBadge" Property="BorderBrush" Value="#5865F2"/>
                                <Setter TargetName="checkMark" Property="Visibility" Value="Visible"/>
                            </Trigger>
                            <Trigger Property="IsEnabled" Value="False">
                                <Setter TargetName="cardBd" Property="Opacity" Value="0.4"/>
                            </Trigger>
                        </ControlTemplate.Triggers>
                    </ControlTemplate>
                </Setter.Value>
            </Setter>
        </Style>

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
                <TextBlock Name="lblSelectTargets" Text="Discord Versions" Foreground="#949BA4" FontSize="12" FontWeight="SemiBold" Margin="0,0,0,8"/>

                <UniformGrid Columns="3" Margin="0,0,0,14" Height="105">
                    <CheckBox Name="chkStable" Style="{StaticResource CardCheck}">
                        <StackPanel HorizontalAlignment="Center" VerticalAlignment="Center">
                            <Image Name="imgStable" Width="42" Height="42" Margin="0,2,0,6" RenderOptions.BitmapScalingMode="HighQuality"/>
                            <TextBlock Name="txtStable" Text="Discord" FontSize="12" FontWeight="SemiBold" Foreground="{DynamicResource TextPrimary}" HorizontalAlignment="Center"/>
                        </StackPanel>
                    </CheckBox>
                    <CheckBox Name="chkPTB" Style="{StaticResource CardCheck}">
                        <StackPanel HorizontalAlignment="Center" VerticalAlignment="Center">
                            <Image Name="imgPTB" Width="42" Height="42" Margin="0,2,0,6" RenderOptions.BitmapScalingMode="HighQuality"/>
                            <TextBlock Name="txtPTB" Text="Discord PTB" FontSize="12" FontWeight="SemiBold" Foreground="{DynamicResource TextPrimary}" HorizontalAlignment="Center"/>
                        </StackPanel>
                    </CheckBox>
                    <CheckBox Name="chkCanary" Style="{StaticResource CardCheck}">
                        <StackPanel HorizontalAlignment="Center" VerticalAlignment="Center">
                            <Image Name="imgCanary" Width="42" Height="42" Margin="0,2,0,6" RenderOptions.BitmapScalingMode="HighQuality"/>
                            <TextBlock Name="txtCanary" Text="Discord Canary" FontSize="12" FontWeight="SemiBold" Foreground="{DynamicResource TextPrimary}" HorizontalAlignment="Center"/>
                        </StackPanel>
                    </CheckBox>
                </UniformGrid>

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
                <Border Name="BorderLog" Background="{DynamicResource LogBg}" BorderBrush="{DynamicResource LogBorder}" BorderThickness="1" CornerRadius="6">
                    <TextBox Name="txtLog" Height="85" IsReadOnly="True" Background="Transparent" Foreground="{DynamicResource LogFg}" BorderThickness="0" FontFamily="Consolas, monospace" FontSize="11" Padding="8,6" VerticalScrollBarVisibility="Auto" HorizontalScrollBarVisibility="Disabled" TextWrapping="Wrap"/>
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
    $chkStable        = $window.FindName("chkStable")
    $chkPTB           = $window.FindName("chkPTB")
    $chkCanary        = $window.FindName("chkCanary")

    $imgStable        = $window.FindName("imgStable")
    $imgPTB           = $window.FindName("imgPTB")
    $imgCanary        = $window.FindName("imgCanary")

    $txtStable        = $window.FindName("txtStable")
    $txtPTB           = $window.FindName("txtPTB")
    $txtCanary        = $window.FindName("txtCanary")

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

    function Get-IconBmp($paths, $b64) {
        foreach ($p in $paths) {
            if ($p -and (Test-Path $p)) {
                try {
                    $bmp = New-Object System.Windows.Media.Imaging.BitmapImage
                    $bmp.BeginInit()
                    $bmp.UriSource = New-Object System.Uri($p, [System.UriKind]::Absolute)
                    $bmp.CacheOption = [System.Windows.Media.Imaging.BitmapCacheOption]::OnLoad
                    $bmp.EndInit()
                    $bmp.Freeze()
                    return $bmp
                } catch {}
            }
        }
        if ($b64) {
            try {
                $bytes = [System.Convert]::FromBase64String($b64)
                $ms = New-Object System.IO.MemoryStream(,$bytes)
                $bmp = New-Object System.Windows.Media.Imaging.BitmapImage
                $bmp.BeginInit()
                $bmp.StreamSource = $ms
                $bmp.CacheOption = [System.Windows.Media.Imaging.BitmapCacheOption]::OnLoad
                $bmp.EndInit()
                $bmp.Freeze()
                return $bmp
            } catch {}
        }
        return $null
    }

    $ctxDir = $null
    if ($PSScriptRoot) { $ctxDir = $PSScriptRoot } elseif ($MyInvocation.MyCommand.Path) { $ctxDir = Split-Path -Parent $MyInvocation.MyCommand.Path }

    $pathsStable = @((Join-Path (Get-Location).Path "discord.png"))
    if ($ctxDir) { $pathsStable += (Join-Path $ctxDir "discord.png") }

    $pathsPTB = @((Join-Path (Get-Location).Path "discord-ptb.png"))
    if ($ctxDir) { $pathsPTB += (Join-Path $ctxDir "discord-ptb.png") }

    $pathsCanary = @((Join-Path (Get-Location).Path "discord-canary.png"))
    if ($ctxDir) { $pathsCanary += (Join-Path $ctxDir "discord-canary.png") }

    $imgStable.Source = Get-IconBmp $pathsStable $b64Stable
    $imgPTB.Source    = Get-IconBmp $pathsPTB $b64PTB
    $imgCanary.Source = Get-IconBmp $pathsCanary $b64Canary

    function Update-Theme {
        $thm = $global:Themes[$global:CurrentTheme]
        foreach ($k in $thm.Keys) {
            $window.Resources[$k] = Get-Brush $thm[$k]
        }
        $MainBorder.Background  = Get-Brush $thm.WindowBg
        $MainBorder.BorderBrush = Get-Brush $thm.WindowBorder
        $TitleBar.Background    = Get-Brush $thm.TitleBg
        $txtTitle.Foreground    = Get-Brush $thm.TitleFg
        $btnTheme.Foreground    = Get-Brush $thm.BtnWinFg
        $btnLang.Foreground     = Get-Brush $thm.BtnWinFg
        $btnMin.Foreground      = Get-Brush $thm.BtnWinFg
        $btnClose.Foreground     = Get-Brush $thm.BtnWinFg
        $lblSelectTargets.Foreground = Get-Brush $thm.TextMuted
        $lblStatus.Foreground   = Get-Brush $thm.TextMuted
        $lblLog.Foreground      = Get-Brush $thm.TextMuted
        $pb.Background          = Get-Brush $thm.PbTrack

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
        $txtStable.Text           = $d.Discord
        $txtPTB.Text              = $d.DiscordPTB
        $txtCanary.Text           = $d.DiscordCanary
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