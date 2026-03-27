# run-devbox-job.ps1
# Unattended job runner for Dev Box delegation workflow.
# Launched as a detached process on the Dev Box by the delegate-devbox skill.
#
# Parameters:
#   -JobPath    : Absolute path to the job artifact markdown file
#   -ConfigPath : Absolute path to workflow-config.json
#
# Prerequisites:
#   - Azure CLI with azure-devops extension
#   - Git credential manager configured
#   - Copilot CLI or coding agent available
#   - copilot-config cloned at {repoBasePath}/copilot-config
#   - Target repo will be auto-cloned if missing

param(
    [Parameter(Mandatory = $true)]
    [string]$JobPath,

    [Parameter(Mandatory = $true)]
    [string]$ConfigPath
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

# --- Helpers ---

function Write-Log {
    param([string]$Message)
    $timestamp = Get-Date -Format 'yyyy-MM-dd HH:mm:ss'
    $logLine = "[$timestamp] $Message"
    Write-Output $logLine
    Add-Content -Path $script:LogPath -Value $logLine
}

function Update-StatusFile {
    param([string]$Status, [hashtable]$Extra = @{})
    $statusObj = @{
        jobId            = $script:JobId
        status           = $Status
        updatedAt        = (Get-Date -Format 'o')
        repo             = $script:Repo
        branch           = $script:Branch
        prUrl            = $script:PrUrl
        completionPath   = $script:CompletionPath
    }
    foreach ($key in $Extra.Keys) {
        $statusObj[$key] = $Extra[$key]
    }
    $statusObj | ConvertTo-Json -Depth 4 | Set-Content -Path $script:StatusPath -Encoding UTF8
}

# --- Parse job artifact ---

$jobContent = Get-Content -Path $JobPath -Raw
$script:JobId = [System.IO.Path]::GetFileNameWithoutExtension($JobPath) -replace '-job$', ''

# Extract YAML frontmatter values
function Get-FrontmatterValue {
    param([string]$Content, [string]$Key)
    if ($Content -match "(?m)^${Key}:\s*(.+)$") { return $Matches[1].Trim() }
    return $null
}

$script:Repo = Get-FrontmatterValue -Content $jobContent -Key 'repo'
$script:Branch = Get-FrontmatterValue -Content $jobContent -Key 'branch'
$script:BaseRef = Get-FrontmatterValue -Content $jobContent -Key 'baseRef'
$ticket = Get-FrontmatterValue -Content $jobContent -Key 'ticket'

# Read config for repo path base and clone URL
$config = Get-Content -Path $ConfigPath -Raw | ConvertFrom-Json
$repoBasePath = $config.devBox.repoBasePath
$repoPath = Join-Path $repoBasePath $script:Repo
$configRepoPath = Join-Path $repoBasePath 'copilot-config'

# Clone repo if it doesn't exist on this Dev Box
if (-not (Test-Path $repoPath)) {
    Write-Output "Repo not found at $repoPath — cloning..."
    $cloneUrl = $config.devBox.cloneUrlPattern -replace '\{repoName\}', $script:Repo
    git clone $cloneUrl $repoPath 2>&1
    if ($LASTEXITCODE -ne 0) {
        throw "Failed to clone repo from $cloneUrl"
    }
}

# Determine ticket directory
$ticketDir = if ($ticket -and $ticket -ne 'null') { $ticket } else { 'general' }
$dateStr = Get-Date -Format 'yyyy-MM-dd'
$timeStr = Get-Date -Format 'HH-mm-ss'
$description = ($script:JobId -replace "^\d{4}-\d{2}-\d{2}_\d{2}-\d{2}-\d{2}_[^_]+_", '')

# Paths
$artifactBase = Join-Path $configRepoPath "agent-artifacts"
$script:CompletionPath = Join-Path $artifactBase "handoffs/$ticketDir/${dateStr}_${timeStr}_${ticket}_${description}-devbox-complete.md"
$script:StatusPath = "$JobPath" -replace '\.md$', '-status.json'
$script:LogPath = "$JobPath" -replace '\.md$', '.log'
$script:PrUrl = $null

# --- Execute ---

try {
    Write-Log "Starting Dev Box job: $($script:JobId)"
    Update-StatusFile -Status 'running'

    # 1. Navigate to repo and fetch
    Write-Log "Navigating to $repoPath"
    Set-Location -Path $repoPath
    git fetch origin 2>&1 | ForEach-Object { Write-Log $_ }

    # 2. Create working branch
    Write-Log "Creating branch $($script:Branch) from origin/$($script:BaseRef)"
    git checkout -b $script:Branch "origin/$($script:BaseRef)" 2>&1 | ForEach-Object { Write-Log $_ }

    # 3. Extract task prompt from job artifact
    $taskPrompt = ''
    $inTaskSection = $false
    foreach ($line in ($jobContent -split "`n")) {
        if ($line -match '^## Task Prompt') { $inTaskSection = $true; continue }
        if ($inTaskSection -and $line -match '^## ') { break }
        if ($inTaskSection) { $taskPrompt += "$line`n" }
    }
    $taskPrompt = $taskPrompt.Trim()
    Write-Log "Task prompt extracted ($(($taskPrompt -split "`n").Count) lines)"

    # 4. Run implementation via Copilot coding agent
    Write-Log "Starting Copilot coding agent..."
    $promptFile = Join-Path $env:TEMP "devbox-job-prompt.md"
    Set-Content -Path $promptFile -Value $taskPrompt -Encoding UTF8

    # Use gh copilot or copilot CLI if available; fall back to copilot-agent
    if (Get-Command 'copilot' -ErrorAction SilentlyContinue) {
        copilot agent --prompt-file $promptFile 2>&1 | ForEach-Object { Write-Log $_ }
    } elseif (Get-Command 'gh' -ErrorAction SilentlyContinue) {
        gh copilot suggest --prompt-file $promptFile 2>&1 | ForEach-Object { Write-Log $_ }
    } else {
        Write-Log "WARNING: No Copilot CLI found. Manual implementation required."
        Update-StatusFile -Status 'failed' -Extra @{ error = 'No Copilot CLI available on Dev Box' }
        exit 1
    }

    # 5. Run validation
    Write-Log "Running validation..."
    $repoConfig = $config.repositories.PSObject.Properties | Where-Object { $_.Name -eq $script:Repo } | Select-Object -First 1
    if ($repoConfig -and $repoConfig.Value.preCommitCommand) {
        $cmd = $repoConfig.Value.preCommitCommand
        Write-Log "Validation command: $cmd"
        Invoke-Expression $cmd 2>&1 | ForEach-Object { Write-Log $_ }
        if ($LASTEXITCODE -ne 0) {
            Write-Log "Validation failed with exit code $LASTEXITCODE"
            Update-StatusFile -Status 'validation-failed'
            # Continue to commit anyway so work is not lost, but record failure
        }
    }

    # 6. Commit and push
    Write-Log "Committing and pushing..."
    git add -A 2>&1 | ForEach-Object { Write-Log $_ }

    $commitMsg = "feat: devbox delegated task - $description"
    git commit -m $commitMsg 2>&1 | ForEach-Object { Write-Log $_ }
    git push -u origin $script:Branch 2>&1 | ForEach-Object { Write-Log $_ }

    # 7. Create ADO PR
    Write-Log "Creating pull request..."
    $prOutput = az repos pr create `
        --repository $script:Repo `
        --source-branch $script:Branch `
        --target-branch $script:BaseRef `
        --title $commitMsg `
        --description "Delegated Dev Box implementation for $ticket. See job artifact: $JobPath" `
        --auto-complete false `
        --output json 2>&1

    $prJson = $prOutput | ConvertFrom-Json -ErrorAction SilentlyContinue
    if ($prJson -and $prJson.url) {
        $script:PrUrl = $prJson.url
        Write-Log "PR created: $($script:PrUrl)"
    } else {
        Write-Log "PR creation output: $prOutput"
    }

    # 8. Write completion handoff
    Write-Log "Writing completion handoff to $($script:CompletionPath)"
    $completionDir = Split-Path $script:CompletionPath -Parent
    if (-not (Test-Path $completionDir)) { New-Item -ItemType Directory -Path $completionDir -Force | Out-Null }

    $completionContent = @"
---
date: $(Get-Date -Format 'o')
type: devbox-completion
status: completed
repo: $($script:Repo)
branch: $($script:Branch)
prUrl: $($script:PrUrl)
sourceJob: $JobPath
---

# Dev Box Completion: $description

## Result
- **Status**: Completed
- **Branch**: ``$($script:Branch)``
- **PR**: $($script:PrUrl)
- **Validation**: $(if ($LASTEXITCODE -eq 0) { 'Passed' } else { 'Failed (changes committed anyway)' })

## Task Prompt
$taskPrompt

## Log
See full log at: ``$($script:LogPath)``

## Next Steps
1. Review the PR
2. Run ``/mslearn-resume-handoff $($script:CompletionPath)`` to continue from this point
"@
    Set-Content -Path $script:CompletionPath -Value $completionContent -Encoding UTF8

    Update-StatusFile -Status 'completed'
    Write-Log "Job completed successfully. Completion handoff written to: $($script:CompletionPath)"
}
catch {
    Write-Log "ERROR: $_"
    Update-StatusFile -Status 'failed' -Extra @{ error = $_.ToString() }
    exit 1
}
