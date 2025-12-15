#!/usr/bin/env pwsh
# Build script for kOS.MechJeb2.Addon
# Usage: pwsh ./build.ps1 [-Config Debug|Release]
# Works on Windows, macOS, and Linux

param(
    [ValidateSet("Debug", "Release")]
    [string]$Config = "Debug"
)

$ErrorActionPreference = "Stop"
$ProjectDir = Split-Path -Parent $MyInvocation.MyCommand.Path
Set-Location $ProjectDir

Write-Host "==========================================="
Write-Host "Building kOS.MechJeb2.Addon ($Config)"
Write-Host "==========================================="

# Clean previous build
Write-Host "Cleaning previous build..."
Remove-Item -Recurse -Force "kOS.MechJeb2.Addon/bin", "kOS.MechJeb2.Addon/obj" -ErrorAction SilentlyContinue

# Find dotnet
$dotnet = "dotnet"
if ($IsMacOS) {
    # macOS with Homebrew
    $brewDotnet = "/opt/homebrew/opt/dotnet@8/bin/dotnet"
    if (Test-Path $brewDotnet) { $dotnet = $brewDotnet }
}

# Build
Write-Host "Building..."
& $dotnet build "kOS.MechJeb2.Addon/kOS.MechJeb2.Addon.csproj" -c $Config
if ($LASTEXITCODE -ne 0) {
    Write-Host "Build failed!" -ForegroundColor Red
    exit 1
}

# Verify DLL was created
$DllPath = "kOS.MechJeb2.Addon/bin/$Config/kOS.MechJeb2.Addon.dll"
if (-not (Test-Path $DllPath)) {
    Write-Host "Build failed - DLL not found at $DllPath" -ForegroundColor Red
    exit 1
}

Write-Host ""
Write-Host "Build successful!" -ForegroundColor Green
Get-Item $DllPath | Select-Object Name, Length, LastWriteTime
$hash = (Get-FileHash $DllPath -Algorithm SHA256).Hash
Write-Host "SHA256: $hash"

# Detect KSP path based on OS
if ($IsWindows) {
    $KspPath = "C:/Program Files (x86)/Steam/steamapps/common/Kerbal Space Program"
    if (-not (Test-Path $KspPath)) {
        $KspPath = "D:/SteamLibrary/steamapps/common/Kerbal Space Program"
    }
} elseif ($IsMacOS) {
    $KspPath = "/Volumes/Flatty/SteamLibrary/steamapps/common/Kerbal Space Program"
} else {
    $KspPath = "$HOME/.steam/steam/steamapps/common/Kerbal Space Program"
}

# Show GameData deployment status
$GameDataDll = "$KspPath/GameData/kOS.MechJeb2.Addon/kOS.MechJeb2.Addon.dll"
if (Test-Path $GameDataDll) {
    Write-Host ""
    Write-Host "GameData DLL:"
    Get-Item $GameDataDll | Select-Object Name, Length, LastWriteTime
    $hash = (Get-FileHash $GameDataDll -Algorithm SHA256).Hash
    Write-Host "SHA256: $hash"
} else {
    Write-Host ""
    Write-Host "Warning: No DLL found in GameData" -ForegroundColor Yellow
}

# Deploy kOS test scripts
$ScriptsDir = "$KspPath/Ships/Script"
if (Test-Path $ScriptsDir) {
    Write-Host ""
    Write-Host "Deploying kOS test scripts..."

    Get-ChildItem "Tests/*.ks" | ForEach-Object {
        $lowercaseName = $_.Name.ToLower()
        Copy-Item $_.FullName "$ScriptsDir/$lowercaseName" -Force
    }

    Write-Host "Test scripts deployed to kOS archive (as lowercase)" -ForegroundColor Green
    Get-ChildItem "$ScriptsDir/*.ks" | Select-Object Name | ForEach-Object { Write-Host "  $($_.Name)" }
}

Write-Host ""
Write-Host "==========================================="
Write-Host "IMPORTANT: KSP must be restarted to load the new DLL!" -ForegroundColor Yellow
Write-Host "==========================================="
Write-Host ""
Write-Host "To test in kOS: RUN testrunner."
Write-Host ""
