<#
  chrome-debullshit — Windows installer (PowerShell)

  Reads ../policy/debullshit.json (the single source of truth shared with the
  Linux/macOS installers) and writes the values under
  HKLM\SOFTWARE\Policies\Google\Chrome.

  Usage (run an *Administrator* PowerShell):
    .\install.ps1              # install
    .\install.ps1 -Uninstall   # remove

  Does NOT touch sync, passwords, payments, bookmarks, or extensions.
#>
[CmdletBinding()]
param([switch]$Uninstall)

$ErrorActionPreference = 'Stop'
$KeyPath = 'HKLM:\SOFTWARE\Policies\Google\Chrome'

# Require elevation — HKLM is machine-wide.
$admin = ([Security.Principal.WindowsPrincipal] `
  [Security.Principal.WindowsIdentity]::GetCurrent()
).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
if (-not $admin) {
  Write-Host "This must run in an Administrator PowerShell." -ForegroundColor Red
  Write-Host "Right-click PowerShell -> Run as administrator, then re-run."
  exit 1
}

$jsonPath = Join-Path $PSScriptRoot '..\policy\debullshit.json'
if (-not (Test-Path $jsonPath)) {
  Write-Host "Can't find $jsonPath — run this from the windows\ folder of the repo." -ForegroundColor Red
  exit 1
}
$policy = Get-Content -Raw $jsonPath | ConvertFrom-Json

if (-not (Test-Path $KeyPath)) { New-Item -Path $KeyPath -Force | Out-Null }

foreach ($prop in $policy.PSObject.Properties) {
  $name = $prop.Name
  if ($Uninstall) {
    Remove-ItemProperty -Path $KeyPath -Name $name -ErrorAction SilentlyContinue
    Write-Host "removed   $name" -ForegroundColor Green
  } else {
    # JSON booleans -> 0/1 DWORD; JSON numbers -> DWORD as-is.
    $value = if ($prop.Value -is [bool]) { [int][bool]$prop.Value } else { [int]$prop.Value }
    New-ItemProperty -Path $KeyPath -Name $name -PropertyType DWord -Value $value -Force | Out-Null
    Write-Host ("set       {0} = {1}" -f $name, $value) -ForegroundColor Green
  }
}

Write-Host ""
if ($Uninstall) {
  Write-Host "Done. Fully quit and relaunch Chrome to restore defaults." -ForegroundColor Green
} else {
  Write-Host "Done. Fully quit and relaunch Chrome." -ForegroundColor Green
}
Write-Host "Verify at chrome://policy -> Reload policies. Every entry should read OK." -ForegroundColor DarkGray
