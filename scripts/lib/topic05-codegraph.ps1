# Topic 05 CodeGraph provisioning primitives.
# The file intentionally parses under Windows PowerShell 5.1; bundle operations require pwsh 7.4+.

$script:Topic05CodeGraphRepositoryRoot = [IO.Path]::GetFullPath((Join-Path $PSScriptRoot '..\..'))

function Test-Topic05CodeGraphWindows {
    return [Runtime.InteropServices.RuntimeInformation]::IsOSPlatform(
        [Runtime.InteropServices.OSPlatform]::Windows
    )
}

function Get-Topic05CodeGraphPathComparison {
    if (Test-Topic05CodeGraphWindows) { return [StringComparison]::OrdinalIgnoreCase }
    return [StringComparison]::Ordinal
}

function Assert-Topic05CodeGraphPropertySet {
    param(
        [Parameter(Mandatory)][object]$Value,
        [Parameter(Mandatory)][string[]]$Expected,
        [Parameter(Mandatory)][string]$Context
    )

    if ($null -eq $Value) { throw "$Context is null" }
    $actual = @($Value.PSObject.Properties.Name | Sort-Object)
    $wanted = @($Expected | Sort-Object)
    if (($actual -join '|') -cne ($wanted -join '|')) {
        throw "$Context has unknown or missing properties: $($actual -join ', ')"
    }
}

function Assert-Topic05CodeGraphSha256 {
    param([Parameter(Mandatory)][string]$Value, [Parameter(Mandatory)][string]$Context)
    if ($Value -cnotmatch '^[0-9a-f]{64}$') { throw "$Context must be lowercase SHA-256" }
}

function Get-Topic05CodeGraphSha256 {
    param([Parameter(Mandatory)][string]$LiteralPath)
    return (Get-FileHash -LiteralPath $LiteralPath -Algorithm SHA256).Hash.ToLowerInvariant()
}

function ConvertTo-Topic05CodeGraphJsonText {
    param([Parameter(Mandatory)][object]$Value)
    return ($Value | ConvertTo-Json -Depth 20) + "`n"
}

function Get-Topic05CodeGraphTextSha256 {
    param([Parameter(Mandatory)][string]$Value)
    $algorithm = [Security.Cryptography.SHA256]::Create()
    try {
        $bytes = [Text.UTF8Encoding]::new($false).GetBytes($Value)
        return ([BitConverter]::ToString($algorithm.ComputeHash($bytes))).Replace('-', '').ToLowerInvariant()
    } finally {
        $algorithm.Dispose()
    }
}

function Write-Topic05CodeGraphJson {
    param([Parameter(Mandatory)][string]$LiteralPath, [Parameter(Mandatory)][object]$Value)
    [IO.File]::WriteAllText(
        $LiteralPath,
        (ConvertTo-Topic05CodeGraphJsonText -Value $Value),
        [Text.UTF8Encoding]::new($false)
    )
}

