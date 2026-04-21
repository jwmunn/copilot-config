<#
.SYNOPSIS
    Sets up copilot-config agents, prompts, and instructions in sibling repositories.
.DESCRIPTION
    Creates junctions from sibling repos' .github/{agents,prompts,instructions}
    folders to this repo's corresponding folders, making @research, /mslearn-ship-it,
    and custom instruction files available from any repo in the workspace.

    By default all three asset types are linked. Use -Assets to restrict.
.EXAMPLE
    .\setup-agents.ps1
    # Auto-discovers sibling repos, links agents + prompts + instructions
.EXAMPLE
    .\setup-agents.ps1 -TargetRepos "docs-ui", "feature-gap-wt"
    # Links specific repos only
.EXAMPLE
    .\setup-agents.ps1 -Assets agents,prompts
    # Skip instructions (e.g. if repos already have their own)
#>

param(
    [string[]]$TargetRepos = @(),
    [ValidateSet("agents", "prompts", "instructions")]
    [string[]]$Assets = @("agents", "prompts", "instructions"),
    [switch]$Force,
    [switch]$DryRun
)

$ErrorActionPreference = "Stop"
$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$githubSource = Join-Path $scriptDir ".github"
$parentDir = Split-Path -Parent $scriptDir

# Build list of asset subfolders that actually exist in source
$sourceFolders = @{}
foreach ($asset in $Assets) {
    $path = Join-Path $githubSource $asset
    if (Test-Path $path) {
        $sourceFolders[$asset] = $path
    } else {
        Write-Host "Source '$asset' not found at $path - skipping" -ForegroundColor DarkYellow
    }
}

if ($sourceFolders.Count -eq 0) {
    Write-Error "No asset folders found to link."
    exit 1
}

Write-Host "Copilot Repo Linker" -ForegroundColor Cyan
Write-Host "===================" -ForegroundColor Cyan
Write-Host "Source: $githubSource"
Write-Host "Assets: $($sourceFolders.Keys -join ', ')"
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

    # Ensure .github exists
    if (-not (Test-Path $githubDir)) {
        if ($DryRun) {
            Write-Host "[$repoName] Would create .github folder" -ForegroundColor Yellow
        } else {
            New-Item -ItemType Directory -Path $githubDir -Force | Out-Null
        }
    }

    foreach ($asset in $sourceFolders.Keys) {
        $sourcePath = $sourceFolders[$asset]
        $targetPath = Join-Path $githubDir $asset

        Write-Host "[$repoName/$asset] " -NoNewline

        # Already exists?
        if (Test-Path $targetPath) {
            $item = Get-Item $targetPath -Force

            # Junction already pointing at our source?
            if ($item.Attributes -band [System.IO.FileAttributes]::ReparsePoint) {
                $existingTarget = $item.Target
                if ($existingTarget -eq $sourcePath -or $existingTarget -eq "$sourcePath\") {
                    Write-Host "Already linked" -ForegroundColor DarkGray
                    $skipped++
                    continue
                }
            }

            # Has content - don't overwrite unless forced
            if (-not $Force) {
                $existingItems = Get-ChildItem $targetPath -ErrorAction SilentlyContinue
                if ($existingItems.Count -gt 0) {
                    Write-Host "Has existing content ($($existingItems.Count) items) - use -Force to replace" -ForegroundColor Yellow
                    $skipped++
                    continue
                }
            }

            # Remove existing folder
            if ($DryRun) {
                Write-Host "Would remove existing folder and create junction" -ForegroundColor Yellow
            } else {
                Remove-Item $targetPath -Recurse -Force
            }
        }

        # Create junction
        if ($DryRun) {
            Write-Host "Would link -> $sourcePath" -ForegroundColor Cyan
            $created++
        } else {
            try {
                New-Item -ItemType Junction -Path $targetPath -Target $sourcePath | Out-Null
                Write-Host "Linked -> $sourcePath" -ForegroundColor Green
                $created++
            } catch {
                Write-Host "Failed: $_" -ForegroundColor Red
                $errors++
            }
        }
    }
}

Write-Host ""
Write-Host "Summary: $created created, $skipped skipped, $errors errors" -ForegroundColor Cyan

if ($DryRun) {
    Write-Host "(Dry run - no changes made)" -ForegroundColor Yellow
}
