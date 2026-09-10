#requires -Version 5.1
<#
.SYNOPSIS
Installs the Codex tgrep skill and a marked global search preference.
.EXAMPLE
.\scripts\Install.ps1 -WhatIf
.EXAMPLE
.\scripts\Install.ps1
.EXAMPLE
.\scripts\Install.ps1 -TgrepPath "$env:LOCALAPPDATA\Programs\copilot-tgrep\1.0.5\tgrep.exe"
.NOTES
Per-user Windows setup. Does not execute tgrep, build an index, start a server,
change PATH, or change Codex configuration or permission settings.
This initial package still requires functional and performance validation.
#>
[CmdletBinding(SupportsShouldProcess = $true)]
param(
    # Reuse an existing executable without downloading or modifying it.
    # Its version is not executed or verified by this installer.
    [string] $TgrepPath
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
if ($env:OS -ne 'Windows_NT') { throw 'This installer supports Windows only.' }
foreach ($requiredVariable in @('USERPROFILE', 'LOCALAPPDATA', 'TEMP')) {
    if (-not [Environment]::GetEnvironmentVariable($requiredVariable)) {
        throw "Required environment variable is missing: $requiredVariable"
    }
}

$version = '1.0.5'
$osArchitecture = [Environment]::GetEnvironmentVariable('PROCESSOR_ARCHITECTURE', 'Machine')
if (-not $osArchitecture) { $osArchitecture = $env:PROCESSOR_ARCHITEW6432 }
if (-not $osArchitecture) { $osArchitecture = $env:PROCESSOR_ARCHITECTURE }
switch ($osArchitecture) {
    'AMD64' {
        $target = 'x86_64-pc-windows-msvc'
        $archiveHash = '5b6ba08ffddb5bc1b436c5c83b4f0c9e66c70a006b3853ed57daf51e7a75986c'
    }
    'ARM64' {
        $target = 'aarch64-pc-windows-msvc'
        $archiveHash = 'f49b68f97810530688a8fe71282dfc384ed4ff99ffe7a8a769e43e68a7c633fe'
    }
    default { throw "Unsupported Windows architecture: $osArchitecture. Use x64 or ARM64 Windows." }
}

$repository = Split-Path -Parent $PSScriptRoot
$skillSourceDirectory = Join-Path $repository 'skills\codex-tgrep-search'
$instructionSource = Join-Path $repository 'instructions\codex-tgrep.md'
$noticeSource = Join-Path $repository 'THIRD_PARTY_NOTICES.md'
$requiredSources = @($instructionSource, $noticeSource)
foreach ($relative in @('SKILL.md', 'agents\openai.yaml', 'references\windows.md', 'references\search-details.md')) {
    $requiredSources += Join-Path $skillSourceDirectory $relative
}
foreach ($source in $requiredSources) {
    if (-not (Test-Path -LiteralPath $source -PathType Leaf)) { throw "Source file missing: $source" }
}
$startMarker = '<!-- codex-tgrep-search:start -->'
$endMarker = '<!-- codex-tgrep-search:end -->'
$utf8 = New-Object System.Text.UTF8Encoding($false, $true)
$sourceBlock = [IO.File]::ReadAllText($instructionSource, $utf8).TrimEnd([char[]]"`r`n")
$blockPattern = '(?s)' + [regex]::Escape($startMarker) + '.*?' + [regex]::Escape($endMarker)
if (-not $sourceBlock.StartsWith($startMarker) -or -not $sourceBlock.EndsWith($endMarker) -or
    [regex]::Matches($sourceBlock, [regex]::Escape($startMarker)).Count -ne 1 -or
    [regex]::Matches($sourceBlock, [regex]::Escape($endMarker)).Count -ne 1 -or
    -not $sourceBlock.Contains('__SKILL_PATH__') -or -not $sourceBlock.Contains('__TGREP_PATH__')) {
    throw 'The instruction source must contain one complete marked block and both path placeholders.'
}

# Codex loads these files as UTF-8. Preserve valid UTF-8 and an optional BOM;
# reject other encodings rather than preserving bytes Codex would misinterpret.
function Read-PreservedText([string] $Path) {
    if (-not (Test-Path -LiteralPath $Path)) {
        return @{ Text = ''; Encoding = $utf8; Preamble = [byte[]]@(); Existed = $false; OriginalBytes = [byte[]]@() }
    }
    if (-not (Test-Path -LiteralPath $Path -PathType Leaf)) { throw "Expected a file at $Path." }
    $bytes = [IO.File]::ReadAllBytes($Path)
    $offset = 0
    if ($bytes.Length -ge 3 -and $bytes[0] -eq 0xEF -and $bytes[1] -eq 0xBB -and $bytes[2] -eq 0xBF) { $offset = 3 }
    try { $content = $utf8.GetString($bytes, $offset, $bytes.Length - $offset) }
    catch { throw "Codex requires UTF-8 instructions. Convert $Path to UTF-8 manually before installing; this file was not changed." }
    if ($content.Contains([string][char]0)) { throw "Unsupported text encoding in $Path. Convert it to UTF-8 manually before installing." }
    $preamble = [byte[]]@()
    if ($offset -gt 0) { $preamble = [byte[]]$bytes[0..($offset - 1)] }
    $roundTrip = [byte[]]($preamble + $utf8.GetBytes($content))
    if ([Convert]::ToBase64String($roundTrip) -cne [Convert]::ToBase64String($bytes)) {
        throw "Cannot preserve the encoding of $Path. Convert it to UTF-8 first."
    }
    return @{ Text = $content; Encoding = $utf8; Preamble = $preamble; Existed = $true; OriginalBytes = $bytes }
}

$codexDirectory = Join-Path $env:USERPROFILE '.codex'
if (-not [string]::IsNullOrWhiteSpace($env:CODEX_HOME)) {
    if ($env:CODEX_HOME -notmatch '^(?:[A-Za-z]:[\\/]|[\\/]{2}[^\\/]+[\\/][^\\/]+(?:[\\/]|$))') {
        throw 'CODEX_HOME must be an absolute Windows path. Set the same absolute path for setup and the process that launches Codex.'
    }
    $codexDirectory = $env:CODEX_HOME
}
$codexDirectory = [IO.Path]::GetFullPath($codexDirectory)
$skillDestinationDirectory = Join-Path $codexDirectory 'skills\codex-tgrep-search'
$skillDestination = Join-Path $skillDestinationDirectory 'SKILL.md'
$reusingExecutable = -not [string]::IsNullOrWhiteSpace($TgrepPath)
if ($reusingExecutable) {
    $executable = $ExecutionContext.SessionState.Path.GetUnresolvedProviderPathFromPSPath($TgrepPath)
    if (-not (Test-Path -LiteralPath $executable -PathType Leaf)) { throw "Existing tgrep executable not found: $executable" }
}
else {
    $executable = Join-Path $env:LOCALAPPDATA "Programs\codex-tgrep\$version\tgrep.exe"
}

$overridePath = Join-Path $codexDirectory 'AGENTS.override.md'
$agentsPath = Join-Path $codexDirectory 'AGENTS.md'
$globalSnapshots = @{}
$globalSnapshots[$overridePath] = Read-PreservedText $overridePath
$globalSnapshots[$agentsPath] = Read-PreservedText $agentsPath
$instructionDestination = $agentsPath
# The loader trims UTF-8 text without removing U+FEFF: even a BOM-only override
# takes precedence. Read-PreservedText separated that BOM only for byte preservation.
if ($globalSnapshots[$overridePath].Preamble.Length -gt 0 -or
    -not [string]::IsNullOrWhiteSpace($globalSnapshots[$overridePath].Text)) {
    $instructionDestination = $overridePath
}
$existing = $globalSnapshots[$instructionDestination]
$skillInstructionPath = $skillDestination.Replace('\', '/')
$tgrepInstructionPath = $executable.Replace('\', '/')
foreach ($resolvedPath in @($skillInstructionPath, $tgrepInstructionPath)) {
    if ($resolvedPath.IndexOfAny([char[]]"`r`n``") -ge 0) {
        throw 'Installation paths containing a newline or backtick cannot be inserted into the Markdown instruction block.'
    }
}
$sourceBlock = $sourceBlock.Replace('__SKILL_PATH__', $skillInstructionPath).Replace('__TGREP_PATH__', $tgrepInstructionPath)
$startCount = [regex]::Matches($existing.Text, [regex]::Escape($startMarker)).Count
$endCount = [regex]::Matches($existing.Text, [regex]::Escape($endMarker)).Count
if ($startCount -gt 1 -or $endCount -gt 1 -or $startCount -ne $endCount -or
    ($startCount -eq 1 -and -not [regex]::IsMatch($existing.Text, $blockPattern))) {
    throw "Malformed or duplicate tgrep markers in $instructionDestination. Resolve them first."
}
$newline = "`r`n"
if ($existing.Text.Contains("`n") -and -not $existing.Text.Contains("`r`n")) { $newline = "`n" }
$sourceBlock = [regex]::Replace($sourceBlock, '\r?\n', $newline)
if ($startCount -eq 1) {
    $match = [regex]::Match($existing.Text, $blockPattern)
    $newInstructions = $existing.Text.Substring(0, $match.Index) + $sourceBlock +
        $existing.Text.Substring($match.Index + $match.Length)
}
else {
    $separator = ''
    if ($existing.Text.Length -gt 0) {
        if (-not $existing.Text.EndsWith("`n")) { $separator += $newline }
        $separator += $newline
    }
    $newInstructions = $existing.Text + $separator + $sourceBlock + $newline
}
$instructionBytes = [byte[]]($existing.Preamble + $existing.Encoding.GetBytes($newInstructions))
if ($existing.Encoding.GetString($existing.Encoding.GetBytes($newInstructions)) -cne $newInstructions) {
    throw 'The existing instruction encoding cannot represent the new text. Convert it to UTF-8 first.'
}

$payload = @()
foreach ($file in @(Get-ChildItem -LiteralPath $skillSourceDirectory -File -Recurse | Sort-Object FullName)) {
    $relative = $file.FullName.Substring($skillSourceDirectory.Length + 1)
    if ($relative -ieq 'THIRD_PARTY_NOTICES.md') { continue }
    $payload += @{ Source = $file.FullName; Destination = (Join-Path $skillDestinationDirectory $relative) }
}
$payload += @{ Source = $noticeSource; Destination = (Join-Path $skillDestinationDirectory 'THIRD_PARTY_NOTICES.md') }
$destinations = @($executable, $instructionDestination) + @($payload | ForEach-Object { $_.Destination })
foreach ($destination in $destinations) {
    if ((Test-Path -LiteralPath $destination) -and -not (Test-Path -LiteralPath $destination -PathType Leaf)) {
        throw "Expected a file at $destination. Resolve the conflict before installing."
    }
}
foreach ($base in @($env:USERPROFILE, $repository)) {
    $duplicate = Join-Path $base '.agents\skills\codex-tgrep-search\SKILL.md'
    if (Test-Path -LiteralPath $duplicate -PathType Leaf) {
        Write-Warning "Another codex-tgrep-search skill exists: $duplicate. Resolve duplicate discovery before validation."
    }
}
Write-Host 'Target: local Codex on Windows; confirm skill discovery in your Codex version during validation.'
Write-Host "Executable: $executable"
Write-Host "Skill:      $skillDestination"
Write-Host "Rules:      $instructionDestination (marked section only)"
if ($reusingExecutable) { Write-Warning 'The supplied executable will be reused without version verification. This skill targets tgrep 1.0.5.' }
$operation = "Install the Codex skill and global search preference; save recovery files"
if (-not $reusingExecutable) { $operation = "Download and install Microsoft tgrep $version; " + $operation }
if (-not $PSCmdlet.ShouldProcess($codexDirectory, $operation)) { return }

$runId = (Get-Date -Format 'yyyyMMdd-HHmmss') + '-' + [Guid]::NewGuid().ToString('N').Substring(0, 8)
$backupDirectory = Join-Path $env:LOCALAPPDATA "codex-tgrep-search\backups\$runId"
$stagingDirectory = $null
[IO.Directory]::CreateDirectory($backupDirectory) | Out-Null
$recovery = [ordered]@{
    CreatedUtc = [DateTime]::UtcNow.ToString('o'); TargetTgrepVersion = $version
    CodexHome = $codexDirectory; EffectiveGlobalInstructions = $instructionDestination
    Executable = $executable; ReusedExecutable = $reusingExecutable
    Files = @(); Status = 'Preparing'; StagingDirectory = $stagingDirectory
}
$manifestPath = Join-Path $backupDirectory 'recovery.json'
function Save-Recovery {
    [IO.File]::WriteAllText($manifestPath, ($recovery | ConvertTo-Json -Depth 5), $utf8)
}
function Assert-GlobalSnapshots {
    foreach ($path in @($overridePath, $agentsPath)) {
        $snapshot = $globalSnapshots[$path]
        $currentExists = Test-Path -LiteralPath $path
        $changed = $currentExists -ne $snapshot.Existed
        if (-not $changed -and $currentExists) {
            if (-not (Test-Path -LiteralPath $path -PathType Leaf)) { $changed = $true }
            else {
                $changed = [Convert]::ToBase64String([IO.File]::ReadAllBytes($path)) -cne
                    [Convert]::ToBase64String($snapshot.OriginalBytes)
            }
        }
        if ($changed) { throw "Global Codex instructions changed while setup was preparing: $path. Review the recovery manifest and retry after saving your changes." }
    }
}
function Install-Bytes([string] $Destination, [byte[]] $Bytes) {
    $existed = Test-Path -LiteralPath $Destination -PathType Leaf
    if ($existed -and [Convert]::ToBase64String([IO.File]::ReadAllBytes($Destination)) -ceq [Convert]::ToBase64String($Bytes)) { return }
    $backupPath = $null
    if ($existed) {
        $backupPath = Join-Path $backupDirectory ('file-{0:D3}.before' -f $recovery.Files.Count)
        [IO.File]::Copy($Destination, $backupPath, $false)
    }
    $recovery.Files += [ordered]@{ Path = $Destination; Existed = $existed; Backup = $backupPath }
    Save-Recovery
    [IO.Directory]::CreateDirectory((Split-Path -Parent $Destination)) | Out-Null
    [IO.File]::WriteAllBytes($Destination, $Bytes)
}
Save-Recovery
try {
    if (-not $reusingExecutable) {
        $stagingDirectory = Join-Path $env:TEMP "codex-tgrep-search-$runId"
        [IO.Directory]::CreateDirectory($stagingDirectory) | Out-Null
        $recovery.StagingDirectory = $stagingDirectory
        Save-Recovery
        $archiveName = "tgrep-v$version-$target.zip"
        $archivePath = Join-Path $stagingDirectory $archiveName
        $uri = "https://github.com/microsoft/tgrep/releases/download/v$version/$archiveName"
        $previousTls = [Net.ServicePointManager]::SecurityProtocol
        try {
            [Net.ServicePointManager]::SecurityProtocol = $previousTls -bor [Net.SecurityProtocolType]::Tls12
            Invoke-WebRequest -UseBasicParsing -Uri $uri -OutFile $archivePath
        }
        finally { [Net.ServicePointManager]::SecurityProtocol = $previousTls }
        if ((Get-FileHash -LiteralPath $archivePath -Algorithm SHA256).Hash -ine $archiveHash) {
            throw 'Downloaded archive SHA256 does not match the pinned official release. No managed files were installed.'
        }
        Add-Type -AssemblyName System.IO.Compression.FileSystem
        $archive = [IO.Compression.ZipFile]::OpenRead($archivePath)
        try {
            # Extract only the expected executable; do not use arbitrary archive paths.
            $entries = @($archive.Entries | Where-Object { $_.FullName -ceq 'tgrep.exe' })
            if ($entries.Count -ne 1) { throw 'Expected exactly one root tgrep.exe in the official archive.' }
            $extractedPath = Join-Path $stagingDirectory 'tgrep.exe'
            [IO.Compression.ZipFileExtensions]::ExtractToFile($entries[0], $extractedPath, $false)
        }
        finally { $archive.Dispose() }
    }
    # Guard both candidates: a new override would change which instructions Codex reads.
    Assert-GlobalSnapshots
    if (-not $reusingExecutable) { Install-Bytes $executable ([IO.File]::ReadAllBytes($extractedPath)) }
    foreach ($item in $payload) { Install-Bytes $item.Destination ([IO.File]::ReadAllBytes($item.Source)) }
    Assert-GlobalSnapshots
    Install-Bytes $instructionDestination $instructionBytes
    $recovery.Status = 'Installed'
    Save-Recovery
    Write-Host 'Files installed; functional validation pending. No executable, index, server, or test was run.'
    Write-Host 'Start a fresh Codex task and follow the README to check skill discovery and instruction loading.'
    Write-Host "Recovery manifest and original files: $backupDirectory"
    if ($stagingDirectory) { Write-Host "Verified download retained for inspection: $stagingDirectory" }
}
catch {
    $recovery.Status = 'Failed: ' + $_.Exception.Message
    Save-Recovery
    Write-Warning "Setup did not complete. Review $manifestPath before retrying or restoring; partial changes may exist."
    throw
}