function Read-Topic05CodeGraphLock {
    [CmdletBinding()]
    param([Parameter(Mandatory)][string]$LiteralPath)

    if ([string]::IsNullOrWhiteSpace($LiteralPath)) { throw 'lock path is empty' }
    $resolved = [IO.Path]::GetFullPath($LiteralPath)
    if (-not (Test-Path -LiteralPath $resolved -PathType Leaf)) { throw "lock file not found: $resolved" }
    try {
        $lock = Get-Content -Raw -LiteralPath $resolved -Encoding UTF8 | ConvertFrom-Json
    } catch {
        throw "lock JSON is invalid"
    }

    Assert-Topic05CodeGraphPropertySet -Value $lock -Context 'lock' -Expected @(
        'schema_version', 'upstream', 'release_url', 'version', 'tag', 'commit', 'license',
        'license_file', 'download_origin', 'allowed_final_hosts', 'checksum_asset', 'artifacts'
    )
    if ([int]$lock.schema_version -ne 1) { throw 'lock schema_version must be 1' }
    if ($lock.upstream -cne 'colbymchenry/codegraph') { throw 'lock upstream mismatch' }
    if ($lock.release_url -cne 'https://github.com/colbymchenry/codegraph/releases/tag/v1.5.0') {
        throw 'lock release URL mismatch'
    }
    if ($lock.version -cne '1.5.0' -or $lock.tag -cne 'v1.5.0' -or
        $lock.commit -cne 'ea72e1b190921232aa7bd02e96bef5bbe4fe0ab6') {
        throw 'lock release identity mismatch'
    }
    if ($lock.license -cne 'MIT') { throw 'lock license mismatch' }
    Assert-Topic05CodeGraphPropertySet -Value $lock.license_file -Context 'license_file' `
        -Expected @('repository_path', 'sha256')
    if ($lock.license_file.repository_path -cne 'LICENSE') { throw 'lock license path mismatch' }
    Assert-Topic05CodeGraphSha256 -Value ([string]$lock.license_file.sha256) -Context 'license digest'
    if ($lock.download_origin -cne 'https://github.com/colbymchenry/codegraph/releases/download/v1.5.0/') {
        throw 'lock download origin mismatch'
    }
    $allowedHosts = @($lock.allowed_final_hosts)
    if (($allowedHosts -join '|') -cne 'github.com|release-assets.githubusercontent.com') {
        throw 'lock allowed final hosts mismatch'
    }
    Assert-Topic05CodeGraphPropertySet -Value $lock.checksum_asset -Context 'checksum_asset' `
        -Expected @('name', 'sha256')
    if ($lock.checksum_asset.name -cne 'SHA256SUMS') { throw 'lock checksum asset mismatch' }
    Assert-Topic05CodeGraphSha256 -Value ([string]$lock.checksum_asset.sha256) `
        -Context 'checksum asset digest'

    $expectedNames = [ordered]@{
        'darwin-arm64' = 'codegraph-darwin-arm64.tar.gz'
        'darwin-x64' = 'codegraph-darwin-x64.tar.gz'
        'linux-arm64' = 'codegraph-linux-arm64.tar.gz'
        'linux-x64' = 'codegraph-linux-x64.tar.gz'
        'win32-arm64' = 'codegraph-win32-arm64.zip'
        'win32-x64' = 'codegraph-win32-x64.zip'
    }
    $artifacts = @($lock.artifacts)
    $seenPlatforms = @{}
    $seenNames = @{}
    foreach ($artifact in $artifacts) {
        Assert-Topic05CodeGraphPropertySet -Value $artifact -Context 'artifact' `
            -Expected @('platform', 'name', 'size', 'sha256')
        $platform = [string]$artifact.platform
        $name = [string]$artifact.name
        if (-not $expectedNames.Contains($platform)) { throw "unknown artifact platform: $platform" }
        if ($seenPlatforms.ContainsKey($platform)) { throw "duplicate artifact platform: $platform" }
        if ($seenNames.ContainsKey($name)) { throw "duplicate artifact name: $name" }
        $seenPlatforms[$platform] = $true
        $seenNames[$name] = $true
        if ($name -cne $expectedNames[$platform]) { throw "artifact name mismatch for $platform" }
        if ([long]$artifact.size -le 0) { throw "artifact size must be positive for $platform" }
        Assert-Topic05CodeGraphSha256 -Value ([string]$artifact.sha256) `
            -Context "artifact digest for $platform"
    }
    if ($artifacts.Count -ne $expectedNames.Count) { throw 'lock must contain six artifacts' }
    return $lock
}

function Get-Topic05CodeGraphPlatform {
    [CmdletBinding()]
    param()

    $architecture = [Runtime.InteropServices.RuntimeInformation]::OSArchitecture
    if ($architecture -eq [Runtime.InteropServices.Architecture]::X64) { $suffix = 'x64' }
    elseif ($architecture -eq [Runtime.InteropServices.Architecture]::Arm64) { $suffix = 'arm64' }
    else { throw 'unsupported_platform: only x64 and arm64 are supported' }

    if ([Runtime.InteropServices.RuntimeInformation]::IsOSPlatform(
        [Runtime.InteropServices.OSPlatform]::Windows
    )) { return "win32-$suffix" }
    if ([Runtime.InteropServices.RuntimeInformation]::IsOSPlatform(
        [Runtime.InteropServices.OSPlatform]::OSX
    )) { return "darwin-$suffix" }
    if ([Runtime.InteropServices.RuntimeInformation]::IsOSPlatform(
        [Runtime.InteropServices.OSPlatform]::Linux
    )) { return "linux-$suffix" }
    throw 'unsupported_platform: operating system is not supported'
}

function Get-Topic05CodeGraphManagedCacheRoot {
    [CmdletBinding()]
    param([string]$UserProfilePath = [Environment]::GetFolderPath('UserProfile'))

    if ([string]::IsNullOrWhiteSpace($UserProfilePath)) { throw 'user profile path is empty' }
    $profile = [IO.Path]::GetFullPath($UserProfilePath).TrimEnd('\', '/')
    if ($profile -ceq [IO.Path]::GetPathRoot($profile).TrimEnd('\', '/')) {
        throw 'user profile path cannot be a filesystem root'
    }
    return [IO.Path]::GetFullPath((Join-Path $profile '.omp\cache\codegraph'))
}

function Test-Topic05CodeGraphPathInside {
    param([Parameter(Mandatory)][string]$Candidate, [Parameter(Mandatory)][string]$Root)
    $comparison = Get-Topic05CodeGraphPathComparison
    $rootFull = [IO.Path]::GetFullPath($Root).TrimEnd('\', '/')
    $candidateFull = [IO.Path]::GetFullPath($Candidate)
    return $candidateFull.StartsWith($rootFull + [IO.Path]::DirectorySeparatorChar, $comparison)
}

function Test-Topic05CodeGraphReparsePoint {
    param([Parameter(Mandatory)][string]$LiteralPath)
    if (-not (Test-Path -LiteralPath $LiteralPath)) { return $false }
    return [bool]((Get-Item -LiteralPath $LiteralPath -Force).Attributes -band [IO.FileAttributes]::ReparsePoint)
}

function Assert-Topic05CodeGraphSafeArchiveName {
    param(
        [Parameter(Mandatory)][string]$EntryName,
        [Parameter(Mandatory)][string]$ExpectedTopLevel
    )

    if ([string]::IsNullOrWhiteSpace($EntryName) -or $EntryName.IndexOf([char]0) -ge 0) {
        throw 'archive entry name is empty or invalid'
    }
    if ($EntryName.StartsWith('/') -or $EntryName.StartsWith('\') -or $EntryName -match '^[A-Za-z]:') {
        throw "archive entry is rooted: $EntryName"
    }
    $normalized = $EntryName.Replace('\', '/').TrimEnd('/')
    if ([string]::IsNullOrWhiteSpace($normalized)) { throw 'archive entry is empty' }
    $segments = @($normalized.Split('/'))
    if (@($segments | Where-Object { $_ -ceq '' -or $_ -ceq '.' -or $_ -ceq '..' }).Count -gt 0) {
        throw "archive entry escapes its root: $EntryName"
    }
    if ($segments[0] -cne $ExpectedTopLevel) {
        throw "archive contains an unexpected top-level path: $($segments[0])"
    }
    return $normalized
}

function Expand-Topic05CodeGraphZip {
    param(
        [Parameter(Mandatory)][string]$ArchivePath,
        [Parameter(Mandatory)][string]$Destination,
        [Parameter(Mandatory)][string]$ExpectedTopLevel
    )

    Add-Type -AssemblyName System.IO.Compression.FileSystem
    $zip = [IO.Compression.ZipFile]::OpenRead($ArchivePath)
    try {
        foreach ($entry in $zip.Entries) {
            $normalized = Assert-Topic05CodeGraphSafeArchiveName -EntryName $entry.FullName `
                -ExpectedTopLevel $ExpectedTopLevel
            $unixType = ([int64]$entry.ExternalAttributes -shr 16) -band 0xF000
            if ($unixType -eq 0xA000) { throw "archive symbolic links are not allowed in ZIP: $normalized" }
        }
        foreach ($entry in $zip.Entries) {
            $normalized = (Assert-Topic05CodeGraphSafeArchiveName -EntryName $entry.FullName `
                -ExpectedTopLevel $ExpectedTopLevel)
            if ($normalized -ceq $ExpectedTopLevel) { continue }
            $relative = $normalized.Substring($ExpectedTopLevel.Length).TrimStart('/')
            $target = [IO.Path]::GetFullPath((Join-Path $Destination $relative))
            if (-not (Test-Topic05CodeGraphPathInside -Candidate $target -Root $Destination)) {
                throw "archive target escapes staging: $normalized"
            }
            $isDirectory = $entry.FullName.EndsWith('/') -or $entry.FullName.EndsWith('\')
            if ($isDirectory) {
                [void](New-Item -ItemType Directory -Path $target -Force)
                continue
            }
            $parent = Split-Path -Parent $target
            if (-not (Test-Path -LiteralPath $parent -PathType Container)) {
                [void](New-Item -ItemType Directory -Path $parent -Force)
            }
            if (Test-Path -LiteralPath $target) { throw "archive duplicate target: $relative" }
            $input = $entry.Open()
            $output = [IO.File]::Open($target, [IO.FileMode]::CreateNew, [IO.FileAccess]::Write, [IO.FileShare]::None)
            try { $input.CopyTo($output) } finally { $output.Dispose(); $input.Dispose() }
        }
    } finally {
        $zip.Dispose()
    }
}

function Open-Topic05CodeGraphTarReader {
    param([Parameter(Mandatory)][string]$ArchivePath)
    $file = [IO.File]::OpenRead($ArchivePath)
    $gzip = [IO.Compression.GZipStream]::new($file, [IO.Compression.CompressionMode]::Decompress, $false)
    $reader = [System.Formats.Tar.TarReader]::new($gzip, $false)
    return [pscustomobject]@{ File = $file; Gzip = $gzip; Reader = $reader }
}

function Close-Topic05CodeGraphTarReader {
    param([Parameter(Mandatory)][object]$Handle)
    $Handle.Reader.Dispose()
    $Handle.Gzip.Dispose()
    $Handle.File.Dispose()
}

function Expand-Topic05CodeGraphTarGz {
    param(
        [Parameter(Mandatory)][string]$ArchivePath,
        [Parameter(Mandatory)][string]$Destination,
        [Parameter(Mandatory)][string]$ExpectedTopLevel
    )

    $handle = Open-Topic05CodeGraphTarReader -ArchivePath $ArchivePath
    try {
        while ($null -ne ($entry = $handle.Reader.GetNextEntry())) {
            $normalized = Assert-Topic05CodeGraphSafeArchiveName -EntryName $entry.Name `
                -ExpectedTopLevel $ExpectedTopLevel
            $type = $entry.EntryType.ToString()
            if ($type -ceq 'HardLink') { throw "archive hard links are not supported: $normalized" }
            if ($type -ceq 'SymbolicLink') {
                $link = [string]$entry.LinkName
                if ([string]::IsNullOrWhiteSpace($link) -or [IO.Path]::IsPathRooted($link) -or
                    $link -match '^[A-Za-z]:') { throw "archive symbolic link is unsafe: $normalized" }
                $relative = $normalized.Substring($ExpectedTopLevel.Length).TrimStart('/')
                $linkParent = Split-Path -Parent (Join-Path $Destination $relative)
                $linkTarget = [IO.Path]::GetFullPath((Join-Path $linkParent $link))
                if (-not (Test-Topic05CodeGraphPathInside -Candidate $linkTarget -Root $Destination)) {
                    throw "archive symbolic link escapes staging: $normalized"
                }
            }
        }
    } finally { Close-Topic05CodeGraphTarReader -Handle $handle }

    $handle = Open-Topic05CodeGraphTarReader -ArchivePath $ArchivePath
    try {
        while ($null -ne ($entry = $handle.Reader.GetNextEntry())) {
            $normalized = Assert-Topic05CodeGraphSafeArchiveName -EntryName $entry.Name `
                -ExpectedTopLevel $ExpectedTopLevel
            if ($normalized -ceq $ExpectedTopLevel) { continue }
            $relative = $normalized.Substring($ExpectedTopLevel.Length).TrimStart('/')
            $target = [IO.Path]::GetFullPath((Join-Path $Destination $relative))
            if (-not (Test-Topic05CodeGraphPathInside -Candidate $target -Root $Destination)) {
                throw "archive target escapes staging: $normalized"
            }
            $type = $entry.EntryType.ToString()
            if ($type -ceq 'Directory') {
                [void](New-Item -ItemType Directory -Path $target -Force)
                continue
            }
            $parent = Split-Path -Parent $target
            if (-not (Test-Path -LiteralPath $parent -PathType Container)) {
                [void](New-Item -ItemType Directory -Path $parent -Force)
            }
            if ($type -ceq 'SymbolicLink') {
                [void][IO.File]::CreateSymbolicLink($target, [string]$entry.LinkName)
                continue
            }
            if ($null -eq $entry.DataStream) { continue }
            $output = [IO.File]::Open($target, [IO.FileMode]::CreateNew, [IO.FileAccess]::Write, [IO.FileShare]::None)
            try { $entry.DataStream.CopyTo($output) } finally { $output.Dispose() }
        }
    } finally { Close-Topic05CodeGraphTarReader -Handle $handle }
}

function Get-Topic05CodeGraphRequiredRelativePaths {
    param([Parameter(Mandatory)][string]$Platform)
    $launcher = if ($Platform.StartsWith('win32-', [StringComparison]::Ordinal)) {
        'bin/codegraph.cmd'
    } else { 'bin/codegraph' }
    $node = if ($Platform.StartsWith('win32-', [StringComparison]::Ordinal)) { 'node.exe' } else { 'node' }
    return [ordered]@{
        launcher = $launcher
        node = $node
        package = 'lib/package.json'
        library_entry = 'lib/dist/index.js'
        cli_entry = 'lib/dist/bin/codegraph.js'
    }
}

function Get-Topic05CodeGraphTreeHash {
    param([Parameter(Mandatory)][string]$BundleRoot)
    $root = [IO.Path]::GetFullPath($BundleRoot).TrimEnd('\', '/')
    [string[]]$rows = foreach ($file in Get-ChildItem -LiteralPath $root -File -Recurse -Force) {
        $relative = $file.FullName.Substring($root.Length).TrimStart('\', '/').Replace('\', '/')
        if ($relative -ceq 'receipt.json') { continue }
        "$relative|$($file.Length)|$(Get-Topic05CodeGraphSha256 -LiteralPath $file.FullName)"
    }
    [Array]::Sort($rows, [StringComparer]::Ordinal)
    $bytes = [Text.UTF8Encoding]::new($false).GetBytes(($rows -join "`n"))
    $sha = [Security.Cryptography.SHA256]::Create()
    try { return ([BitConverter]::ToString($sha.ComputeHash($bytes))).Replace('-', '').ToLowerInvariant() }
    finally { $sha.Dispose() }
}

function Invoke-Topic05CodeGraphVersionProbe {
    param(
        [Parameter(Mandatory)][string]$NodePath,
        [Parameter(Mandatory)][string]$CliPath
    )

    $start = [Diagnostics.ProcessStartInfo]::new()
    $start.FileName = $NodePath
    $start.WorkingDirectory = Split-Path -Parent $NodePath
    $start.UseShellExecute = $false
    $start.CreateNoWindow = $true
    $start.RedirectStandardInput = $true
    $start.RedirectStandardOutput = $true
    $start.RedirectStandardError = $true
    [void]$start.ArgumentList.Add($CliPath)
    [void]$start.ArgumentList.Add('--version')
    foreach ($key in @($start.Environment.Keys)) {
        if ($key.StartsWith('CODEGRAPH_', [StringComparison]::OrdinalIgnoreCase) -or
            $key -ceq 'NODE_OPTIONS' -or $key -ceq 'NODE_PATH') { [void]$start.Environment.Remove($key) }
    }
    $start.Environment['CODEGRAPH_DIR'] = '.codegraph'
    $start.Environment['CODEGRAPH_TELEMETRY'] = '0'
    $start.Environment['CODEGRAPH_NO_UPDATE_CHECK'] = '1'
    $start.Environment['CODEGRAPH_NO_DAEMON'] = '1'
    $start.Environment['DO_NOT_TRACK'] = '1'
    $start.Environment['CI'] = '1'
    $start.Environment['NO_COLOR'] = '1'

    $process = [Diagnostics.Process]::new()
    $process.StartInfo = $start
    try {
        if (-not $process.Start()) { throw 'version probe could not start' }
        $process.StandardInput.Close()
        $stdoutTask = $process.StandardOutput.ReadToEndAsync()
        $stderrTask = $process.StandardError.ReadToEndAsync()
        if (-not $process.WaitForExit(10000)) {
            try { $process.Kill($true) } catch { try { $process.Kill() } catch {} }
            throw 'version probe timeout'
        }
        $stdout = $stdoutTask.GetAwaiter().GetResult()
        [void]$stderrTask.GetAwaiter().GetResult()
        if ($process.ExitCode -ne 0) { throw 'version probe exited nonzero' }
        if ([Text.Encoding]::UTF8.GetByteCount($stdout) -gt 65536) { throw 'version probe output overflow' }
        $matches = [regex]::Matches($stdout, '(?<![0-9])1\.5\.0(?![0-9])')
        if ($matches.Count -ne 1) { throw 'version probe returned an invalid version' }
        return $matches[0].Value
    } finally { $process.Dispose() }
}

function Get-Topic05CodeGraphRequiredFileRecords {
    param(
        [Parameter(Mandatory)][string]$BundleRoot,
        [Parameter(Mandatory)][string]$Platform
    )
    $required = Get-Topic05CodeGraphRequiredRelativePaths -Platform $Platform
    $records = [ordered]@{}
    foreach ($entry in $required.GetEnumerator()) {
        $path = Join-Path $BundleRoot ($entry.Value.Replace('/', [IO.Path]::DirectorySeparatorChar))
        if (-not (Test-Path -LiteralPath $path -PathType Leaf)) {
            throw "required bundle file is missing: $($entry.Value)"
        }
        if (Test-Topic05CodeGraphReparsePoint -LiteralPath $path) {
            throw "required bundle file cannot be a reparse point: $($entry.Value)"
        }
        $records[$entry.Key] = [ordered]@{
            path = $entry.Value
            sha256 = Get-Topic05CodeGraphSha256 -LiteralPath $path
        }
    }
    $packagePath = Join-Path $BundleRoot 'lib\package.json'
    try { $package = Get-Content -Raw -LiteralPath $packagePath -Encoding UTF8 | ConvertFrom-Json }
    catch { throw 'required package metadata is invalid' }
    if ([string]$package.version -cne '1.5.0') { throw 'required package version mismatch' }
    return $records
}

function Read-Topic05CodeGraphReceipt {
    param([Parameter(Mandatory)][string]$LiteralPath)
    if (-not (Test-Path -LiteralPath $LiteralPath -PathType Leaf)) { throw 'managed cache conflict: receipt is missing' }
    try { $receipt = Get-Content -Raw -LiteralPath $LiteralPath -Encoding UTF8 | ConvertFrom-Json }
    catch { throw 'managed cache conflict: receipt JSON is invalid' }
    Assert-Topic05CodeGraphPropertySet -Value $receipt -Context 'receipt' -Expected @(
        'schema_version', 'record_type', 'upstream', 'version', 'tag', 'commit', 'platform',
        'bundle_root', 'receipt_path', 'artifact', 'required_files', 'bundle_tree_sha256',
        'provisioned_at_utc'
    )
    Assert-Topic05CodeGraphPropertySet -Value $receipt.artifact -Context 'receipt artifact' `
        -Expected @('name', 'size', 'sha256')
    Assert-Topic05CodeGraphPropertySet -Value $receipt.required_files -Context 'receipt required_files' `
        -Expected @('launcher', 'node', 'package', 'library_entry', 'cli_entry')
    foreach ($name in @('launcher', 'node', 'package', 'library_entry', 'cli_entry')) {
        Assert-Topic05CodeGraphPropertySet -Value $receipt.required_files.$name `
            -Context "receipt required_files.$name" -Expected @('path', 'sha256')
        Assert-Topic05CodeGraphSha256 -Value ([string]$receipt.required_files.$name.sha256) `
            -Context "receipt required_files.$name digest"
    }
    Assert-Topic05CodeGraphSha256 -Value ([string]$receipt.artifact.sha256) -Context 'receipt artifact digest'
    Assert-Topic05CodeGraphSha256 -Value ([string]$receipt.bundle_tree_sha256) -Context 'receipt tree digest'
    return $receipt
}

function Test-Topic05CodeGraphPublishedBundle {
    param(
        [Parameter(Mandatory)][string]$FinalRoot,
        [Parameter(Mandatory)][object]$Lock,
        [Parameter(Mandatory)][object]$Artifact
    )
    try {
        $receiptPath = Join-Path $FinalRoot 'receipt.json'
        $receipt = Read-Topic05CodeGraphReceipt -LiteralPath $receiptPath
        $comparison = Get-Topic05CodeGraphPathComparison
        if ([int]$receipt.schema_version -ne 1 -or $receipt.record_type -cne 'codegraph_bundle_receipt') {
            throw 'receipt identity'
        }
        foreach ($name in @('upstream', 'version', 'tag', 'commit')) {
            if ([string]$receipt.$name -cne [string]$Lock.$name) { throw "receipt $name" }
        }
        if ($receipt.platform -cne $Artifact.platform -or $receipt.artifact.name -cne $Artifact.name -or
            [long]$receipt.artifact.size -ne [long]$Artifact.size -or
            $receipt.artifact.sha256 -cne $Artifact.sha256) { throw 'receipt artifact' }
        if (-not ([IO.Path]::GetFullPath([string]$receipt.bundle_root).Equals(
            [IO.Path]::GetFullPath($FinalRoot), $comparison
        ))) { throw 'receipt bundle path' }
        if (-not ([IO.Path]::GetFullPath([string]$receipt.receipt_path).Equals(
            [IO.Path]::GetFullPath($receiptPath), $comparison
        ))) { throw 'receipt path' }
        $actualRecords = Get-Topic05CodeGraphRequiredFileRecords -BundleRoot $FinalRoot `
            -Platform ([string]$Artifact.platform)
        foreach ($name in @('launcher', 'node', 'package', 'library_entry', 'cli_entry')) {
            if ($receipt.required_files.$name.path -cne $actualRecords[$name].path -or
                $receipt.required_files.$name.sha256 -cne $actualRecords[$name].sha256) {
                throw "required file $name"
            }
        }
        if ($receipt.bundle_tree_sha256 -cne (Get-Topic05CodeGraphTreeHash -BundleRoot $FinalRoot)) {
            throw 'bundle tree hash'
        }
        $nodePath = Join-Path $FinalRoot ($actualRecords.node.path.Replace('/', [IO.Path]::DirectorySeparatorChar))
        $cliPath = Join-Path $FinalRoot ($actualRecords.cli_entry.path.Replace('/', [IO.Path]::DirectorySeparatorChar))
        $version = Invoke-Topic05CodeGraphVersionProbe -NodePath $nodePath -CliPath $cliPath
        if ($version -cne '1.5.0') { throw 'version mismatch' }
        return $receipt
    } catch {
        throw "managed cache conflict: $($_.Exception.Message)"
    }
}

function Invoke-Topic05CodeGraphDownload {
    param(
        [Parameter(Mandatory)][uri]$Uri,
        [Parameter(Mandatory)][string]$Destination,
        [Parameter(Mandatory)][string[]]$AllowedFinalHosts
    )
    if ($Uri.Scheme -cne 'https') { throw 'network URL must use HTTPS' }
    $handler = [Net.Http.HttpClientHandler]::new()
    $handler.AllowAutoRedirect = $true
    $handler.MaxAutomaticRedirections = 5
    $client = [Net.Http.HttpClient]::new($handler)
    $client.Timeout = [TimeSpan]::FromMinutes(5)
    try {
        $response = $client.GetAsync($Uri, [Net.Http.HttpCompletionOption]::ResponseHeadersRead).GetAwaiter().GetResult()
        try {
            if (-not $response.IsSuccessStatusCode) { throw "network response status $([int]$response.StatusCode)" }
            $finalUri = $response.RequestMessage.RequestUri
            if ($finalUri.Scheme -cne 'https' -or -not ($AllowedFinalHosts -ccontains $finalUri.Host)) {
                throw "network redirect host is not allowed: $($finalUri.Host)"
            }
            $output = [IO.File]::Open($Destination, [IO.FileMode]::CreateNew, [IO.FileAccess]::Write, [IO.FileShare]::None)
            try { [void]$response.Content.CopyToAsync($output).GetAwaiter().GetResult() }
            finally { $output.Dispose() }
            return $finalUri.AbsoluteUri
        } finally { $response.Dispose() }
    } finally { $client.Dispose(); $handler.Dispose() }
}

function Remove-Topic05CodeGraphEmptyParents {
    param(
        [Parameter(Mandatory)][string]$Start,
        [Parameter(Mandatory)][string]$Stop
    )
    $current = [IO.Path]::GetFullPath($Start).TrimEnd('\', '/')
    $stopFull = [IO.Path]::GetFullPath($Stop).TrimEnd('\', '/')
    $comparison = Get-Topic05CodeGraphPathComparison
    while ($current.StartsWith($stopFull, $comparison) -and (Test-Path -LiteralPath $current -PathType Container)) {
        if (@(Get-ChildItem -LiteralPath $current -Force).Count -ne 0) { break }
        [IO.Directory]::Delete($current)
        if ($current.Equals($stopFull, $comparison)) { break }
        $current = [IO.Path]::GetDirectoryName($current).TrimEnd('\', '/')
    }
}

function Install-Topic05CodeGraphBundle {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][string]$LockPath,
        [Parameter(Mandatory)][string]$CacheRoot,
        [string]$ArtifactPath,
        [switch]$AllowNetwork
    )

    if ([string]::IsNullOrWhiteSpace($CacheRoot)) { throw 'cache root is empty' }
    if ($ArtifactPath -and $AllowNetwork) { throw 'artifact path and network acquisition are mutually exclusive' }
    $lock = Read-Topic05CodeGraphLock -LiteralPath $LockPath
    $platform = Get-Topic05CodeGraphPlatform
    $artifactRows = @($lock.artifacts | Where-Object platform -CEQ $platform)
    if ($artifactRows.Count -ne 1) { throw "unsupported_platform: lock row is unavailable for $platform" }
    $artifact = $artifactRows[0]
    $cacheFull = [IO.Path]::GetFullPath($CacheRoot).TrimEnd('\', '/')
    if ($cacheFull -ceq [IO.Path]::GetPathRoot($cacheFull).TrimEnd('\', '/')) {
        throw 'cache root cannot be a filesystem root'
    }
    if (Test-Topic05CodeGraphReparsePoint -LiteralPath $cacheFull) { throw 'cache root cannot be a reparse point' }
    $versionRoot = Join-Path $cacheFull 'v1.5.0'
    $finalRoot = Join-Path $versionRoot $platform
    if (Test-Path -LiteralPath $finalRoot) {
        if (-not (Test-Path -LiteralPath $finalRoot -PathType Container) -or
            (Test-Topic05CodeGraphReparsePoint -LiteralPath $finalRoot)) {
            throw 'managed cache conflict: final target is not a real directory'
        }
        return Test-Topic05CodeGraphPublishedBundle -FinalRoot $finalRoot -Lock $lock -Artifact $artifact
    }

    $sourceArchive = $null
    $downloadRoot = $null
    if ($ArtifactPath) {
        $sourceArchive = [IO.Path]::GetFullPath($ArtifactPath)
        if (-not (Test-Path -LiteralPath $sourceArchive -PathType Leaf)) {
            throw "artifact path not found: $sourceArchive"
        }
    } elseif (-not $AllowNetwork) {
        throw 'artifact path is required unless network acquisition is explicitly allowed'
    }

    if ($null -ne $sourceArchive) {
        $item = Get-Item -LiteralPath $sourceArchive
        if ([long]$item.Length -ne [long]$artifact.size) { throw 'artifact size mismatch' }
        if ((Get-Topic05CodeGraphSha256 -LiteralPath $sourceArchive) -cne $artifact.sha256) {
            throw 'artifact digest mismatch'
        }
    }

    $stagingRoot = $null
    try {
        [void](New-Item -ItemType Directory -Path $versionRoot -Force)
        if ($AllowNetwork) {
            $downloadRoot = Join-Path $versionRoot ($platform + '.download-' + [guid]::NewGuid().ToString('N'))
            [void](New-Item -ItemType Directory -Path $downloadRoot)
            $sourceArchive = Join-Path $downloadRoot $artifact.name
            $downloadUri = [uri]($lock.download_origin + $artifact.name)
            $finalDownloadUri = [uri](Invoke-Topic05CodeGraphDownload -Uri $downloadUri `
                -Destination $sourceArchive -AllowedFinalHosts @($lock.allowed_final_hosts))
            if ($finalDownloadUri.Scheme -cne 'https' -or
                -not (@($lock.allowed_final_hosts) -ccontains $finalDownloadUri.Host)) {
                throw "network redirect host is not allowed: $($finalDownloadUri.Host)"
            }
            $item = Get-Item -LiteralPath $sourceArchive
            if ([long]$item.Length -ne [long]$artifact.size) { throw 'artifact size mismatch' }
            if ((Get-Topic05CodeGraphSha256 -LiteralPath $sourceArchive) -cne $artifact.sha256) {
                throw 'artifact digest mismatch'
            }
        }

        $stagingRoot = Join-Path $versionRoot ($platform + '.staging-' + [guid]::NewGuid().ToString('N'))
        [void](New-Item -ItemType Directory -Path $stagingRoot)
        $expectedTop = "codegraph-$platform"
        if ($artifact.name.EndsWith('.zip', [StringComparison]::Ordinal)) {
            Expand-Topic05CodeGraphZip -ArchivePath $sourceArchive -Destination $stagingRoot `
                -ExpectedTopLevel $expectedTop
        } elseif ($artifact.name.EndsWith('.tar.gz', [StringComparison]::Ordinal)) {
            Expand-Topic05CodeGraphTarGz -ArchivePath $sourceArchive -Destination $stagingRoot `
                -ExpectedTopLevel $expectedTop
        } else { throw 'archive format is unsupported' }

        $records = Get-Topic05CodeGraphRequiredFileRecords -BundleRoot $stagingRoot -Platform $platform
        $nodePath = Join-Path $stagingRoot ($records.node.path.Replace('/', [IO.Path]::DirectorySeparatorChar))
        $cliPath = Join-Path $stagingRoot ($records.cli_entry.path.Replace('/', [IO.Path]::DirectorySeparatorChar))
        $detectedVersion = Invoke-Topic05CodeGraphVersionProbe -NodePath $nodePath -CliPath $cliPath
        if ($detectedVersion -cne '1.5.0') { throw "version mismatch: detected $detectedVersion" }

        $receiptPath = Join-Path $finalRoot 'receipt.json'
        $receipt = [ordered]@{
            schema_version = 1
            record_type = 'codegraph_bundle_receipt'
            upstream = [string]$lock.upstream
            version = [string]$lock.version
            tag = [string]$lock.tag
            commit = [string]$lock.commit
            platform = $platform
            bundle_root = [IO.Path]::GetFullPath($finalRoot)
            receipt_path = [IO.Path]::GetFullPath($receiptPath)
            artifact = [ordered]@{
                name = [string]$artifact.name
                size = [long]$artifact.size
                sha256 = [string]$artifact.sha256
            }
            required_files = $records
            bundle_tree_sha256 = Get-Topic05CodeGraphTreeHash -BundleRoot $stagingRoot
            provisioned_at_utc = [DateTime]::UtcNow.ToString('o')
        }
        Write-Topic05CodeGraphJson -LiteralPath (Join-Path $stagingRoot 'receipt.json') -Value $receipt
        if (Test-Path -LiteralPath $finalRoot) { throw 'managed cache conflict: final target appeared during publication' }
        [IO.Directory]::Move($stagingRoot, $finalRoot)
        $stagingRoot = $null
        return Read-Topic05CodeGraphReceipt -LiteralPath $receiptPath
    } finally {
        if ($stagingRoot -and (Test-Path -LiteralPath $stagingRoot)) {
            Remove-Item -LiteralPath $stagingRoot -Recurse -Force
        }
        if ($downloadRoot -and (Test-Path -LiteralPath $downloadRoot)) {
            Remove-Item -LiteralPath $downloadRoot -Recurse -Force
        }
        if (Test-Path -LiteralPath $versionRoot -PathType Container) {
            Remove-Topic05CodeGraphEmptyParents -Start $versionRoot -Stop $cacheFull
        }
    }
}

