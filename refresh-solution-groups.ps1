#!/usr/bin/env pwsh
<#
.SYNOPSIS
    Refreshes solution group options in GitHub workflow files based on solution-groups.json
.DESCRIPTION
    This script reads the solution-groups.json file and updates the workflow_dispatch input options
    in ExportSolution.yml and DeploySolution.yml to match the current solution groups configuration.
.PARAMETER SolutionGroupsFile
    Path to the solution-groups.json file
.PARAMETER ExportWorkflowFile
    Path to the ExportSolution.yml workflow file
.PARAMETER DeployWorkflowFile
    Path to the DeploySolution.yml workflow file
.EXAMPLE
    .\refresh-solution-groups.ps1
.EXAMPLE
    .\refresh-solution-groups.ps1 -SolutionGroupsFile ".\SolutionGroups\solution-groups.json"
#>

param(
    [Parameter(Mandatory = $false)]
    [string]$SolutionGroupsFile = ".\SolutionGroups\solution-groups.json",
    
    [Parameter(Mandatory = $false)]
    [string]$ExportWorkflowFile = ".\.github\workflows\ExportSolution.yml",
    
    [Parameter(Mandatory = $false)]
    [string]$DeployWorkflowFile = ".\.github\workflows\DeploySolution.yml"
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Refresh Solution Groups" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan

# Verify files exist
if (-not (Test-Path $SolutionGroupsFile)) {
    Write-Error "Solution groups file not found: $SolutionGroupsFile"
    exit 1
}

if (-not (Test-Path $ExportWorkflowFile)) {
    Write-Error "Export workflow file not found: $ExportWorkflowFile"
    exit 1
}

if (-not (Test-Path $DeployWorkflowFile)) {
    Write-Error "Deploy workflow file not found: $DeployWorkflowFile"
    exit 1
}

Write-Host "Reading solution groups from: $SolutionGroupsFile" -ForegroundColor Green

# Read and parse solution-groups.json
$solutionGroups = Get-Content $SolutionGroupsFile -Raw | ConvertFrom-Json

# Build the options list
$options = @()
foreach ($groupProperty in $solutionGroups.PSObject.Properties) {
    $groupName = $groupProperty.Name
    $apps = $groupProperty.Value
    
    Write-Host "  Processing group: $groupName" -ForegroundColor Yellow
    
    for ($i = 0; $i -lt $apps.Count; $i++) {
        $appName = $apps[$i]
        $option = "$groupName -> $($i + 1). $appName"
        $options += $option
        Write-Host "    - $option" -ForegroundColor Gray
    }
}

Write-Host "`nGenerated $($options.Count) solution option(s)" -ForegroundColor Green

# Function to update workflow file
function Update-WorkflowFile {
    param(
        [string]$FilePath,
        [string[]]$Options
    )
    
    Write-Host "`nUpdating workflow file: $FilePath" -ForegroundColor Green
    
    $content = Get-Content $FilePath -Raw
    
    # Find the solution input section and replace the options
    # Pattern matches from solution: to the next top-level key (branch_name or environment)
    $pattern = "(?s)(solution:\s+description:\s+'Solution to (?:export|deploy)'\s+required:\s+true\s+type:\s+choice\s+options:\s*\r?\n)(?:\s+-\s+'[^']+'\s*\r?\n)+(\s+(?:branch_name|environment):)"
    
    # Build the replacement options block
    $optionsBlock = ""
    foreach ($option in $Options) {
        $optionsBlock += "          - '$option'`r`n"
    }
    
    $replacement = "`${1}$optionsBlock`${2}"
    
    $newContent = $content -replace $pattern, $replacement
    
    if ($content -eq $newContent) {
        Write-Host "  No changes needed" -ForegroundColor Yellow
        return $false
    }
    
    # Write back to file with UTF8 encoding without BOM
    $utf8NoBom = New-Object System.Text.UTF8Encoding $false
    [System.IO.File]::WriteAllText($FilePath, $newContent, $utf8NoBom)
    Write-Host "  Updated successfully" -ForegroundColor Green
    return $true
}

# Update both workflow files
$exportChanged = Update-WorkflowFile -FilePath $ExportWorkflowFile -Options $options
$deployChanged = Update-WorkflowFile -FilePath $DeployWorkflowFile -Options $options

Write-Host "`n========================================" -ForegroundColor Cyan
Write-Host "Summary" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Export workflow changed: $exportChanged" -ForegroundColor $(if ($exportChanged) { "Green" } else { "Gray" })
Write-Host "Deploy workflow changed: $deployChanged" -ForegroundColor $(if ($deployChanged) { "Green" } else { "Gray" })

if ($exportChanged -or $deployChanged) {
    Write-Host "`n✓ Workflow files updated successfully!" -ForegroundColor Green
    exit 0
} else {
    Write-Host "`n✓ No changes required - files are already up to date" -ForegroundColor Yellow
    exit 0
}
