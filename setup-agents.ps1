<# 
.SYNOPSIS
    Sets up copilot-config agents in sibling repositories.
.DESCRIPTION
    Creates junctions from sibling repos' .github/agents folders to this repo's agents,
    making @research, @planning, etc. available from any repo in the workspace.
.EXAMPLE
    .\setup-agents.ps1
    # Auto-discovers and links all sibling repos
.EXAMPLE
    .\setup-agents.ps1 -TargetRepos "docs-ui", "feature-gap-wt"
    # Links specific repos only
#>

param(
    [string[]]$TargetRepos = @(),
    [switch]$Force,
    [switch]$DryRun
)

$ErrorActionPreference = "Stop"
$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$agentsSource = Join-Path $scriptDir ".github\agents"
$parentDir = Split-Path -Parent $scriptDir

if (-not (Test-Path $agentsSource)) {
    Write-Error "Agents source not found: $agentsSource"
    exit 1
}

Write-Host "Copilot Agents Setup" -ForegroundColor Cyan
Write-Host "===================" -ForegroundColor Cyan
Write-Host "Source: $agentsSource"
Write-Host ""

# Discover sibling repos if none specified
if ($TargetRepos.Count -eq 0) {
    $siblings = Get-ChildItem -Path $parentDir -Directory | Where-Object {
        $_.Name -ne "copilot-config" -and (Test-Path (Join-Path $_.FullName ".git"))
    }
    $TargetRepos = $siblings | ForEach-Object { $_.FullName }
} else {
    # Resolve relative paths
    $TargetRepos = $TargetRepos | ForEach-Object {
        if ([System.IO.Path]::IsPathRooted($_)) { $_ }
        else { Join-Path $parentDir $_ }
    }
}

if ($TargetRepos.Count -eq 0) {
    Write-Host "No sibling repos found." -ForegroundColor Yellow
    exit 0
}

Write-Host "Found $($TargetRepos.Count) repos to configure:" -ForegroundColor Green
$TargetRepos | ForEach-Object { Write-Host "  - $(Split-Path -Leaf $_)" }
Write-Host ""

$created = 0
$skipped = 0
$errors = 0

foreach ($repo in $TargetRepos) {
    $repoName = Split-Path -Leaf $repo
    $githubDir = Join-Path $repo ".github"
    $agentsTarget = Join-Path $githubDir "agents"
    
    Write-Host "[$repoName] " -NoNewline
    
    # Ensure .github exists
    if (-not (Test-Path $githubDir)) {
        if ($DryRun) {
            Write-Host "Would create .github folder" -ForegroundColor Yellow
        } else {
            New-Item -ItemType Directory -Path $githubDir -Force | Out-Null
        }
    }
    
    # Check if agents folder already exists
    if (Test-Path $agentsTarget) {
        $item = Get-Item $agentsTarget
        
        # Already a junction pointing to our agents?
        if ($item.Attributes -band [System.IO.FileAttributes]::ReparsePoint) {
            $target = (Get-Item $agentsTarget).Target
            if ($target -eq $agentsSource) {
                Write-Host "Already linked" -ForegroundColor DarkGray
                $skipped++
                continue
            }
        }
        
        # Has content - don't overwrite unless forced
        if (-not $Force) {
            $existingAgents = Get-ChildItem $agentsTarget -Filter "*.agent.md" -ErrorAction SilentlyContinue
            if ($existingAgents.Count -gt 0) {
                Write-Host "Has existing agents ($($existingAgents.Count) files) - use -Force to replace" -ForegroundColor Yellow
                $skipped++
                continue
            }
        }
        
        # Remove existing folder
        if ($DryRun) {
            Write-Host "Would remove existing folder and create junction" -ForegroundColor Yellow
        } else {
            Remove-Item $agentsTarget -Recurse -Force
        }
    }
    
    # Create junction
    if ($DryRun) {
        Write-Host "Would create junction" -ForegroundColor Cyan
        $created++
    } else {
        try {
            New-Item -ItemType Junction -Path $agentsTarget -Target $agentsSource | Out-Null
            Write-Host "Junction created" -ForegroundColor Green
            $created++
        } catch {
            Write-Host "Failed: $_" -ForegroundColor Red
            $errors++
        }
    }
}

Write-Host ""
Write-Host "Summary: $created created, $skipped skipped, $errors errors" -ForegroundColor Cyan

if ($DryRun) {
    Write-Host "(Dry run - no changes made)" -ForegroundColor Yellow
}
