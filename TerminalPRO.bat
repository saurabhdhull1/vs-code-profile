@echo off
setlocal EnableExtensions
title TerminalPRO - PowerShell + Windows Terminal + VS Code (no admin)
set "SETUP=%TEMP%\TerminalPRO-setup.ps1"
set "PS=powershell.exe -NoProfile -ExecutionPolicy Bypass"

echo ============================================================
echo  TerminalPRO - terminal setup, no administrator rights
echo ============================================================
echo   - JetBrainsMono NF font  (Nerd Font, per-user install)
echo   - Starship prompt  + theme
echo   - Windows Terminal theme (Catppuccin Mocha / Tokyo Night)
echo   - VS Code integrated terminal + fonts
echo ============================================================
echo.

where powershell.exe >nul 2>&1
if errorlevel 1 (
    echo [!!] Windows PowerShell was not found.
    pause
    exit /b 1
)

echo [0/11] Extracting helper script...
%PS% -Command "$self='%~f0'; $bm=('# BEGIN TERMINALPRO ' + 'SETUP'); $em=('# END TERMINALPRO ' + 'SETUP'); $p=Join-Path $env:TEMP 'TerminalPRO-setup.ps1'; $src=Get-Content -LiteralPath $self -Raw -Encoding UTF8; $i=$src.IndexOf($bm); $j=$src.IndexOf($em); if ($i -lt 0 -or $j -lt $i) { Write-Host '[!!] Setup block not found inside this .bat file.'; exit 1 }; $code=$src.Substring($i, ($j - $i) + $em.Length); [IO.File]::WriteAllText($p, $code, (New-Object System.Text.UTF8Encoding $false)); Write-Host ('     helper script: ' + $p)"
if not exist "%SETUP%" (
    echo [!!] Could not extract the helper script - run this .bat from a normal folder.
    pause
    exit /b 1
)

echo.
echo [1/11] Configuring execution policy for current user...
%PS% -Command "try { Set-ExecutionPolicy -Scope CurrentUser -ExecutionPolicy RemoteSigned -Force -ErrorAction Stop; Write-Host '[OK] CurrentUser policy = RemoteSigned' } catch { Write-Host ('[!!] Unable to change policy: ' + $_.Exception.Message) -ForegroundColor Yellow }"

echo.
echo [2/11] Installing NuGet provider if required...
%PS% -Command "if (-not (Get-PackageProvider -Name NuGet -ErrorAction SilentlyContinue)) { try { Install-PackageProvider -Name NuGet -MinimumVersion 2.8.5.201 -Force -ErrorAction Stop; Write-Host '[OK] NuGet installed' } catch { Write-Host ('[!!] ' + $_.Exception.Message) -ForegroundColor Yellow } } else { Write-Host '[OK] NuGet already available' }"

echo.
echo [3/11] Installing/updating PSReadLine...
%PS% -Command "try { Install-Module PSReadLine -Scope CurrentUser -Force -AllowClobber -ErrorAction Stop; Write-Host '[OK] PSReadLine installed/updated' } catch { Write-Host ('[!!] PSReadLine: ' + $_.Exception.Message) -ForegroundColor Yellow }"

echo.
echo [4/11] Preparing PowerShell profile files...
%PS% -Command "$p=$PROFILE.CurrentUserCurrentHost; Write-Host ('     profile: ' + $p); $dir=Split-Path -Parent $p; if (-not (Test-Path $dir)) { $null=New-Item -ItemType Directory -Path $dir -Force }; if (-not (Test-Path $p)) { $null=New-Item -ItemType File -Path $p -Force }; try { Unblock-File -LiteralPath $p -ErrorAction SilentlyContinue } catch {}"

echo.
echo [5/11] Installing Starship prompt...
%PS% -Command "$dir=Join-Path $env:LOCALAPPDATA 'Programs\starship'; $exe=Join-Path $dir 'starship.exe'; if (Get-Command starship -ErrorAction SilentlyContinue) { Write-Host ('[OK] starship already installed: ' + ((starship --version) -join ' ')) } elseif (Test-Path $exe) { Write-Host ('[OK] starship found: ' + ((& $exe --version) -join ' ')) } else { $zip=Join-Path $env:TEMP 'starship-setup.zip'; Write-Host '     downloading starship from github.com...'; try { [Net.ServicePointManager]::SecurityProtocol=[Net.SecurityProtocolType]::Tls12; Invoke-WebRequest -Uri 'https://github.com/starship/starship/releases/latest/download/starship-x86_64-pc-windows-msvc.zip' -OutFile $zip -UseBasicParsing -ErrorAction Stop; if (-not (Test-Path $dir)) { $null=New-Item -ItemType Directory -Path $dir -Force }; Expand-Archive -LiteralPath $zip -DestinationPath $dir -Force -ErrorAction Stop; Remove-Item -LiteralPath $zip -Force -ErrorAction SilentlyContinue; Unblock-File -LiteralPath $exe -ErrorAction SilentlyContinue; Write-Host ('[OK] starship installed: ' + ((& $exe --version) -join ' ')) } catch { Write-Host ('[!!] starship install failed: ' + $_.Exception.Message) -ForegroundColor Yellow; Write-Host '     No internet? Get it from https://starship.rs and drop starship.exe in the folder above.' } }; $userPath=[Environment]::GetEnvironmentVariable('Path','User'); if (-not $userPath) { $userPath='' }; if ($userPath -notlike ('*' + $dir + '*')) { [Environment]::SetEnvironmentVariable('Path', ($userPath.TrimEnd(';') + ';' + $dir).TrimStart(';'), 'User'); Write-Host '[OK] Added starship to user PATH' } else { Write-Host '[OK] starship is on user PATH' }"

echo.
echo [6/11] Installing JetBrainsMono NF font (per-user, no admin)...
%PS% -File "%SETUP%" -Step Font

echo.
echo [7/11] Writing Starship theme (Nerd Font icons, catppuccin colours)...
%PS% -File "%SETUP%" -Step Starship -Self "%~f0"

