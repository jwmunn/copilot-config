#!/usr/bin/env pwsh
# session-end-learnings.ps1: Logs session end and writes a marker for learnings extraction
# Runs as sessionEnd hook
# The actual AI-driven analysis is performed by the session-learnings skill/prompt
$ErrorActionPreference = "Stop"

$inputJson = [Console]::In.ReadToEnd() | ConvertFrom-Json

$timestamp = Get-Date -Format "o"
$artifactsDir = "copilot-config/agent-artifacts/learnings"

# Create learnings directory if it doesn't exist
if (-not (Test-Path $artifactsDir)) {
    New-Item -ItemType Directory -Path $artifactsDir -Force | Out-Null
}

# Extract session metadata
$cwd = if ($inputJson.cwd) { $inputJson.cwd } else { Get-Location }

try {
    $repoRoot = git -C $cwd rev-parse --show-toplevel 2>$null
    $repoName = Split-Path $repoRoot -Leaf
} catch {
    $repoName = Split-Path $cwd -Leaf
}

try {
    $branch = git -C $cwd rev-parse --abbrev-ref HEAD 2>$null
} catch {
    $branch = "unknown"
}

try {
    $commitHash = git -C $cwd rev-parse --short HEAD 2>$null
} catch {
    $commitHash = "unknown"
}

$sessionMeta = @{
    timestamp  = $timestamp
    cwd        = $cwd.ToString()
    repoName   = $repoName
    branch     = $branch
    commitHash = $commitHash
} | ConvertTo-Json -Compress

# Write session-end marker with metadata
$markerFile = Join-Path $artifactsDir ".session-end-marker.json"
$sessionMeta | Out-File -FilePath $markerFile -Encoding utf8 -Force

# Append to session log
"Session ended at $timestamp" | Out-File -FilePath (Join-Path $artifactsDir "session-end.log") -Append -Encoding utf8

exit 0
