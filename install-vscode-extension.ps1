# Quick installer for MSLearn Copilot Agents VS Code Extension
Write-Host "🚀 Installing MSLearn Copilot Agents VS Code Extension..." -ForegroundColor Green

$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Definition
$extensionDir = Join-Path $scriptDir "vscode-extension"

if (!(Test-Path $extensionDir)) {
    Write-Host "❌ Extension directory not found: $extensionDir" -ForegroundColor Red
    exit 1
}

Set-Location $extensionDir

$installScript = Join-Path $extensionDir "install.ps1"
if (Test-Path $installScript) {
    & $installScript
} else {
    Write-Host "❌ install.ps1 not found in extension directory" -ForegroundColor Red
    exit 1
}