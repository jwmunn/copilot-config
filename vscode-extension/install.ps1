# MSLearn Copilot Agents - Installation Script (PowerShell)
# ======================================================

Write-Host "🚀 MSLearn Copilot Agents - Installation Script" -ForegroundColor Green
Write-Host "================================================" -ForegroundColor Green

$extensionDir = $PSScriptRoot
Set-Location $extensionDir

function Run-Command {
    param(
        [string]$Command,
        [string]$Description
    )
    
    Write-Host ""
    Write-Host "📦 $Description..." -ForegroundColor Yellow
    
    try {
        $result = Invoke-Expression $Command
        Write-Host $result -ForegroundColor Gray
        return $true
    }
    catch {
        Write-Host "❌ Error: $_" -ForegroundColor Red
        return $false
    }
}

try {
    # Check if npm is available
    if (!(Run-Command "npm --version" "Checking npm")) {
        throw "npm not found. Please install Node.js"
    }

    # Install dependencies
    if (!(Run-Command "npm install" "Installing dependencies")) {
        throw "Failed to install dependencies"
    }

    # Compile TypeScript
    if (!(Run-Command "npm run compile" "Compiling TypeScript")) {
        throw "Failed to compile TypeScript"
    }

    # Package the extension
    Write-Host ""
    Write-Host "📦 Packaging extension..." -ForegroundColor Yellow
    if (!(Run-Command "npm run package" "Creating VSIX package")) {
        throw "Failed to package extension"
    }

    # Find the generated VSIX file
    $vsixFile = Get-ChildItem -Name "*.vsix" | Select-Object -First 1

    if (!$vsixFile) {
        throw "VSIX file not found after packaging"
    }

    Write-Host ""
    Write-Host "✅ Extension packaged: $vsixFile" -ForegroundColor Green

    # Install the extension
    Write-Host ""
    Write-Host "🔧 Installing extension in VS Code..." -ForegroundColor Yellow
    if (!(Run-Command "code --install-extension $vsixFile" "Installing extension")) {
        throw "Failed to install extension"
    }

    Write-Host ""
    Write-Host "🎉 Installation completed successfully!" -ForegroundColor Green
    Write-Host ""
    Write-Host "📋 Next steps:" -ForegroundColor Cyan
    Write-Host "1. Restart VS Code"
    Write-Host "2. Open a workspace with copilot-config directory"
    Write-Host "3. Use @mslearn-research, @mslearn-planning, etc. in the chat"
    Write-Host ""
    Write-Host "💡 Use Ctrl+Shift+P and search 'MSLearn' to see available commands" -ForegroundColor Yellow

}
catch {
    Write-Host ""
    Write-Host "❌ Installation failed: $_" -ForegroundColor Red
    Write-Host ""
    Write-Host "🔧 Manual installation steps:" -ForegroundColor Yellow
    Write-Host "1. cd vscode-extension"
    Write-Host "2. npm install"
    Write-Host "3. npm run compile"
    Write-Host "4. npm run package"
    Write-Host "5. code --install-extension *.vsix"
    exit 1
}