#!/usr/bin/env pwsh
# Safety guard hook - blocks dangerous commands and protects critical paths
# Runs as preToolUse hook before any tool execution
$ErrorActionPreference = "Stop"

$inputJson = [Console]::In.ReadToEnd() | ConvertFrom-Json
$toolName = $inputJson.toolName
$toolArgs = $inputJson.toolArgs | ConvertFrom-Json -ErrorAction SilentlyContinue

switch ($toolName) {
    { $_ -in "bash", "shell" } {
        $command = $toolArgs.command
        if (-not $command) { exit 0 }

        # Block destructive system commands
        if ($command -match "rm\s+-rf\s+/|sudo\s+rm|mkfs|dd\s+if=|format\s+[A-Z]:") {
            @{ permissionDecision = "deny"; permissionDecisionReason = "Destructive system command blocked by safety guard" } |
                ConvertTo-Json -Compress
            exit 0
        }

        # Block SQL injection patterns
        if ($command -match "(?i)DROP\s+TABLE|DROP\s+DATABASE|TRUNCATE\s+TABLE|DELETE\s+FROM\s+\w+\s*;") {
            @{ permissionDecision = "deny"; permissionDecisionReason = "Destructive SQL command blocked by safety guard" } |
                ConvertTo-Json -Compress
            exit 0
        }

        # Block force pushes to protected branches
        if ($command -match "git\s+push\s+.*--force|git\s+push\s+-f") {
            if ($command -match "\s(main|develop|master)\b") {
                @{ permissionDecision = "deny"; permissionDecisionReason = "Force push to protected branch (main/develop) blocked by safety guard" } |
                    ConvertTo-Json -Compress
                exit 0
            }
        }

        # Block pushes directly to protected branches
        if ($command -match "git\s+push\s+origin\s+(main|develop|master)\b") {
            @{ permissionDecision = "deny"; permissionDecisionReason = "Direct push to protected branch blocked - use a feature branch and PR" } |
                ConvertTo-Json -Compress
            exit 0
        }
    }

    { $_ -in "edit", "create" } {
        $filePath = if ($toolArgs.path) { $toolArgs.path } elseif ($toolArgs.filePath) { $toolArgs.filePath } else { $null }
        if (-not $filePath) { exit 0 }

        # Protect CI/CD pipeline configs
        if ($filePath -match "(azurepipelines|\.azure-pipelines|\.github/workflows)/") {
            @{ permissionDecision = "deny"; permissionDecisionReason = "CI/CD pipeline files are protected - modify manually" } |
                ConvertTo-Json -Compress
            exit 0
        }

        # Protect package lock files
        if ($filePath -match "(package-lock\.json|yarn\.lock|pnpm-lock\.yaml)$") {
            @{ permissionDecision = "deny"; permissionDecisionReason = "Lock files should not be edited directly - run package manager commands instead" } |
                ConvertTo-Json -Compress
            exit 0
        }
    }
}

# Allow everything else
