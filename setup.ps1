#Requires -Version 5.1
<#
.SYNOPSIS
    SPADE Framework — Setup Script (Windows)

.DESCRIPTION
    Installs SPADE skills globally for all Claude Code sessions.

.EXAMPLE
    .\setup.ps1

.NOTES
    After running this, use /spade-onboard in Claude Code within any
    project to initialise SPADE files and fill in architecture docs.
#>

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Definition
$Version = '1.0.0'

# --- Output helpers ---

function Write-Header {
    Write-Host ''
    Write-Host ([char]0x2501 * 52) -ForegroundColor Blue
    Write-Host "  SPADE Framework v${Version}" -ForegroundColor Blue
    Write-Host '  A Human-AI Operating Model for Engineering Teams' -ForegroundColor Blue
    Write-Host ([char]0x2501 * 52) -ForegroundColor Blue
    Write-Host ''
}

function Write-OK   { param([string]$Msg) Write-Host "[OK] $Msg" -ForegroundColor Green }
function Write-Info  { param([string]$Msg) Write-Host " ->  $Msg" -ForegroundColor Blue }

function Copy-Always {
    param([string]$Src, [string]$Dest, [string]$Label)
    Copy-Item $Src $Dest -Force
    Write-OK "$Label installed"
}

# --- Main ---

Write-Header

$skillsDir = Join-Path $HOME '.claude\skills'
Write-Host "Installing SPADE skills globally to $skillsDir"
Write-Host ''
New-Item -Path $skillsDir -ItemType Directory -Force | Out-Null

$srcSkills = Join-Path $ScriptDir '.claude\skills'
foreach ($skillDir in (Get-ChildItem $srcSkills -Directory)) {
    $destDir = Join-Path $skillsDir $skillDir.Name
    if (-not (Test-Path $destDir)) { New-Item -Path $destDir -ItemType Directory -Force | Out-Null }
    Copy-Always (Join-Path $skillDir.FullName 'SKILL.md') (Join-Path $destDir 'SKILL.md') "Skill: $($skillDir.Name)"
}

Write-Host ''
Write-OK 'Global skills installed.'
Write-Host ''
Write-Host ([char]0x2501 * 52) -ForegroundColor Green
Write-Host '  SPADE installed successfully.' -ForegroundColor Green
Write-Host ([char]0x2501 * 52) -ForegroundColor Green
Write-Host ''
Write-Host 'Next steps:'
Write-Host ''
Write-Host '  1. Open Claude Code in any project'
Write-Host '  2. Run /spade-onboard to initialise SPADE and fill in architecture docs'
Write-Host '  3. Commit the generated files so your team gets SPADE automatically'
Write-Host ''
