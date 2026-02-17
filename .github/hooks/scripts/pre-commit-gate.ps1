#!/usr/bin/env pwsh
# Pre-commit quality gate hook - runs repo-specific checks before git commit
# Runs as preToolUse hook, only activates when the tool is bash and the command is git commit
$ErrorActionPreference = "Stop"

$inputJson = [Console]::In.ReadToEnd() | ConvertFrom-Json
$toolName = $inputJson.toolName

# Only intercept bash/shell commands
if ($toolName -notin "bash", "shell") { exit 0 }

$toolArgs = $inputJson.toolArgs | ConvertFrom-Json -ErrorAction SilentlyContinue
$command = $toolArgs.command
if (-not $command) { exit 0 }

# Only intercept git commit commands
if ($command -notmatch "git\s+commit") { exit 0 }

# Determine current repo
$cwd = $inputJson.cwd
try {
    Push-Location $cwd
    $repoRoot = git rev-parse --show-toplevel 2>$null
    $repoName = Split-Path $repoRoot -Leaf
} catch {
    $repoName = Split-Path $cwd -Leaf
} finally {
    Pop-Location
}

# Find workflow-config.json
$configLocations = @(
    ".github/config/workflow-config.json",
    "../copilot-config/.github/config/workflow-config.json",
    "../../copilot-config/.github/config/workflow-config.json"
)

$preCommitCmd = $null
foreach ($configPath in $configLocations) {
    if (Test-Path $configPath) {
        $config = Get-Content $configPath -Raw | ConvertFrom-Json

        # Try direct repo name match
        $repoConfig = $config.repositories.PSObject.Properties | Where-Object { $_.Name -eq $repoName }
        if ($repoConfig) {
            $preCommitCmd = $repoConfig.Value.preCommitCommand
        }

        # If no direct match, search aliases
        if (-not $preCommitCmd) {
            foreach ($prop in $config.repositories.PSObject.Properties) {
                $aliases = $prop.Value.aliases
                if ($aliases -and ($aliases -contains $repoName)) {
                    $preCommitCmd = $prop.Value.preCommitCommand
                    break
                }
            }
        }

        if ($preCommitCmd) { break }
    }
}

# If no pre-commit command found, allow the commit
if (-not $preCommitCmd) { exit 0 }

# Run the pre-commit checks
Write-Host "Running pre-commit quality gate: $preCommitCmd" -ForegroundColor Cyan
Push-Location $cwd
try {
    Invoke-Expression $preCommitCmd
    # Checks passed, allow the commit
    exit 0
} catch {
    @{
        permissionDecision = "deny"
        permissionDecisionReason = "Pre-commit quality gate failed. Fix the build/lint/typecheck errors before committing."
    } | ConvertTo-Json -Compress
    exit 0
} finally {
    Pop-Location
}
