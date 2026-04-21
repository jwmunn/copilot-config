<#
.SYNOPSIS
    Consolidates .github/prompts/*.prompt.md into .github/skills/mslearn-<name>/SKILL.md
    so mslearn workflows are discoverable as CLI skills (prompts aren't loaded by Copilot CLI).
.DESCRIPTION
    - Renames existing skill folders to add the 'mslearn-' prefix.
    - For prompts without a matching skill, creates a new skill folder and generates a
      SKILL.md from the prompt (stripping VS-Code-only frontmatter like agent: and model:).
    - Leaves the original prompt files in place for VS Code users.
.EXAMPLE
    .\migrate-prompts-to-skills.ps1 -DryRun
    .\migrate-prompts-to-skills.ps1
#>

param(
    [switch]$DryRun,
    [switch]$Force
)

$ErrorActionPreference = "Stop"
$root = Split-Path -Parent $MyInvocation.MyCommand.Path
$skillsDir = Join-Path $root ".github\skills"
$promptsDir = Join-Path $root ".github\prompts"

if (-not (Test-Path $promptsDir)) { Write-Error "Prompts not found"; exit 1 }
if (-not (Test-Path $skillsDir)) { New-Item -ItemType Directory -Path $skillsDir | Out-Null }

$renamed = 0; $created = 0; $skipped = 0

Get-ChildItem $promptsDir -Filter "*.prompt.md" | ForEach-Object {
    $promptPath = $_.FullName
    $baseName = $_.BaseName -replace '\.prompt$', ''      # e.g. "mslearn-ship-it"
    $shortName = $baseName -replace '^mslearn-', ''        # e.g. "ship-it"

    $prefixedDir = Join-Path $skillsDir $baseName
    $unprefixedDir = Join-Path $skillsDir $shortName

    # Case 1: already migrated
    if (Test-Path (Join-Path $prefixedDir "SKILL.md")) {
        Write-Host "[skip ] $baseName (already a skill)" -ForegroundColor DarkGray
        $skipped++
        return
    }

    # Case 2: existing un-prefixed skill folder — rename it
    if (Test-Path (Join-Path $unprefixedDir "SKILL.md")) {
        Write-Host "[rename] $shortName -> $baseName" -ForegroundColor Cyan
        if (-not $DryRun) {
            Rename-Item -Path $unprefixedDir -NewName $baseName -Force
        }
        $renamed++
        return
    }

    # Case 3: no existing skill — convert prompt to skill
    Write-Host "[create] $baseName (from prompt)" -ForegroundColor Green
    if ($DryRun) { $created++; return }

    New-Item -ItemType Directory -Path $prefixedDir -Force | Out-Null

    $raw = Get-Content $promptPath -Raw

    # Strip VS Code-only frontmatter keys (agent, model); keep description & body.
    # Frontmatter is the first --- block at top of file.
    $new = $raw
    if ($raw -match '^(?s)---\r?\n(.*?)\r?\n---\r?\n(.*)$') {
        $frontmatter = $Matches[1]
        $body = $Matches[2]

        $keptLines = $frontmatter -split "`r?`n" | Where-Object {
            $_ -notmatch '^\s*(agent|model)\s*:'
        }

        $new = "---`n" + ($keptLines -join "`n") + "`n---`n" + $body
    }

    Set-Content -Path (Join-Path $prefixedDir "SKILL.md") -Value $new -Encoding UTF8
    $created++
}

Write-Host ""
Write-Host "Summary: $renamed renamed, $created created, $skipped skipped" -ForegroundColor Cyan
if ($DryRun) { Write-Host "(Dry run - no changes made)" -ForegroundColor Yellow }