echo.
echo [8/11] Adding terminal configuration to the PowerShell profile...
%PS% -File "%SETUP%" -Step Profile -Self "%~f0"

echo.
echo [9/11] Applying Windows Terminal theme (Catppuccin Mocha + NF font)...
%PS% -File "%SETUP%" -Step WindowsTerminal

echo.
echo [10/11] Configuring VS Code integrated terminal...
%PS% -File "%SETUP%" -Step VSCode

echo.
echo [11/11] Verifying configuration...
%PS% -File "%SETUP%" -Step Verify

echo.
echo ============================================================
echo  Done - no administrator rights were needed.
echo.
echo  Next steps:
echo    1. Close EVERY Windows Terminal / VS Code window, reopen.
echo    2. Windows Terminal: Settings -^> Color schemes -^> Catppuccin Mocha
echo       or Tokyo Night.  Font: JetBrainsMono NF.
echo    3. VS Code: open a new terminal (Ctrl+Shift+backtick).
echo.
echo  Prompt:  [folder] path  [branch] branch  [status]  [arrow]
echo  Tab cycles completions, Ctrl+R searches history,
echo  Up/Down walks history, F2 toggles the prediction list.
echo ============================================================
echo.
pause
exit /b 0

# BEGIN TERMINALPRO SETUP
<#
    TerminalPRO helper - called by TerminalPRO.bat with -Step.

    Everything here is per-user and needs no administrator rights:
      * fonts  -> %LOCALAPPDATA%\Microsoft\Windows\Fonts + HKCU font registry
      * theme  -> Windows Terminal settings.json   (backed up before editing)
      * editor -> VS Code user settings.json       (backed up before editing,
                  comments and formatting are preserved)
#>
[CmdletBinding()]
param(
    [ValidateSet('Font', 'Starship', 'Profile', 'WindowsTerminal', 'VSCode', 'Verify')]
    [string]$Step = 'Font',
    [string]$Self
)

