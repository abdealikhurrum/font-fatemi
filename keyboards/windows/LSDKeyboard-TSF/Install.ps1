#Requires -RunAsAdministrator
<#
.SYNOPSIS
    Register or unregister the LSD Keyboard TSF IME.

.DESCRIPTION
    Build the project first:
        dotnet publish -c Release -r win-x64 --self-contained false

    Then run this script from the publish output directory, or pass -PublishDir:
        .\Install.ps1 -PublishDir .\publish\win-x64

    To uninstall:
        .\Install.ps1 -Uninstall

.PARAMETER PublishDir
    Path to the dotnet publish output. Defaults to .\LSDKeyboard.Tsf\bin\Release\net8.0-windows\win-x64\publish

.PARAMETER Uninstall
    Remove all registry entries and unregister the comhost.
#>

param(
    [string] $PublishDir = ".\LSDKeyboard.Tsf\bin\Release\net8.0-windows\win-x64\publish",
    [switch] $Uninstall
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

# GUIDs — must match LSDTextInputProcessor.cs constants exactly
$Clsid           = "{C4172B4F-E6D8-4C89-A6F0-28B82D531E4E}"
$LangProfileGuid = "{3E4B8C1A-F7D2-4E9B-A5C6-192837465011}"
$LangId          = "0x00000401"   # Arabic (Saudi Arabia)

$ComhostName = "LSDKeyboard.Tsf.comhost.dll"

# ---------------------------------------------------------------------------
# Uninstall
# ---------------------------------------------------------------------------

if ($Uninstall) {
    Write-Host "Unregistering LSD Keyboard TSF IME..."

    # Tell TSF to remove the language profile
    $tsf = New-Object -ComObject "msctf.dll"  # won't work directly; use reg deletion
    # Remove TSF profile registry entries
    $tipKey = "HKLM:\SOFTWARE\Microsoft\CTF\TIP\$Clsid"
    if (Test-Path $tipKey) {
        Remove-Item $tipKey -Recurse -Force
        Write-Host "  Removed TSF TIP registry key."
    }

    # Unregister the COM server
    $comhostPath = Join-Path $PublishDir $ComhostName
    if (Test-Path $comhostPath) {
        & regsvr32.exe /s /u $comhostPath
        Write-Host "  Unregistered $ComhostName."
    } else {
        Write-Warning "  Comhost not found at $comhostPath — skipping regsvr32 /u."
    }

    Write-Host "Uninstall complete. You may need to log off/on or restart ctfmon.exe."
    exit 0
}

# ---------------------------------------------------------------------------
# Install
# ---------------------------------------------------------------------------

$comhostPath = Join-Path (Resolve-Path $PublishDir) $ComhostName
if (-not (Test-Path $comhostPath)) {
    Write-Error "Comhost DLL not found: $comhostPath`nBuild the project first:`n  dotnet publish -c Release -r win-x64 --self-contained false"
}

Write-Host "Installing LSD Keyboard TSF IME..."
Write-Host "  Comhost: $comhostPath"

# 1. Register the COM server (writes HKCR\CLSID\{...}\InProcServer32)
Write-Host "  Registering COM server with regsvr32..."
& regsvr32.exe /s $comhostPath
if ($LASTEXITCODE -ne 0) { Write-Error "regsvr32 failed (exit $LASTEXITCODE)." }

# 2. Register the TSF language profile
#
#    TSF discovers IMEs via the registry tree:
#      HKLM\SOFTWARE\Microsoft\CTF\TIP\{CLSID}
#        Enable = 1 (DWORD)
#        \LanguageProfile\{LangId (hex8)}\{ProfileGUID}
#          Display      = "Lisan ud Dawat"   (REG_SZ)
#          Description  = "LSD Arabic IME"  (REG_SZ)
#          IconFile     = ""                 (REG_SZ, optional)
#          IconIndex    = 0                  (DWORD)
#          Enable       = 1                  (DWORD)
#
#    The language identifier key must be the decimal LCID formatted as 8 hex
#    digits with leading zeros: 0x00000401 for Arabic-SA.

$langHex = "0x00000401"
$tipBase  = "HKLM:\SOFTWARE\Microsoft\CTF\TIP\$Clsid"
$profPath = "$tipBase\LanguageProfile\$langHex\$LangProfileGuid"

Write-Host "  Writing TSF TIP registry entries..."

New-Item -Path $tipBase -Force | Out-Null
Set-ItemProperty -Path $tipBase -Name "Enable" -Value 1 -Type DWord

New-Item -Path $profPath -Force | Out-Null
Set-ItemProperty -Path $profPath -Name "Display"     -Value "Lisan ud Dawat"  -Type String
Set-ItemProperty -Path $profPath -Name "Description" -Value "LSD Arabic IME"  -Type String
Set-ItemProperty -Path $profPath -Name "IconFile"    -Value ""                -Type String
Set-ItemProperty -Path $profPath -Name "IconIndex"   -Value 0                 -Type DWord
Set-ItemProperty -Path $profPath -Name "Enable"      -Value 1                 -Type DWord

Write-Host "  Done."
Write-Host ""
Write-Host "Installation complete."
Write-Host "Open Settings > Time & Language > Language & Region,"
Write-Host "add Arabic (Saudi Arabia), and select 'Lisan ud Dawat' as the input method."
Write-Host "You may need to restart ctfmon.exe or log off/on for TSF to pick up the new IME."
