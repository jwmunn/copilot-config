<#
.SYNOPSIS
    Makes copilot-config skills, prompts, and agents available in every Copilot CLI session.
.DESCRIPTION
    Creates junctions from the user's ~/.copilot directory to this repo's .github
    subfolders so Copilot CLI loads them globally, regardless of cwd.

    Layout created:
      ~/.copilot/skills/<skill-name>        -> copilot-config/.github/skills/<skill-name>
      ~/.copilot/.github/prompts            -> copilot-config/.github/prompts
      ~/.copilot/.github/agents             -> copilot-config/.github/agents
      ~/.copilot/.github/instructions       -> copilot-config/.github/instructions

    Skills are individually junctioned per-skill so user-level skills added later
    (e.g. ado-code-search) coexist without conflict. Prompts/agents are junctioned
    as whole directories since the CLI walks the git root for .github/ folders and
    %USERPROFILE% acts as a stable fallback when sessions start outside a repo.

    This does NOT touch ~/.copilot/copilot-instructions.md. Manage that separately.
.EXAMPLE
    .\setup-global.ps1
    # Apply all links
.EXAMPLE
    .\setup-global.ps1 -DryRun
    # Preview what would change
.EXAMPLE
    .\setup-global.ps1 -Force
    # Replace existing non-junction folders (will delete their contents!)
#>

param(
    [switch]$Force,
    [switch]$DryRun
)

$ErrorActionPreference = "Stop"
$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$sourceRoot = Join-Path $scriptDir ".github"

if (-not (Test-Path $sourceRoot)) {
    Write-Error "Source .github not found: $sourceRoot"
    exit 1
}

$userCopilot = Join-Path $env:USERPROFILE ".copilot"
$userSkills  = Join-Path $userCopilot "skills"

Write-Host "Copilot Global Setup" -ForegroundColor Cyan
Write-Host "====================" -ForegroundColor Cyan
Write-Host "Source: $sourceRoot"
Write-Host "Target: $userCopilot"
if ($DryRun) { Write-Host "(DRY RUN - no changes)" -ForegroundColor Yellow }
Write-Host ""

$created = 0; $skipped = 0; $errors = 0

function Ensure-Directory($path) {
    if (-not (Test-Path $path)) {
        if ($DryRun) {
            Write-Host "  Would create directory $path" -ForegroundColor DarkGray
        } else {
            New-Item -ItemType Directory -Path $path -Force | Out-Null
        }
    }
}

function Link-Junction {
    param(
        [string]$LinkPath,
        [string]$TargetPath,
        [string]$Label
    )

    Write-Host "[$Label] " -NoNewline

    if (-not (Test-Path $TargetPath)) {
        Write-Host "Source missing: $TargetPath" -ForegroundColor Yellow
        $script:skipped++
        return
    }

    if (Test-Path $LinkPath) {
        $item = Get-Item $LinkPath -Force
        $isJunction = $item.Attributes -band [System.IO.FileAttributes]::ReparsePoint

        if ($isJunction) {
            $existingTarget = $item.Target
            if ($existingTarget -eq $TargetPath -or $existingTarget -eq "$TargetPath\") {
                Write-Host "Already linked" -ForegroundColor DarkGray
                $script:skipped++
                return
            }
            if (-not $Force) {
                Write-Host "Junction points elsewhere ($existingTarget) - use -Force to replace" -ForegroundColor Yellow
                $script:skipped++
                return
            }
        } elseif (-not $Force) {
            Write-Host "Exists and is not a junction - use -Force to replace" -ForegroundColor Yellow
            $script:skipped++
            return
        }

        if ($DryRun) {
            Write-Host "Would remove existing and re-link" -ForegroundColor Cyan
        } else {
            Remove-Item $LinkPath -Recurse -Force
        }
    }

    if ($DryRun) {
        Write-Host "Would link -> $TargetPath" -ForegroundColor Cyan
        $script:created++
        return
    }

    try {
        # Ensure parent directory exists
        $parent = Split-Path -Parent $LinkPath
        if (-not (Test-Path $parent)) {
            New-Item -ItemType Directory -Path $parent -Force | Out-Null
        }
        New-Item -ItemType Junction -Path $LinkPath -Target $TargetPath | Out-Null
        Write-Host "Linked -> $TargetPath" -ForegroundColor Green
        $script:created++
    } catch {
        Write-Host "Failed: $_" -ForegroundColor Red
        $script:errors++
    }
}

# --- Ensure target parent dirs exist ---
Ensure-Directory $userCopilot
Ensure-Directory $userSkills

# --- Skills: one junction per skill directory ---
$skillsSource = Join-Path $sourceRoot "skills"
if (Test-Path $skillsSource) {
    Write-Host "--- Skills ---" -ForegroundColor Cyan
    Get-ChildItem $skillsSource -Directory | ForEach-Object {
        Link-Junction `
            -LinkPath (Join-Path $userSkills $_.Name) `
            -TargetPath $_.FullName `
            -Label "skill:$($_.Name)"
    }
    Write-Host ""
}

# --- Prompts, Agents, Instructions: link into sibling repos via setup-agents.ps1 ---
# Copilot CLI does NOT load prompts/agents/instructions from ~/.copilot/.github/.
# Skills are the only asset type auto-loaded from ~/.copilot/ (per /help discovery table).
# For prompts/agents/instructions, use setup-agents.ps1 to link into each sibling repo.
Write-Host "--- Prompts / Agents / Instructions ---" -ForegroundColor Cyan
Write-Host "Not linked at user level (not supported by Copilot CLI)." -ForegroundColor DarkGray
Write-Host "Run: .\setup-agents.ps1   to link these into sibling repos." -ForegroundColor DarkGray
Write-Host ""

Write-Host "Summary: $created created, $skipped skipped, $errors errors" -ForegroundColor Cyan

if (-not $DryRun -and $created -gt 0) {
    Write-Host ""
    Write-Host "Tip: restart any active Copilot CLI sessions, then run /env to verify." -ForegroundColor DarkGray
}