$ErrorActionPreference = 'Continue'
try { [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12 } catch { }

function Write-Ok([string]$message) { Write-Host ('     [OK] ' + $message) }
function Write-Warn([string]$message) { Write-Host ('     [!!] ' + $message) -ForegroundColor Yellow }
function Write-Note([string]$message) { Write-Host ('     ' + $message) }

function Backup-File([string]$path) {
    try {
        $bak = $path + '.bak-' + (Get-Date -Format 'yyyyMMdd-HHmmss')
        Copy-Item -LiteralPath $path -Destination $bak -Force -ErrorAction Stop
        Write-Note ('backup: ' + $bak)
        return $bak
    } catch {
        Write-Warn ('could not back up ' + $path + ': ' + $_.Exception.Message)
        return $null
    }
}

function Get-EmbeddedBlock([string]$beginMarker, [string]$endMarker) {
    if (-not $Self -or -not (Test-Path -LiteralPath $Self)) {
        Write-Warn 'helper was not given the path of TerminalPRO.bat (-Self)'
        return $null
    }
    $source = Get-Content -LiteralPath $Self -Raw -Encoding UTF8
    $start = $source.IndexOf($beginMarker)
    $end = $source.IndexOf($endMarker)
    if ($start -lt 0 -or $end -lt $start) {
        Write-Warn ('block not found in TerminalPRO.bat: ' + $beginMarker)
        return $null
    }
    return $source.Substring($start, ($end - $start) + $endMarker.Length)
}

# ---------------------------------------------------------------- JSON helpers
# Terminal / VS Code settings are JSON with comments and trailing commas.
function ConvertFrom-Jsonc([string]$text) {
    if ($null -eq $text) { return $null }
    $text = $text.TrimStart([char]0xFEFF)
    $sb = New-Object System.Text.StringBuilder
    $inString = $false
    $escaped = $false
    $i = 0
    while ($i -lt $text.Length) {
        $c = $text[$i]
        if ($inString) {
            [void]$sb.Append($c)
            if ($escaped) { $escaped = $false }
            elseif ($c -eq '\') { $escaped = $true }
            elseif ($c -eq '"') { $inString = $false }
            $i++
            continue
        }
        if ($c -eq '"') { $inString = $true; [void]$sb.Append($c); $i++; continue }
        if ($c -eq '/' -and ($i + 1) -lt $text.Length) {
            $next = $text[$i + 1]
            if ($next -eq '/') {
                while ($i -lt $text.Length -and $text[$i] -ne "`n") { $i++ }
                continue
            }
            if ($next -eq '*') {
                $i += 2
                while (($i + 1) -lt $text.Length -and -not ($text[$i] -eq '*' -and $text[$i + 1] -eq '/')) { $i++ }
                $i += 2
                continue
            }
        }
        [void]$sb.Append($c)
        $i++
    }
    $clean = $sb.ToString()
    $clean = [regex]::Replace($clean, ',(\s*[}\]])', '$1')
    return ($clean | ConvertFrom-Json)
}

function Set-JsonProp($object, [string]$name, $value) {
    if ($null -eq $object) { return }
    if ($object.PSObject.Properties[$name]) { $object.$name = $value }
    else { $object | Add-Member -NotePropertyName $name -NotePropertyValue $value -Force }
}

function Save-Json($object, [string]$path) {
    $json = $object | ConvertTo-Json -Depth 32
    [IO.File]::WriteAllText($path, $json, (New-Object System.Text.UTF8Encoding $false))
}

# Edits a JSONC document one top-level key at a time, keeping every comment,
# blank line and the user's own ordering intact.
function Set-JsoncValue([string]$text, [string]$key, [string]$jsonValue) {
    $newline = "`r`n"
    if ($text -notmatch "`r`n") { $newline = "`n" }
    $lines = New-Object System.Collections.Generic.List[string]
    foreach ($line in ($text -split "`r?`n")) { $lines.Add($line) }

    $quotedKey = '"' + $key + '"'
    $isCommented = { param($line) $line -match '^\s*//' }
    $matching = -1
    for ($i = 0; $i -lt $lines.Count; $i++) {
        $line = $lines[$i]
        if (& $isCommented $line) { continue }
        if ($line -match ('^\s*' + [regex]::Escape($quotedKey) + '\s*:')) { $matching = $i; break }
    }

    if ($matching -ge 0) {
        $line = $lines[$matching]
        $indent = ([regex]::Match($line, '^\s*')).Value
        $hasComma = $line -match ',\s*$'
        $valueText = [regex]::Replace($line, '^\s*' + [regex]::Escape($quotedKey) + '\s*:', '')
        $valueText = $valueText -replace ',\s*$', ''
        # only rewrite values we can fully see on this line
        try {
            $null = ('{"probe": ' + $valueText.Trim() + '}') | ConvertFrom-Json
        } catch {
            return $null   # multi-line / unusual value: leave the file alone
        }
        $replacement = $indent + $quotedKey + ': ' + $jsonValue
        if ($hasComma) { $replacement += ',' }
        $lines[$matching] = $replacement
        return ($lines -join $newline)
    }

    # key is missing: insert it just before the closing brace of the document
    $closing = -1
    for ($i = $lines.Count - 1; $i -ge 0; $i--) {
        if ($lines[$i].Trim() -eq '}') { $closing = $i; break }
    }
    if ($closing -lt 0) { return $null }

    $previous = $closing - 1
    while ($previous -ge 0 -and $lines[$previous].Trim() -eq '') { $previous-- }
    if ($previous -ge 0) {
        $trimmed = $lines[$previous].TrimEnd()
        if ($trimmed -notmatch '[,\{\[]$') { $lines[$previous] = $trimmed + ',' }
    }

    # reuse the indentation the document already uses for top level keys
    $indent = '  '
    for ($i = $previous; $i -ge 0; $i--) {
        $probe = [regex]::Match($lines[$i], '^(\s+)"')
        if ($probe.Success) { $indent = $probe.Groups[1].Value; break }
    }
    $lines.Insert($closing, $indent + $quotedKey + ': ' + $jsonValue + ',')
    return ($lines -join $newline)
}

# ---------------------------------------------------------------- font install
$FontFamily = 'JetBrainsMono NF'
$FontFiles = @{
    'JetBrainsMonoNerdFont-Regular.ttf'        = 'Regular'
    'JetBrainsMonoNerdFont-Bold.ttf'           = 'Bold'
    'JetBrainsMonoNerdFont-Italic.ttf'         = 'Italic'
    'JetBrainsMonoNerdFont-BoldItalic.ttf'     = 'Bold Italic'
    'JetBrainsMonoNerdFont-Medium.ttf'         = 'Medium'
    'JetBrainsMonoNerdFontMono-Regular.ttf'    = 'Regular'
    'JetBrainsMonoNerdFontMono-Bold.ttf'       = 'Bold'
    'JetBrainsMonoNerdFontMono-Italic.ttf'     = 'Italic'
    'JetBrainsMonoNerdFontMono-BoldItalic.ttf' = 'Bold Italic'
}

$FontNativeCode = @'
using System;
using System.Runtime.InteropServices;
public static class TerminalProFontApi {
    [DllImport("gdi32.dll", CharSet = CharSet.Unicode)]
    public static extern int AddFontResourceEx(string lpFileName, uint fl, IntPtr pdv);
    [DllImport("user32.dll", CharSet = CharSet.Unicode)]
    public static extern IntPtr SendMessageTimeout(IntPtr hWnd, uint msg, UIntPtr wParam, IntPtr lParam, uint flags, uint timeout, out UIntPtr result);
}
'@

function Get-FontFamilyName([string]$file) {
    try {
        Add-Type -AssemblyName System.Drawing -ErrorAction Stop
        $collection = New-Object System.Drawing.Text.PrivateFontCollection
        $collection.AddFontFile($file)
        if ($collection.Families.Count -gt 0) { return $collection.Families[0].Name }
    } catch { }
    return $null
}

function Install-NerdFont {
    $fontDir = Join-Path $env:LOCALAPPDATA 'Microsoft\Windows\Fonts'
    $regPath = 'HKCU:\Software\Microsoft\Windows NT\CurrentVersion\Fonts'

    $missing = @()
    foreach ($name in $FontFiles.Keys) {
        if (-not (Test-Path (Join-Path $fontDir $name))) { $missing += $name }
    }
    if ($missing.Count -eq 0) {
        Write-Ok ($FontFamily + ' is already installed for this user')
        return $true
    }

    if (-not (Test-Path $fontDir)) { $null = New-Item -ItemType Directory -Path $fontDir -Force }

    $work = Join-Path $env:TEMP ('TerminalPRO-font-' + [guid]::NewGuid().ToString('N').Substring(0, 8))
    $null = New-Item -ItemType Directory -Path $work -Force

    $tar = Get-Command tar.exe -ErrorAction SilentlyContinue
    if ($tar) {
        $url = 'https://github.com/ryanoasis/nerd-fonts/releases/latest/download/JetBrainsMono.tar.xz'
        $archive = Join-Path $work 'JetBrainsMono.tar.xz'
    } else {
        $url = 'https://github.com/ryanoasis/nerd-fonts/releases/latest/download/JetBrainsMono.zip'
        $archive = Join-Path $work 'JetBrainsMono.zip'
    }

    Write-Note 'downloading JetBrainsMono Nerd Font from github.com (about 7 MB)...'
    try {
        Invoke-WebRequest -Uri $url -OutFile $archive -UseBasicParsing -ErrorAction Stop
    } catch {
        Write-Warn ('font download failed: ' + $_.Exception.Message)
        Write-Note 'offline fix: get JetBrainsMono.tar.xz from github.com/ryanoasis/nerd-fonts/releases'
        Write-Note 'and copy the JetBrainsMonoNerdFont-*.ttf files into the folder below, then re-run.'
        Write-Note ('    ' + $fontDir)
        return $false
    }

    $extracted = $false
    if ($tar) {
        & tar.exe -xf $archive -C $work 2>$null
        if ($LASTEXITCODE -eq 0) { $extracted = $true }
    }
    if (-not $extracted) {
        try {
            if (-not (Test-Path $archive) -or $tar) {
                $zipUrl = 'https://github.com/ryanoasis/nerd-fonts/releases/latest/download/JetBrainsMono.zip'
                $zipFile = Join-Path $work 'JetBrainsMono.zip'
                Invoke-WebRequest -Uri $zipUrl -OutFile $zipFile -UseBasicParsing -ErrorAction Stop
            }
            Expand-Archive -LiteralPath (Join-Path $work 'JetBrainsMono.zip') -DestinationPath $work -Force -ErrorAction Stop
            $extracted = $true
        } catch {
            Write-Warn ('font extraction failed: ' + $_.Exception.Message)
            Remove-Item -LiteralPath $work -Recurse -Force -ErrorAction SilentlyContinue
            return $false
        }
    }

    if (-not ('TerminalProFontApi' -as [type])) {
        try { Add-Type -TypeDefinition $FontNativeCode -ErrorAction Stop } catch { }
    }
    if (-not (Test-Path $regPath)) { $null = New-Item -Path $regPath -Force }

    $installed = 0
    foreach ($name in $FontFiles.Keys) {
        $source = Get-ChildItem -LiteralPath $work -Recurse -Filter $name -File -ErrorAction SilentlyContinue |
            Select-Object -First 1
        if (-not $source) { Write-Warn ('missing in download: ' + $name); continue }

        $target = Join-Path $fontDir $name
        Copy-Item -LiteralPath $source.FullName -Destination $target -Force

        $family = Get-FontFamilyName $target
        if (-not $family) { $family = $FontFamily }
        $valueName = '{0} {1} (TrueType)' -f $family, $FontFiles[$name]
        New-ItemProperty -Path $regPath -Name $valueName -Value $target -PropertyType String -Force | Out-Null

        if ('TerminalProFontApi' -as [type]) {
            [void][TerminalProFontApi]::AddFontResourceEx($target, 0x10, [IntPtr]::Zero)
        }
        $installed++
    }

    # Tell running apps (and the shell) that the font list changed.
    if ('TerminalProFontApi' -as [type]) {
        $result = [UIntPtr]::Zero
        [void][TerminalProFontApi]::SendMessageTimeout([IntPtr]0xffff, 0x001D, [UIntPtr]::Zero, [IntPtr]::Zero, 2, 1000, [ref]$result)
    }

    Remove-Item -LiteralPath $work -Recurse -Force -ErrorAction SilentlyContinue

    if ($installed -gt 0) {
        Write-Ok ('installed ' + $installed + ' font files into ' + $fontDir)
        Write-Ok ('font families: ' + $FontFamily + ' and ' + $FontFamily + 'M')
        return $true
    }
    Write-Warn 'no font file was installed'
    return $false
}

# ------------------------------------------------------------- starship theme
function Set-StarshipConfig {
    $block = Get-EmbeddedBlock ('# BEGIN STARSHIP ' + 'THEME') ('# END STARSHIP ' + 'THEME')
    if (-not $block) { return $false }

    $configDir = Join-Path $HOME '.config'
    $target = Join-Path $configDir 'starship.toml'
    if (-not (Test-Path $configDir)) { $null = New-Item -ItemType Directory -Path $configDir -Force }

    $old = ''
    if (Test-Path $target) { $old = Get-Content -LiteralPath $target -Raw -Encoding UTF8 }
    if ($old -and ($old.Trim() -ne $block.Trim())) { Backup-File $target | Out-Null }

    [IO.File]::WriteAllText($target, $block, (New-Object System.Text.UTF8Encoding $false))
    Write-Ok 'starship theme written'
    Write-Note $target
    return $true
}

# ------------------------------------------------------------ profile config
function Set-ProfileConfig {
    $block = Get-EmbeddedBlock ('# BEGIN DEV TERMINAL ' + 'CONFIG') ('# END DEV TERMINAL ' + 'CONFIG')
    if (-not $block) { return $false }

    $beginMarker = '# BEGIN DEV TERMINAL ' + 'CONFIG'
    $endMarker = '# END DEV TERMINAL ' + 'CONFIG'

    $targets = New-Object System.Collections.Generic.List[string]
    [void]$targets.Add((Join-Path $HOME 'Documents\WindowsPowerShell\Microsoft.PowerShell_profile.ps1'))

    $pwshDir = Join-Path $HOME 'Documents\PowerShell'
    $pwshExists = (Test-Path (Join-Path $pwshDir 'Microsoft.PowerShell_profile.ps1')) -or
                  (Test-Path $pwshDir) -or
                  (Get-Command pwsh.exe -ErrorAction SilentlyContinue) -or
                  (Test-Path 'C:\Program Files\PowerShell\7\pwsh.exe')
    if ($pwshExists) { [void]$targets.Add((Join-Path $pwshDir 'Microsoft.PowerShell_profile.ps1')) }

    $written = 0
    foreach ($target in $targets) {
        $dir = Split-Path -Parent $target
        if (-not (Test-Path $dir)) { $null = New-Item -ItemType Directory -Path $dir -Force }
        if (-not (Test-Path $target)) { $null = New-Item -ItemType File -Path $target -Force }
        try { Unblock-File -LiteralPath $target -ErrorAction SilentlyContinue } catch { }

        $existing = Get-Content -LiteralPath $target -Raw -Encoding UTF8 -ErrorAction SilentlyContinue
        if ($null -eq $existing) { $existing = '' }

        $start = $existing.IndexOf($beginMarker)
        $end = $existing.IndexOf($endMarker)
        if ($start -ge 0 -and $end -gt $start) {
            $length = ($end - $start) + $endMarker.Length
            $updated = $existing.Remove($start, $length).Insert($start, $block)
        } elseif ($existing.Trim().Length -eq 0) {
            $updated = $block
        } else {
            $updated = $existing.TrimEnd() + "`r`n`r`n" + $block + "`r`n"
        }

        [IO.File]::WriteAllText($target, $updated, (New-Object System.Text.UTF8Encoding $false))
        Write-Ok ('profile configured: ' + $target)
        $written++
    }
    return ($written -gt 0)
}

# ------------------------------------------------------- Windows Terminal theme
$Schemes = @(
    @{
        name = 'Catppuccin Mocha'; background = '#1E1E2E'; foreground = '#CDD6F4'
        cursorColor = '#F5E0DC'; selectionBackground = '#585B70'
        black = '#45475A'; red = '#F38BA8'; green = '#A6E3A1'; yellow = '#F9E2AF'
        blue = '#89B4FA'; purple = '#F5C2E7'; cyan = '#94E2D5'; white = '#BAC2DE'
        brightBlack = '#585B70'; brightRed = '#F38BA8'; brightGreen = '#A6E3A1'; brightYellow = '#F9E2AF'
        brightBlue = '#89B4FA'; brightPurple = '#F5C2E7'; brightCyan = '#94E2D5'; brightWhite = '#A6ADC8'
    },
    @{
        name = 'Tokyo Night'; background = '#1A1B26'; foreground = '#C0CAF5'
        cursorColor = '#C0CAF5'; selectionBackground = '#33467C'
        black = '#15161E'; red = '#F7768E'; green = '#9ECE6A'; yellow = '#E0AF68'
        blue = '#7AA2F7'; purple = '#BB9AF7'; cyan = '#7DCFFF'; white = '#A9B1D6'
        brightBlack = '#414868'; brightRed = '#F7768E'; brightGreen = '#9ECE6A'; brightYellow = '#E0AF68'
        brightBlue = '#7AA2F7'; brightPurple = '#BB9AF7'; brightCyan = '#7DCFFF'; brightWhite = '#C0CAF5'
    }
)

function Get-TerminalSettingsPaths {
    $paths = New-Object System.Collections.Generic.List[string]
    $packages = Join-Path $env:LOCALAPPDATA 'Packages'
    $known = @(
        'Microsoft.WindowsTerminal_8wekyb3d8bbwe',
        'Microsoft.WindowsTerminalPreview_8wekyb3d8bbwe',
        'Microsoft.WindowsTerminalCanary_8wekyb3d8bbwe'
    )
    foreach ($pkg in $known) {
        $candidate = Join-Path $packages ($pkg + '\LocalState\settings.json')
        if (Test-Path $candidate) { [void]$paths.Add($candidate) }
    }
    $unpackaged = Join-Path $env:LOCALAPPDATA 'Microsoft\Windows Terminal\settings.json'
    if (Test-Path $unpackaged) { [void]$paths.Add($unpackaged) }
    return $paths
}

function Set-WindowsTerminalTheme {
    $paths = Get-TerminalSettingsPaths
    if ($paths.Count -eq 0) {
        Write-Warn 'Windows Terminal not found - skipped (install it from the Microsoft Store)'
        return $false
    }

    $done = $false
    foreach ($path in $paths) {
        try {
            $cfg = ConvertFrom-Jsonc (Get-Content -LiteralPath $path -Raw -Encoding UTF8)
            if (-not $cfg) { Write-Warn ('could not parse ' + $path + ' - skipped'); continue }
        } catch {
            Write-Warn ('could not parse ' + $path + ': ' + $_.Exception.Message)
            continue
        }

        Backup-File $path | Out-Null

        if (-not $cfg.PSObject.Properties['profiles'] -or -not $cfg.profiles) {
            Set-JsonProp $cfg 'profiles' ([pscustomobject]@{})
        }
        if (-not $cfg.profiles.PSObject.Properties['defaults'] -or -not $cfg.profiles.defaults) {
            Set-JsonProp $cfg.profiles 'defaults' ([pscustomobject]@{})
        }

        $defaults = $cfg.profiles.defaults
        Set-JsonProp $defaults 'font' ([pscustomobject]@{ face = $FontFamily; size = 11; weight = 'normal' })
        Set-JsonProp $defaults 'colorScheme' 'Catppuccin Mocha'
        Set-JsonProp $defaults 'padding' '10, 10, 8, 10'
        Set-JsonProp $defaults 'cursorShape' 'bar'
        Set-JsonProp $defaults 'antialiasingMode' 'grayscale'
        Set-JsonProp $defaults 'scrollbarState' 'hidden'
        if (-not $defaults.PSObject.Properties['opacity']) { Set-JsonProp $defaults 'opacity' 92 }
        if (-not $defaults.PSObject.Properties['useAcrylic']) { Set-JsonProp $defaults 'useAcrylic' $true }

        # merge colour schemes by name and keep the user's own schemes
        $existing = @()
        if ($cfg.PSObject.Properties['schemes'] -and $cfg.schemes) { $existing = @($cfg.schemes) }
        $merged = @()
        foreach ($old in $existing) {
            $replacement = $Schemes | Where-Object { $_.name -eq $old.name } | Select-Object -First 1
            if ($replacement) { $merged += [pscustomobject]$replacement } else { $merged += $old }
        }
        foreach ($scheme in $Schemes) {
            $present = $merged | Where-Object { $_.name -eq $scheme.name } | Select-Object -First 1
            if (-not $present) { $merged += [pscustomobject]$scheme }
        }
        Set-JsonProp $cfg 'schemes' @($merged)

        Save-Json $cfg $path
        Write-Ok ('theme applied: ' + $path)
        $done = $true
    }
    return $done
}

# --------------------------------------------------------------- VS Code config
function Get-VSCodeSettingsPaths {
    $paths = New-Object System.Collections.Generic.List[string]
    foreach ($flavour in @('Code', 'Code - Insiders', 'Cursor', 'VSCodium')) {
        $root = Join-Path $env:APPDATA $flavour
        if (Test-Path $root) {
            $userDir = Join-Path $root 'User'
            if (-not (Test-Path $userDir)) { $null = New-Item -ItemType Directory -Path $userDir -Force }
            [void]$paths.Add((Join-Path $userDir 'settings.json'))
        }
    }
    return $paths
}

function Set-VSCodeSettings {
    $paths = Get-VSCodeSettingsPaths
    if ($paths.Count -eq 0) {
        Write-Warn 'VS Code (or Cursor/VSCodium) user profile not found - skipped'
        Write-Note 'install VS Code, open it once, then re-run this .bat'
        return $false
    }

    $wanted = [ordered]@{
        'terminal.integrated.fontFamily'             = '"JetBrainsMono NF, Consolas, monospace"'
        'terminal.integrated.fontSize'               = '13'
        'terminal.integrated.fontLigatures.enabled'  = 'true'
        'terminal.integrated.cursorStyle'            = '"line"'
        'terminal.integrated.smoothScrolling'        = 'true'
        'terminal.integrated.defaultProfile.windows' = '"Windows PowerShell"'
        'editor.fontFamily'                          = '"JetBrainsMono NF, Consolas, ''Courier New'', monospace"'
        'editor.fontLigatures'                       = 'true'
    }

    $applied = 0
    foreach ($path in $paths) {
        $text = ''
        $existed = Test-Path $path
        if ($existed) {
            $text = Get-Content -LiteralPath $path -Raw -Encoding UTF8
        } else {
            $text = '{' + "`r`n" + '}' + "`r`n"
        }

        $original = $text
        $skipped = @()
        foreach ($key in $wanted.Keys) {
            $updated = Set-JsoncValue $text $key $wanted[$key]
            if ($null -eq $updated) { $skipped += $key; continue }
            $text = $updated
        }

        # never leave a broken file behind
        $valid = $true
        try { $null = ConvertFrom-Jsonc $text } catch { $valid = $false }
        if (-not $valid) {
            Write-Warn ('could not safely edit ' + $path + ' - left unchanged (see backup / manual edit)')
            continue
        }

        if ($existed) { Backup-File $path | Out-Null }
        [IO.File]::WriteAllText($path, $text, (New-Object System.Text.UTF8Encoding $false))
        Write-Ok ('VS Code terminal + font set: ' + $path)
        foreach ($key in $skipped) { Write-Warn ('left as-is (multi-line value): ' + $key) }
        $applied++
    }

    if ($applied -gt 0) {
        if (-not (Get-Command pwsh.exe -ErrorAction SilentlyContinue)) {
            Write-Note 'optional: PowerShell 7 renders starship faster - winget install Microsoft.PowerShell'
        }
    }
    return ($applied -gt 0)
}

# --------------------------------------------------------------------- verify
function Invoke-Verify {
    $fontDir = Join-Path $env:LOCALAPPDATA 'Microsoft\Windows\Fonts'
    if (Test-Path (Join-Path $fontDir 'JetBrainsMonoNerdFont-Regular.ttf')) {
        Write-Ok 'JetBrainsMono Nerd Font file present'
    } else {
        Write-Warn 'JetBrainsMono NF not found in the user font folder'
    }

    $registered = $false
    try {
        $registered = [bool]((Get-Item 'HKCU:\Software\Microsoft\Windows NT\CurrentVersion\Fonts').Property |
            Where-Object { $_ -like ($FontFamily + '*') })
    } catch { }
    if ($registered) { Write-Ok 'font registered for this user' } else { Write-Warn 'font registry entry missing' }

    $ship = (Get-Command starship -ErrorAction SilentlyContinue).Source
    if (-not $ship) {
        $candidate = Join-Path $env:LOCALAPPDATA 'Programs\starship\starship.exe'
        if (Test-Path $candidate) { $ship = $candidate }
    }
    if ($ship) {
        Write-Ok ('starship: ' + ((& $ship --version) -join ' '))
        $toml = Join-Path $HOME '.config\starship.toml'
        if (Test-Path $toml) {
            $env:STARSHIP_CONFIG = $toml
            $null = (& $ship prompt --status 0 --terminal-width 80 2>&1)
            if ($LASTEXITCODE -eq 0) { Write-Ok 'starship.toml parses correctly' }
            else { Write-Warn 'starship.toml has errors - run: starship prompt' }
        } else { Write-Warn 'starship.toml not found' }
    } else { Write-Warn 'starship binary not found' }

    $profileBlock = '# BEGIN DEV TERMINAL ' + 'CONFIG'
    $profilePaths = @((Join-Path $HOME 'Documents\WindowsPowerShell\Microsoft.PowerShell_profile.ps1'))
    $pwshProfile = Join-Path $HOME 'Documents\PowerShell\Microsoft.PowerShell_profile.ps1'
    if (Test-Path $pwshProfile) { $profilePaths += $pwshProfile }
    foreach ($profilePath in $profilePaths) {
        if (-not (Test-Path $profilePath)) { Write-Warn ('profile missing: ' + $profilePath); continue }
        $profileText = Get-Content -LiteralPath $profilePath -Raw
        if ($profileText.Contains($profileBlock)) { Write-Ok ('profile block present: ' + $profilePath) }
        else { Write-Warn ('profile block missing: ' + $profilePath) }
    }

    $module = Get-Module -ListAvailable PSReadLine | Sort-Object Version -Descending | Select-Object -First 1
    if ($module) { Write-Ok ('PSReadLine: ' + $module.Version) } else { Write-Warn 'PSReadLine is not installed' }

    foreach ($path in (Get-TerminalSettingsPaths)) {
        $text = Get-Content -LiteralPath $path -Raw
        if ($text -match 'Catppuccin Mocha') { Write-Ok ('Windows Terminal scheme present: ' + $path) }
        else { Write-Warn ('scheme missing in ' + $path) }
        if ($text -match [regex]::Escape($FontFamily)) { Write-Ok ('Windows Terminal font = ' + $FontFamily) }
        else { Write-Warn ('font setting missing in ' + $path) }
    }

    foreach ($path in (Get-VSCodeSettingsPaths)) {
        if (-not (Test-Path $path)) { continue }
        $text = Get-Content -LiteralPath $path -Raw
        if ($text -match [regex]::Escape($FontFamily)) { Write-Ok ('VS Code font set: ' + $path) }
        else { Write-Warn ('VS Code font setting missing in ' + $path) }
        if ($text -match 'terminal\.integrated\.defaultProfile\.windows') { Write-Ok 'VS Code terminal profile set' }
        else { Write-Warn 'VS Code terminal profile not set' }
    }

    if (Get-Command git -ErrorAction SilentlyContinue) { Write-Ok ('git: ' + (git --version)) }
    else { Write-Warn 'git not found - the prompt will only show the path' }
}

switch ($Step) {
    'Font'            { [void](Install-NerdFont) }
    'Starship'        { [void](Set-StarshipConfig) }
    'Profile'         { [void](Set-ProfileConfig) }
    'WindowsTerminal' { [void](Set-WindowsTerminalTheme) }
    'VSCode'          { [void](Set-VSCodeSettings) }
    'Verify'          { Invoke-Verify }
}

# END TERMINALPRO SETUP

# BEGIN DEV TERMINAL CONFIG

# ---------------------------------------------------------------
#  Encoding: starship, git and icons all speak UTF-8
# ---------------------------------------------------------------
try {
    [Console]::OutputEncoding = [System.Text.Encoding]::UTF8
    $OutputEncoding = [System.Text.Encoding]::UTF8
} catch { }

# ---------------------------------------------------------------
#  PSReadLine: history list, theme colours, key bindings
# ---------------------------------------------------------------
$psrl = Get-Module -ListAvailable PSReadLine | Sort-Object Version -Descending | Select-Object -First 1
if ($psrl) { Import-Module $psrl.Path -ErrorAction SilentlyContinue }

$esc = [char]27

if (Get-Module PSReadLine) {
    # Multi-row dropdown of matching history, not a faint inline hint.
    # Some hosts (VS Code, redirected output, legacy console) cannot render
    # predictions at all, so never let a failure block the shell.
    try {
        Set-PSReadLineOption -PredictionSource History
        Set-PSReadLineOption -PredictionViewStyle ListView
    } catch {
        try { Set-PSReadLineOption -PredictionSource None } catch { }
    }
    Set-PSReadLineOption -HistorySaveStyle SaveIncrementally
    Set-PSReadLineOption -MaximumHistoryCount 4096
    Set-PSReadLineOption -HistorySearchCursorMovesToEnd

    # Colours for the history dropdown and text selection
    try {
        Set-PSReadLineOption -Colors @{
            InlinePrediction       = "$esc[38;5;244m"
            ListPrediction         = "$esc[38;5;250m"
            ListPredictionSelected = "$esc[48;5;237m"
            Selection              = "$esc[48;5;237m"
            ContinuationPrompt     = "$esc[90m"
        }
    } catch { }

    # Tab cycles completions, Up/Down search history only
    Set-PSReadLineKeyHandler -Key Tab -Function MenuComplete
    Set-PSReadLineKeyHandler -Key Ctrl+r -Function ReverseSearchHistory
    Set-PSReadLineKeyHandler -Key UpArrow -Function HistorySearchBackward
    Set-PSReadLineKeyHandler -Key DownArrow -Function HistorySearchForward
}

# ---------------------------------------------------------------
#  Starship prompt: path icon, git branch/status, coloured arrow
#  Settings live in ~\.config\starship.toml (written by this .bat)
# ---------------------------------------------------------------
$global:DevStarship = $null

$starshipCmd = Get-Command starship -ErrorAction SilentlyContinue
if ($starshipCmd) {
    $global:DevStarship = $starshipCmd.Source
} else {
    $candidate = Join-Path $env:LOCALAPPDATA 'Programs\starship\starship.exe'
    if (Test-Path $candidate) {
        $global:DevStarship = $candidate
        $env:PATH = $env:PATH.TrimEnd(';') + ';' + (Split-Path -Parent $candidate)
    }
}

if ($global:DevStarship) {
    $env:STARSHIP_CONFIG = Join-Path $HOME '.config\starship.toml'
    try {
        $init = & $global:DevStarship init powershell --print-full-init 2>$null
        if ($init) { Invoke-Expression ($init | Out-String) }
    } catch {
        $global:DevStarship = $null
    }
}

# ---------------------------------------------------------------
#  Fallback theme (only used when starship is not available)
# ---------------------------------------------------------------
if (-not $global:DevStarship) {

    $global:DevAnsi = $true
    try { if (-not $Host.UI.SupportsVirtualTerminal) { $global:DevAnsi = $false } } catch { $global:DevAnsi = $false }
    if ($env:TERM -eq 'dumb') { $global:DevAnsi = $false }
    try { if ([Console]::IsOutputRedirected) { $global:DevAnsi = $false } } catch { }
    if ($env:NO_COLOR) { $global:DevAnsi = $false }

    $global:DevColors = @{
        Reset = "$esc[0m"
        Path  = "$esc[1;36m"   # bold cyan
        Git   = "$esc[1;35m"   # bold magenta
        Dirty = "$esc[1;33m"   # bold yellow
        Ok    = "$esc[1;32m"   # bold green
        Bad   = "$esc[1;31m"   # bold red
    }

    # Icons are built from code points so this file stays pure ASCII
    $global:DevIconPath  = if ($global:DevAnsi) { [char]::ConvertFromUtf32(0xF07B) } else { 'PS' }
    $global:DevIconGit   = if ($global:DevAnsi) { [char]::ConvertFromUtf32(0xE0A0) } else { 'git:' }
    $global:DevIconArrow = if ($global:DevAnsi) { [char]::ConvertFromUtf32(0x276F) } else { '>' }
    $global:DevEllipsis  = [char]::ConvertFromUtf32(0x2026)

    function global:Format-PromptPart {
        param([string]$Color, [string]$Text)
        if ($global:DevAnsi) { return "$Color$Text$($global:DevColors.Reset)" }
        return $Text
    }

    $global:DevGitCache = @{}

    function global:Get-PromptGit {
        $dir = $PWD.ProviderPath
        if (-not $dir) { return $null }

        # Cache for one second: the prompt runs after every command
        $hit = $global:DevGitCache[$dir]
        if ($hit -and ((Get-Date) - $hit.At).TotalMilliseconds -lt 1000) { return $hit.Info }

        $info = $null
        if (Get-Command git -ErrorAction SilentlyContinue) {
            # Walk up to find the work tree root, at most 25 levels
            $probe = $dir
            $root = $null
            for ($i = 0; $i -lt 25 -and $probe; $i++) {
                if (Test-Path -LiteralPath (Join-Path $probe '.git')) { $root = $probe; break }
                $parent = Split-Path -Parent $probe
                if (-not $parent -or $parent -eq $probe) { break }
                $probe = $parent
            }
            if ($root) {
                # One call gives branch name and dirty state
                $lines = @(& git -C $root --no-optional-locks status --porcelain=2 --branch 2>$null)
                if ($LASTEXITCODE -eq 0 -and $lines.Count -gt 0) {
                    $branch = 'HEAD'
                    $dirty = $false
                    foreach ($line in $lines) {
                        if ($line -like '# branch.head *') { $branch = $line.Substring(14) }
                        elseif ($line -notlike '# *') { $dirty = $true }
                    }
                    if ($branch -eq '(detached)') {
                        $short = & git -C $root --no-optional-locks rev-parse --short HEAD 2>$null
                        if ($short) { $branch = '@' + $short }
                    }
                    $info = [pscustomobject]@{ Branch = $branch; Dirty = $dirty }
                }
            }
        }

        $global:DevGitCache[$dir] = @{ At = (Get-Date); Info = $info }
        return $info
    }

    function global:prompt {
        $ok = $?
        $savedExit = $global:LASTEXITCODE

        try {
            $path = [string]$PWD.Path
            if ($path -and $HOME -and $path.StartsWith($HOME, 'OrdinalIgnoreCase')) {
                $shown = '~' + $path.Substring($HOME.Length)
            } else {
                $shown = $path
            }

            # Keep the prompt short only when the path gets long
            if ($shown.Length -gt 55) {
                $parts = $shown -split '\\'
                if ($parts.Count -gt 3) {
                    $shown = (($parts[0], $global:DevEllipsis) + ($parts[-2..-1])) -join '\'
                }
            }

            $out = Format-PromptPart $global:DevColors.Path ($global:DevIconPath + ' ' + $shown)

            $git = Get-PromptGit
            if ($git) {
                $out += ' ' + (Format-PromptPart $global:DevColors.Git ($global:DevIconGit + ' ' + $git.Branch))
                if ($git.Dirty) { $out += (Format-PromptPart $global:DevColors.Dirty '*') }
            }

            if ($ok) {
                $out += '  ' + (Format-PromptPart $global:DevColors.Ok $global:DevIconArrow)
            } else {
                $out += '  ' + (Format-PromptPart $global:DevColors.Bad $global:DevIconArrow)
            }

            return $out + ' '
        } catch {
            return 'PS ' + $PWD.Path + '> '
        } finally {
            $global:LASTEXITCODE = $savedExit
        }
    }
}

# END DEV TERMINAL CONFIG

# BEGIN STARSHIP THEME
# TerminalPRO - Starship theme for JetBrainsMono NF + Catppuccin Mocha
# Icons are \u escapes so this block stays pure ASCII:
#   \uf07b folder  \ue0a0 branch  \uf017 clock  \uf023 lock  \u276f arrow
add_newline = false
command_timeout = 2000
scan_timeout = 30
format = "$directory$git_branch$git_status$docker_context$nodejs$python$rust$golang$cmd_duration$character"
right_format = "$time"

[time]
disabled = false
time_format = "%H:%M"
style = "bold #6C7086"

[character]
success_symbol = "[\u276f](bold #A6E3A1)"
error_symbol = "[\u276f](bold #F38BA8)"
vimcmd_symbol = "[\u276e](bold #89B4FA)"
format = "$symbol "

[directory]
style = "bold #89DCEB"
format = "[\uf07b $path]($style)[$read_only]($read_only_style) "
read_only = " \uf023"
read_only_style = "bold #F38BA8"
truncation_length = 4
truncation_symbol = ".../"
truncate_to_repo = true
home_symbol = "~"
repo_root_style = "bold #94E2D5"
repo_root_format = "[\uf07b $before_root_path]($before_repo_root_style)[$repo_root]($repo_root_style)[$path]($style)[$read_only]($read_only_style) "
use_os_path_sep = true

[git_branch]
symbol = "\ue0a0 "
style = "bold #CBA6F7"
format = "[$symbol$branch(:$remote_branch)]($style) "

[git_status]
style = "bold #F9E2AF"
format = "([$all_status$ahead_behind]($style) )"
conflicted = "="
ahead = "\u21e1${count}"
behind = "\u21e3${count}"
diverged = "\u21d5\u21e1${ahead_count}\u21e3${behind_count}"
untracked = "?${count}"
modified = "!${count}"
staged = "+${count}"
renamed = "\u00bb${count}"
deleted = "\u2718${count}"
stashed = "\u2261"

[cmd_duration]
min_time = 1500
style = "bold #FAB387"
format = "[\uf017 $duration]($style) "

[docker_context]
symbol = "\uf308 "
style = "bold #89B4FA"
format = "[$symbol$context]($style) "

[nodejs]
symbol = "\ue718 "
style = "bold #A6E3A1"
format = "[$symbol($version )]($style)"

[python]
symbol = "\ue73c "
style = "bold #F9E2AF"
format = "[$symbol($version )($virtualenv )]($style)"

[rust]
symbol = "\ue7a8 "
style = "bold #FAB387"
format = "[$symbol($version )]($style)"

[golang]
symbol = "\ue627 "
style = "bold #89DCEB"
format = "[$symbol($version )]($style)"

[package]
disabled = true
# END STARSHIP THEME