function Read-Topic05CodeGraphComponentManifest {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][string]$LiteralPath,
        [Parameter(Mandatory)][string]$TemplateRoot
    )

    $manifestPath = [IO.Path]::GetFullPath($LiteralPath)
    $templateFull = [IO.Path]::GetFullPath($TemplateRoot).TrimEnd('\', '/')
    if (-not (Test-Path -LiteralPath $manifestPath -PathType Leaf)) {
        throw 'CodeGraph component manifest is missing'
    }
    try { $manifest = Get-Content -Raw -LiteralPath $manifestPath -Encoding UTF8 | ConvertFrom-Json }
    catch { throw 'CodeGraph component manifest JSON is invalid' }
    Assert-Topic05CodeGraphPropertySet -Value $manifest -Context 'component manifest' -Expected @(
        'schema_version', 'record_type', 'component', 'component_version', 'minimum_pwsh_version',
        'requires', 'upstream_lock', 'files', 'generated_target_files'
    )
    if ([int]$manifest.schema_version -ne 1 -or
        $manifest.record_type -cne 'codegraph_component_manifest' -or
        $manifest.component -cne 'codegraph' -or
        $manifest.component_version -cne '1.0.0' -or
        [version]$manifest.minimum_pwsh_version -lt [version]'7.4.0') {
        throw 'CodeGraph component manifest identity is unsupported'
    }

    $requires = @($manifest.requires)
    if ($requires.Count -ne 1) { throw 'CodeGraph component manifest must require exactly state' }
    $state = $requires[0]
    Assert-Topic05CodeGraphPropertySet -Value $state -Context 'component state requirement' -Expected @(
        'component', 'path', 'schema_version', 'record_type', 'sha256'
    )
    Assert-Topic05CodeGraphSha256 -Value ([string]$state.sha256) -Context 'state manifest digest'
    if ($state.component -cne 'state' -or $state.path -cne '.omp/state/manifest.json' -or
        [int]$state.schema_version -ne 1 -or $state.record_type -cne 'agent_tasks_component_manifest') {
        throw 'CodeGraph state requirement is unsupported'
    }
    $sourceStateManifest = Join-Path $templateFull '.omp\state\manifest.json'
    if (-not (Test-Path -LiteralPath $sourceStateManifest -PathType Leaf) -or
        (Get-Topic05CodeGraphSha256 $sourceStateManifest) -cne [string]$state.sha256) {
        throw 'CodeGraph state requirement digest does not match the template state manifest'
    }

    Assert-Topic05CodeGraphPropertySet -Value $manifest.upstream_lock -Context 'component upstream lock' `
        -Expected @('path', 'sha256', 'version', 'tag', 'commit')
    Assert-Topic05CodeGraphSha256 -Value ([string]$manifest.upstream_lock.sha256) `
        -Context 'component upstream lock digest'
    if ($manifest.upstream_lock.path -cne '.omp/codegraph/upstream-lock.json' -or
        $manifest.upstream_lock.version -cne '1.5.0' -or $manifest.upstream_lock.tag -cne 'v1.5.0' -or
        $manifest.upstream_lock.commit -cne 'ea72e1b190921232aa7bd02e96bef5bbe4fe0ab6') {
        throw 'CodeGraph component upstream lock identity is unsupported'
    }

    $expectedPaths = [string[]]@(
        '.omp/codegraph/CODEGRAPH-LICENSE.txt',
        '.omp/codegraph/COMPONENT.md',
        '.omp/codegraph/codegraph-process.ps1',
        '.omp/codegraph/safe-init.mjs',
        '.omp/codegraph/upstream-lock.json',
        '.omp/tools/codegraph-retrieve.js'
    )
    [Array]::Sort($expectedPaths, [StringComparer]::Ordinal)
    $rows = @($manifest.files)
    if ($rows.Count -ne $expectedPaths.Count) { throw 'CodeGraph component file set is not exact' }
    $actualPaths = [Collections.Generic.List[string]]::new()
    foreach ($row in $rows) {
        Assert-Topic05CodeGraphPropertySet -Value $row -Context 'component file row' -Expected @('path', 'sha256')
        $relative = [string]$row.path
        Assert-Topic05CodeGraphSha256 -Value ([string]$row.sha256) -Context "component file digest $relative"
        [void]$actualPaths.Add($relative)
        $sourcePath = [IO.Path]::GetFullPath((Join-Path $templateFull ($relative -replace '/', '\')))
        if (-not (Test-Topic05CodeGraphPathInside -Root $templateFull -Candidate $sourcePath) -or
            -not (Test-Path -LiteralPath $sourcePath -PathType Leaf) -or
            (Get-Topic05CodeGraphSha256 $sourcePath) -cne [string]$row.sha256) {
            throw "CodeGraph component file hash check failed: $relative"
        }
    }
    $actualArray = [string[]]$actualPaths.ToArray()
    $sortedArray = [string[]]$actualPaths.ToArray()
    [Array]::Sort($sortedArray, [StringComparer]::Ordinal)
    if (($actualArray -join '|') -cne ($sortedArray -join '|') -or
        ($actualArray -join '|') -cne ($expectedPaths -join '|')) {
        throw 'CodeGraph component files are not sorted and exact'
    }
    $lockPath = Join-Path $templateFull '.omp\codegraph\upstream-lock.json'
    if ((Get-Topic05CodeGraphSha256 $lockPath) -cne [string]$manifest.upstream_lock.sha256) {
        throw 'CodeGraph component upstream lock digest mismatch'
    }
    $lock = Read-Topic05CodeGraphLock -LiteralPath $lockPath
    if ($lock.version -cne $manifest.upstream_lock.version -or $lock.tag -cne $manifest.upstream_lock.tag -or
        $lock.commit -cne $manifest.upstream_lock.commit) {
        throw 'CodeGraph component and upstream lock identities disagree'
    }
    $licensePath = Join-Path $templateFull '.omp\codegraph\CODEGRAPH-LICENSE.txt'
    if ((Get-Topic05CodeGraphSha256 $licensePath) -cne
        'e6d98f98c666bebe065ac2492a0a19232cc318d4d67bac3ca42ffb77bacc8809') {
        throw 'CodeGraph license bytes do not match the pinned upstream license'
    }
    if ((@($manifest.generated_target_files) -join '|') -cne
        '.omp/codegraph/runtime.json|.omp/codegraph/install-record.json') {
        throw 'CodeGraph generated target file set is not exact'
    }
    return $manifest
}

function New-Topic05CodeGraphRuntimeRecord {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][object]$Receipt,
        [Parameter(Mandatory)][string]$TargetOmp,
        [Parameter(Mandatory)][string]$PwshPath
    )

    $targetFull = [IO.Path]::GetFullPath($TargetOmp).TrimEnd('\', '/')
    $pwshFull = [IO.Path]::GetFullPath($PwshPath)
    $templateRoot = Join-Path $script:Topic05CodeGraphRepositoryRoot 'template'
    $componentManifestPath = Join-Path $templateRoot '.omp\codegraph\component-manifest.json'
    $lockPath = Join-Path $templateRoot '.omp\codegraph\upstream-lock.json'
    [void](Read-Topic05CodeGraphComponentManifest -LiteralPath $componentManifestPath -TemplateRoot $templateRoot)
    $receiptPath = [IO.Path]::GetFullPath([string]$Receipt.receipt_path)
    if (-not (Test-Path -LiteralPath $receiptPath -PathType Leaf)) { throw 'bundle receipt is missing' }
    $validatedReceipt = Read-Topic05CodeGraphReceipt -LiteralPath $receiptPath
    foreach ($name in @('upstream', 'version', 'tag', 'commit', 'platform')) {
        if ([string]$Receipt.$name -cne [string]$validatedReceipt.$name) { throw 'bundle receipt identity changed' }
    }
    $bundleRoot = [IO.Path]::GetFullPath([string]$validatedReceipt.bundle_root).TrimEnd('\', '/')
    $required = $validatedReceipt.required_files
    $pathFor = {
        param([string]$Name)
        return [IO.Path]::GetFullPath((Join-Path $bundleRoot ([string]$required.$Name.path -replace '/', '\')))
    }
    return [ordered]@{
        schema_version = 1
        record_type = 'codegraph_target_runtime'
        component = 'codegraph'
        component_version = '1.0.0'
        created_at_utc = [DateTime]::UtcNow.ToString('o')
        target_omp = $targetFull
        component_manifest_sha256 = Get-Topic05CodeGraphSha256 $componentManifestPath
        upstream_lock_sha256 = Get-Topic05CodeGraphSha256 $lockPath
        receipt_sha256 = Get-Topic05CodeGraphSha256 $receiptPath
        upstream = [string]$validatedReceipt.upstream
        version = [string]$validatedReceipt.version
        tag = [string]$validatedReceipt.tag
        commit = [string]$validatedReceipt.commit
        platform = [string]$validatedReceipt.platform
        artifact_sha256 = [string]$validatedReceipt.artifact.sha256
        paths = [ordered]@{
            bundle_root = $bundleRoot
            receipt = $receiptPath
            launcher = & $pathFor 'launcher'
            node = & $pathFor 'node'
            library_entry = & $pathFor 'library_entry'
            cli_entry = & $pathFor 'cli_entry'
            safe_init = [IO.Path]::GetFullPath((Join-Path $targetFull 'codegraph\safe-init.mjs'))
            process_wrapper = [IO.Path]::GetFullPath((Join-Path $targetFull 'codegraph\codegraph-process.ps1'))
            pwsh = $pwshFull
        }
    }
}

function Get-Topic05CodeGraphCleanupPlan {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [ValidateSet('bundle', 'index')]
        [string]$Kind,

        [Parameter(Mandatory)][string]$LiteralPath,
        [Parameter(Mandatory)][string]$Confirmation,
        [string]$ManagedCacheRoot = (Get-Topic05CodeGraphManagedCacheRoot)
    )

    if ([string]::IsNullOrWhiteSpace($LiteralPath) -or
        [string]::IsNullOrWhiteSpace($Confirmation)) {
        throw 'cleanup input is empty'
    }
    $target = [IO.Path]::GetFullPath($LiteralPath).TrimEnd('\', '/')
    if (-not (Test-Path -LiteralPath $target -PathType Container)) {
        throw 'cleanup target is missing'
    }
    if (Test-Topic05CodeGraphReparsePoint -LiteralPath $target) {
        throw 'cleanup target cannot be a reparse point'
    }
    $comparison = Get-Topic05CodeGraphPathComparison

    if ($Kind -ceq 'index') {
        if ([IO.Path]::GetFileName($target) -cne '.codegraph') {
            throw 'cleanup index name mismatch'
        }
        $worktree = [IO.Path]::GetDirectoryName($target).TrimEnd('\', '/')
        $gitRoot = @(& git -C $worktree rev-parse --show-toplevel 2>$null)
        if ($LASTEXITCODE -ne 0 -or $gitRoot.Count -ne 1) {
            throw 'cleanup worktree is unavailable'
        }
        $canonicalWorktree = [IO.Path]::GetFullPath($gitRoot[0].Trim()).TrimEnd('\', '/')
        if (-not $canonicalWorktree.Equals($worktree, $comparison)) {
            throw 'cleanup worktree mismatch'
        }
        $confirmedWorktree = [IO.Path]::GetFullPath($Confirmation).TrimEnd('\', '/')
        if (-not $confirmedWorktree.Equals($canonicalWorktree, $comparison)) {
            throw 'cleanup confirmation mismatch'
        }
    } else {
        if ([string]::IsNullOrWhiteSpace($ManagedCacheRoot)) {
            throw 'cleanup managed cache root is empty'
        }
        $managedRoot = [IO.Path]::GetFullPath($ManagedCacheRoot).TrimEnd('\', '/')
        if ($managedRoot -ceq [IO.Path]::GetPathRoot($managedRoot).TrimEnd('\', '/')) {
            throw 'cleanup bundle scope mismatch'
        }
        if (-not (Test-Topic05CodeGraphPathInside -Candidate $target -Root $managedRoot)) {
            throw 'cleanup bundle scope mismatch'
        }
        $relative = $target.Substring($managedRoot.Length).TrimStart('\', '/').Replace('\', '/')
        $segments = @($relative.Split('/'))
        if ($segments.Count -ne 2 -or $segments[0] -cne 'v1.5.0' -or
            $segments[1] -cnotmatch '^(darwin|linux|win32)-(arm64|x64)$') {
            throw 'cleanup bundle scope mismatch'
        }
        $receiptPath = Join-Path $target 'receipt.json'
        $receipt = Read-Topic05CodeGraphReceipt -LiteralPath $receiptPath
        if ($receipt.version -cne '1.5.0' -or $receipt.platform -cne $segments[1] -or
            -not ([IO.Path]::GetFullPath([string]$receipt.bundle_root).TrimEnd('\', '/').Equals(
                $target,
                $comparison
            )) -or
            -not ([IO.Path]::GetFullPath([string]$receipt.receipt_path).TrimEnd('\', '/').Equals(
                [IO.Path]::GetFullPath($receiptPath),
                $comparison
            ))) {
            throw 'cleanup bundle receipt mismatch'
        }
        $expectedConfirmation = "v1.5.0:$($receipt.platform):$($receipt.artifact.sha256)"
        if ($Confirmation -cne $expectedConfirmation) {
            throw 'cleanup confirmation mismatch'
        }
    }

    $files = @(Get-ChildItem -LiteralPath $target -File -Force -Recurse)
    $bytes = [long](($files | Measure-Object -Property Length -Sum).Sum)
    return [ordered]@{
        schema_version = 1
        status = 'planned'
        apply = $false
        kind = $Kind
        target = $target
        file_count = $files.Count
        bytes = $bytes
        trash_path = $null
    }
}

function Invoke-Topic05CodeGraphCleanup {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [ValidateSet('bundle', 'index')]
        [string]$Kind,

        [Parameter(Mandatory)][string]$LiteralPath,
        [Parameter(Mandatory)][string]$Confirmation,
        [string]$ManagedCacheRoot = (Get-Topic05CodeGraphManagedCacheRoot),
        [switch]$Apply
    )

    $result = Get-Topic05CodeGraphCleanupPlan -Kind $Kind -LiteralPath $LiteralPath `
        -Confirmation $Confirmation -ManagedCacheRoot $ManagedCacheRoot
    if (-not $Apply) { return $result }

    $trash = $result.target + '.trash-' + [DateTime]::UtcNow.ToString('yyyyMMddTHHmmssfffZ') + '-' +
        [guid]::NewGuid().ToString('N')
    if (Test-Path -LiteralPath $trash) { throw 'cleanup trash conflict' }
    [IO.Directory]::Move($result.target, $trash)
    $result['status'] = 'moved_to_recoverable_trash'
    $result['apply'] = $true
    $result['trash_path'] = $trash
    return $result
}
