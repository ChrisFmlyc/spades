#Requires -Version 5.1
<#
.SYNOPSIS
    SPADE Framework — Setup Script (Windows)

.DESCRIPTION
    Installs SPADE into a target project repository.

.PARAMETER Path
    Target project directory. Defaults to interactive prompt.

.PARAMETER Global
    Installs skills to ~/.claude/skills/ for all projects.

.PARAMETER Upgrade
    Upgrade an existing installation at the specified path.

.PARAMETER Remove
    Remove SPADE sections from the project at the specified path.

.EXAMPLE
    .\setup.ps1 C:\Projects\my-app
    .\setup.ps1 -Global
    .\setup.ps1 -Upgrade C:\Projects\my-app
    .\setup.ps1 -Remove C:\Projects\my-app
#>

[CmdletBinding(DefaultParameterSetName = 'Install')]
param(
    [Parameter(ParameterSetName = 'Install', Position = 0)]
    [Parameter(ParameterSetName = 'Upgrade', Mandatory)]
    [Parameter(ParameterSetName = 'Remove', Mandatory)]
    [string]$Path,

    [Parameter(ParameterSetName = 'Global')]
    [switch]$Global,

    [Parameter(ParameterSetName = 'Upgrade')]
    [switch]$Upgrade,

    [Parameter(ParameterSetName = 'Remove')]
    [switch]$Remove
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Definition
$Version = '1.0.0'

$MarkerStart = "<!-- SPADE-FRAMEWORK-START v${Version} -->"
$MarkerStartPattern = '<!-- SPADE-FRAMEWORK-START'
$MarkerEnd = '<!-- SPADE-FRAMEWORK-END -->'

# --- Output helpers ---

function Write-Header {
    Write-Host ''
    Write-Host ([char]0x2501 * 52) -ForegroundColor Blue
    Write-Host "  SPADE Framework v${Version}" -ForegroundColor Blue
    Write-Host '  A Human-AI Operating Model for Engineering Teams' -ForegroundColor Blue
    Write-Host ([char]0x2501 * 52) -ForegroundColor Blue
    Write-Host ''
}

function Write-OK    { param([string]$Msg) Write-Host "[OK] $Msg" -ForegroundColor Green }
function Write-Warn  { param([string]$Msg) Write-Host "[!!] $Msg" -ForegroundColor Yellow }
function Write-Info  { param([string]$Msg) Write-Host " ->  $Msg" -ForegroundColor Blue }
function Write-Err   { param([string]$Msg) Write-Host "[XX] $Msg" -ForegroundColor Red }

# --- Core helpers ---

function Test-SpadeSection {
    param([string]$FilePath)
    if (-not (Test-Path $FilePath)) { return $false }
    (Get-Content $FilePath -Raw) -match [regex]::Escape($MarkerStartPattern)
}

function Set-SpadeSection {
    <#
    .SYNOPSIS
        Inject or replace a SPADE section in an existing file.
    #>
    param(
        [string]$SourceFile,
        [string]$TargetFile,
        [string]$Label
    )

    $sectionContent = Get-Content $SourceFile -Raw
    $markedContent = "${MarkerStart}`n${sectionContent}`n${MarkerEnd}"

    if (-not (Test-Path $TargetFile)) {
        Set-Content -Path $TargetFile -Value $markedContent -NoNewline
        Write-OK "$Label created (new file)"
        return
    }

    if (Test-SpadeSection $TargetFile) {
        $existing = Get-Content $TargetFile -Raw
        $pattern = "(?s)$([regex]::Escape($MarkerStartPattern)).*?$([regex]::Escape($MarkerEnd))"
        $updated = [regex]::Replace($existing, $pattern, $markedContent, 'Singleline')
        Set-Content -Path $TargetFile -Value $updated -NoNewline
        Write-OK "$Label updated (SPADE section replaced, your content preserved)"
        return
    }

    # No existing section — append
    Add-Content -Path $TargetFile -Value "`n$markedContent"
    Write-OK "$Label augmented (SPADE section appended to existing file)"
}

function Remove-SpadeSection {
    param(
        [string]$TargetFile,
        [string]$Label
    )

    if (-not (Test-Path $TargetFile)) { return }

    if (-not (Test-SpadeSection $TargetFile)) {
        Write-Warn "$Label has no SPADE section, skipping"
        return
    }

    $existing = Get-Content $TargetFile -Raw
    $pattern = "(?s)\r?\n?$([regex]::Escape($MarkerStartPattern)).*?$([regex]::Escape($MarkerEnd))\r?\n?"
    $cleaned = [regex]::Replace($existing, $pattern, '', 'Singleline')

    if ([string]::IsNullOrWhiteSpace($cleaned)) {
        Remove-Item $TargetFile -Force
        Write-OK "$Label removed (file was SPADE-only)"
    }
    else {
        Set-Content -Path $TargetFile -Value $cleaned -NoNewline
        Write-OK "$Label cleaned (SPADE section removed, your content preserved)"
    }
}

function Copy-IfMissing {
    param([string]$Src, [string]$Dest, [string]$Label)

    if (Test-Path $Dest) {
        Write-Warn "$Label already exists, skipping (won't overwrite)"
    }
    else {
        Copy-Item $Src $Dest
        Write-OK "$Label created"
    }
}

function Copy-Always {
    param([string]$Src, [string]$Dest, [string]$Label)
    Copy-Item $Src $Dest -Force
    Write-OK "$Label installed"
}

# --- Install logic ---

function Test-LooksLikeProject {
    param([string]$Dir)
    $markers = @(
        '.git', 'package.json', 'Cargo.toml', 'go.mod', 'pyproject.toml',
        'setup.py', 'Gemfile', 'pom.xml', 'build.gradle', 'Makefile', 'src'
    )
    foreach ($m in $markers) {
        if (Test-Path (Join-Path $Dir $m)) { return $true }
    }
    # Check for .sln / .csproj
    if (Get-ChildItem $Dir -Filter '*.sln' -ErrorAction SilentlyContinue) { return $true }
    if (Get-ChildItem $Dir -Filter '*.csproj' -ErrorAction SilentlyContinue) { return $true }
    return $false
}

function Install-ToProject {
    param([string]$Target)

    if (-not (Test-Path $Target -PathType Container)) {
        Write-Err "Directory does not exist: $Target"
        exit 1
    }

    $Target = (Resolve-Path $Target).Path

    # Safety check: warn if this doesn't look like a project root
    if (-not (Test-LooksLikeProject $Target)) {
        Write-Warn 'This directory does not look like a project root:'
        Write-Warn "  $Target"
        Write-Warn 'No .git, package.json, go.mod, Cargo.toml, src\, or similar found.'
        Write-Host ''
        $confirm = Read-Host 'Install SPADE here anyway? [y/N]'
        if ($confirm -notmatch '^[Yy]$') {
            Write-Info 'Aborted. cd into your project directory first, then run: & $HOME\.spade\setup.ps1 .'
            exit 0
        }
    }

    Write-Host "Installing SPADE into: $Target"
    Write-Host ''

    # AGENTS.md and CLAUDE.md: inject or augment
    Write-Host 'Configuring framework files...'
    Set-SpadeSection (Join-Path $ScriptDir 'fragments\AGENTS-section.md') (Join-Path $Target 'AGENTS.md') 'AGENTS.md'
    Set-SpadeSection (Join-Path $ScriptDir 'fragments\CLAUDE-section.md') (Join-Path $Target 'CLAUDE.md') 'CLAUDE.md'

    Write-Host ''

    # Skills: always overwrite
    Write-Host 'Installing skills...'
    $skillsRoot = Join-Path $ScriptDir '.claude\skills'
    foreach ($skillDir in (Get-ChildItem $skillsRoot -Directory)) {
        $destDir = Join-Path $Target ".claude\skills\$($skillDir.Name)"
        if (-not (Test-Path $destDir)) { New-Item -Path $destDir -ItemType Directory -Force | Out-Null }
        Copy-Always (Join-Path $skillDir.FullName 'SKILL.md') (Join-Path $destDir 'SKILL.md') "Skill: $($skillDir.Name)"
    }

    Write-Host ''

    # Architecture templates: never overwrite
    Write-Host 'Setting up architecture templates...'
    Copy-IfMissing (Join-Path $ScriptDir 'ARCHITECTURE.md') (Join-Path $Target 'ARCHITECTURE.md') 'ARCHITECTURE.md'
    Copy-IfMissing (Join-Path $ScriptDir 'PATTERNS.md')      (Join-Path $Target 'PATTERNS.md')      'PATTERNS.md'
    Copy-IfMissing (Join-Path $ScriptDir 'ANTI-PATTERNS.md') (Join-Path $Target 'ANTI-PATTERNS.md') 'ANTI-PATTERNS.md'

    # Examples and docs
    $examplesDir = Join-Path $Target '.spade\examples'
    if (-not (Test-Path $examplesDir)) {
        New-Item -Path $examplesDir -ItemType Directory -Force | Out-Null
        $srcExamples = Join-Path $ScriptDir 'examples'
        if (Test-Path $srcExamples) {
            Get-ChildItem (Join-Path $srcExamples '*.md') | ForEach-Object {
                Copy-Item $_.FullName $examplesDir
            }
        }
        Write-OK 'Example templates installed to .spade\examples\'
    }
    else {
        Write-Warn '.spade\examples\ already exists, skipping'
    }

    $docsDir = Join-Path $Target '.spade\docs'
    New-Item -Path $docsDir -ItemType Directory -Force | Out-Null
    $srcDocs = Join-Path $ScriptDir 'docs'
    if (Test-Path $srcDocs) {
        Get-ChildItem (Join-Path $srcDocs '*.md') | ForEach-Object {
            Copy-Item $_.FullName $docsDir -Force
        }
    }

    # Version metadata
    $spadeMeta = Join-Path $Target '.spade'
    New-Item -Path $spadeMeta -ItemType Directory -Force | Out-Null
    $versionFile = Join-Path $spadeMeta 'version'
    $timestamp = (Get-Date).ToUniversalTime().ToString('yyyy-MM-ddTHH:mm:ssZ')
    @"
spade_version=$Version
installed_at=$timestamp
source=$ScriptDir
"@ | Set-Content $versionFile
    Write-OK 'Version metadata recorded'

    Write-Host ''
    Write-Host ([char]0x2501 * 52) -ForegroundColor Green
    Write-Host '  SPADE installed successfully.' -ForegroundColor Green
    Write-Host ([char]0x2501 * 52) -ForegroundColor Green
    Write-Host ''
    Write-Host 'Next steps:'
    Write-Host ''
    Write-Host '  1. Run /spade-onboard in Claude Code to fill in architecture docs'
    Write-Host '  2. Start using SPADE: /spade-scope, /spade-plan, /spade-approve'
    Write-Host '  3. See examples in .spade\examples\'
    Write-Host ''
}

function Install-Global {
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
    Write-Info 'AGENTS.md and architecture docs must still be installed per-project.'
    Write-Host ''
}

function Uninstall-FromProject {
    param([string]$Target)

    $Target = (Resolve-Path $Target).Path
    $versionFile = Join-Path $Target '.spade\version'

    if (-not (Test-Path $versionFile)) {
        Write-Err "No SPADE installation found in $Target"
        exit 1
    }

    Write-Host "Removing SPADE from: $Target"
    Write-Host ''

    Remove-SpadeSection (Join-Path $Target 'AGENTS.md') 'AGENTS.md'
    Remove-SpadeSection (Join-Path $Target 'CLAUDE.md') 'CLAUDE.md'

    # Remove spade-* skills
    $skillsPath = Join-Path $Target '.claude\skills'
    if (Test-Path $skillsPath) {
        Get-ChildItem $skillsPath -Directory -Filter 'spade-*' | ForEach-Object {
            Remove-Item $_.FullName -Recurse -Force
            Write-OK "Removed skill: $($_.Name)"
        }
    }

    $spadePath = Join-Path $Target '.spade'
    if (Test-Path $spadePath) {
        Remove-Item $spadePath -Recurse -Force
        Write-OK 'Removed .spade\ directory'
    }

    Write-Warn 'ARCHITECTURE.md, PATTERNS.md, ANTI-PATTERNS.md preserved (contain your content)'
    Write-Host ''
    Write-OK 'SPADE removed. Your existing file content is intact.'
    Write-Host ''
}

# --- Main ---

Write-Header

if ($Global) {
    Install-Global
}
elseif ($Remove) {
    Uninstall-FromProject -Target $Path
}
elseif ($Upgrade) {
    Install-ToProject -Target $Path
}
elseif ($Path) {
    Install-ToProject -Target $Path
}
else {
    $targetPath = Read-Host 'Where would you like to install SPADE? Project path (or . for current directory)'
    if ([string]::IsNullOrWhiteSpace($targetPath)) { $targetPath = '.' }
    Install-ToProject -Target $targetPath
}
