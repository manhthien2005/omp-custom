#Requires -Version 5.1
[CmdletBinding()]
param()

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$repositoryRoot = (Resolve-Path (Join-Path $PSScriptRoot '..\..')).Path
$lockPath = Join-Path $repositoryRoot 'template\.omp\codegraph\upstream-lock.json'
$componentManifestPath = Join-Path $repositoryRoot 'template\.omp\codegraph\component-manifest.json'
$templateRoot = Join-Path $repositoryRoot 'template'
$libraryPath = Join-Path $repositoryRoot 'scripts\lib\topic05-codegraph.ps1'
$provisionPath = Join-Path $repositoryRoot 'scripts\provision-codegraph.ps1'
$cleanupPath = Join-Path $repositoryRoot 'scripts\cleanup-codegraph.ps1'
$tempBase = [IO.Path]::GetFullPath([IO.Path]::GetTempPath()).TrimEnd('\', '/')
$tempPrefix = 'omp-topic05-provision-'
$script:TempRoots = New-Object 'System.Collections.Generic.List[string]'
$script:Passed = 0
$script:Failed = 0

function Assert-Topic05Provision {
    param(
        [Parameter(Mandatory)][bool]$Condition,
        [Parameter(Mandatory)][string]$Message
    )
    if (-not $Condition) { throw $Message }
}

function Assert-Topic05ExactPropertySet {
    param(
        [Parameter(Mandatory)][object]$Value,
        [Parameter(Mandatory)][string[]]$Expected,
        [Parameter(Mandatory)][string]$Context
    )

    $actual = @($Value.PSObject.Properties.Name | Sort-Object)
    $wanted = @($Expected | Sort-Object)
    Assert-Topic05Provision (($actual -join '|') -ceq ($wanted -join '|')) `
        "$Context property set mismatch: $($actual -join ', ')"
}

function Invoke-Topic05ProvisionTest {
    param(
        [Parameter(Mandatory)][string]$Name,
        [Parameter(Mandatory)][scriptblock]$Body
    )

    try {
        & $Body
        $script:Passed++
        Write-Host "PASS $Name" -ForegroundColor Green
    } catch {
        $script:Failed++
        Write-Host "FAIL $Name :: $($_.Exception.Message)" -ForegroundColor Red
    }
}

function New-Topic05ProvisionRoot {
    $path = Join-Path $tempBase ($tempPrefix + [guid]::NewGuid().ToString('N'))
    [void](New-Item -ItemType Directory -Path $path)
    [void]$script:TempRoots.Add([IO.Path]::GetFullPath($path))
    return $path
}

function Remove-Topic05ProvisionRoots {
    foreach ($path in @($script:TempRoots)) {
        $resolved = [IO.Path]::GetFullPath($path).TrimEnd('\', '/')
        $parent = [IO.Path]::GetDirectoryName($resolved).TrimEnd('\', '/')
        $leaf = [IO.Path]::GetFileName($resolved)
        if ($parent -cne $tempBase -or -not $leaf.StartsWith($tempPrefix, [StringComparison]::Ordinal)) {
            throw "Refusing unsafe Topic 05 test cleanup target: $resolved"
        }
        if (Test-Path -LiteralPath $resolved) {
            Remove-Item -LiteralPath $resolved -Recurse -Force
        }
    }
}

function Get-Topic05TreeFingerprint {
    param([Parameter(Mandatory)][string]$LiteralPath)
    if (-not (Test-Path -LiteralPath $LiteralPath)) { return '<absent>' }

    $root = [IO.Path]::GetFullPath($LiteralPath).TrimEnd('\', '/')
    $rows = foreach ($item in Get-ChildItem -LiteralPath $root -Force -Recurse | Sort-Object FullName) {
        $relative = $item.FullName.Substring($root.Length).TrimStart('\', '/')
        if ($item.PSIsContainer) {
            "D|$relative"
        } else {
            "F|$relative|$((Get-FileHash -LiteralPath $item.FullName -Algorithm SHA256).Hash)"
        }
    }
    return $rows -join "`n"
}

function Assert-Topic05Throws {
    param(
        [Parameter(Mandatory)][scriptblock]$Body,
        [Parameter(Mandatory)][string]$MessagePattern,
        [string]$Context = 'operation'
    )

    $caught = $null
    try { & $Body } catch { $caught = $_ }
    Assert-Topic05Provision ($null -ne $caught) "[$Context] expected failure matching: $MessagePattern"
    Assert-Topic05Provision ($caught.Exception.Message -like $MessagePattern) `
        "[$Context] unexpected failure: $($caught.Exception.Message)"
}

function New-Topic05FakeBundleArchive {
    param(
        [Parameter(Mandatory)][string]$Root,
        [string[]]$Omit = @(),
        [string[]]$ExtraEntries = @()
    )

    Add-Type -AssemblyName System.IO.Compression.FileSystem
    $bundle = Join-Path $Root (
        'bundle-source-' + [guid]::NewGuid().ToString('N') + '\codegraph-win32-x64'
    )
    foreach ($relative in @(
        'bin\codegraph.cmd',
        'node.exe',
        'lib\package.json',
        'lib\dist\index.js',
        'lib\dist\bin\codegraph.js'
    )) {
        if ($Omit -contains $relative) { continue }
        $path = Join-Path $bundle $relative
        [void](New-Item -ItemType Directory -Path (Split-Path -Parent $path) -Force)
        $value = if ($relative -ceq 'lib\package.json') { '{"name":"codegraph","version":"1.5.0"}' } else { "fixture:$relative" }
        Set-Content -LiteralPath $path -Value $value -Encoding UTF8 -NoNewline
    }

    $archive = Join-Path $Root ('codegraph-win32-x64-' + [guid]::NewGuid().ToString('N') + '.zip')
    $zip = [IO.Compression.ZipFile]::Open($archive, [IO.Compression.ZipArchiveMode]::Create)
    try {
        if (Test-Path -LiteralPath $bundle) {
            foreach ($file in Get-ChildItem -LiteralPath $bundle -File -Recurse | Sort-Object FullName) {
                $relative = $file.FullName.Substring($bundle.Length).TrimStart('\', '/').Replace('\', '/')
                [IO.Compression.ZipFileExtensions]::CreateEntryFromFile(
                    $zip,
                    $file.FullName,
                    "codegraph-win32-x64/$relative",
                    [IO.Compression.CompressionLevel]::NoCompression
                ) | Out-Null
            }
        }
        foreach ($entryName in $ExtraEntries) {
            $entry = $zip.CreateEntry($entryName)
            $writer = [IO.StreamWriter]::new($entry.Open(), [Text.UTF8Encoding]::new($false))
            try { $writer.Write('extra') } finally { $writer.Dispose() }
        }
    } finally {
        $zip.Dispose()
    }
    return $archive
}

function New-Topic05FixtureLock {
    param(
        [Parameter(Mandatory)][string]$Root,
        [Parameter(Mandatory)][string]$ArtifactPath,
        [long]$SizeAdjustment = 0,
        [string]$Sha256
    )

    $document = Get-Content -Raw -LiteralPath $lockPath -Encoding UTF8 | ConvertFrom-Json
    $row = @($document.artifacts | Where-Object platform -CEQ 'win32-x64')[0]
    $artifact = Get-Item -LiteralPath $ArtifactPath
    $row.size = [long]$artifact.Length + $SizeAdjustment
    $row.sha256 = if ($Sha256) { $Sha256 } else {
        (Get-FileHash -LiteralPath $ArtifactPath -Algorithm SHA256).Hash.ToLowerInvariant()
    }
    $fixtureLock = Join-Path $Root ('lock-' + [guid]::NewGuid().ToString('N') + '.json')
    $document | ConvertTo-Json -Depth 10 | Set-Content -LiteralPath $fixtureLock -Encoding UTF8
    return $fixtureLock
}

function New-Topic05FakeTarGz {
    param(
        [Parameter(Mandatory)][string]$Root,
        [string]$UnsafeLinkTarget,
        [switch]$HardLink
    )

    $archive = Join-Path $Root ('codegraph-linux-x64-' + [guid]::NewGuid().ToString('N') + '.tar.gz')
    $file = [IO.File]::Open($archive, [IO.FileMode]::CreateNew, [IO.FileAccess]::Write, [IO.FileShare]::None)
    $gzip = [IO.Compression.GZipStream]::new($file, [IO.Compression.CompressionMode]::Compress, $true)
    $writer = [System.Formats.Tar.TarWriter]::new(
        $gzip,
        [System.Formats.Tar.TarEntryFormat]::Pax,
        $true
    )
    try {
        $entries = [ordered]@{
            'codegraph-linux-x64/bin/codegraph' = 'launcher'
            'codegraph-linux-x64/node' = 'node'
            'codegraph-linux-x64/lib/package.json' = '{"name":"codegraph","version":"1.5.0"}'
            'codegraph-linux-x64/lib/dist/index.js' = 'library'
            'codegraph-linux-x64/lib/dist/bin/codegraph.js' = 'cli'
        }
        foreach ($entry in $entries.GetEnumerator()) {
            $tarEntry = [System.Formats.Tar.PaxTarEntry]::new(
                [System.Formats.Tar.TarEntryType]::RegularFile,
                $entry.Key
            )
            $bytes = [Text.UTF8Encoding]::new($false).GetBytes([string]$entry.Value)
            $stream = [IO.MemoryStream]::new($bytes, $false)
            try {
                $tarEntry.DataStream = $stream
                $writer.WriteEntry($tarEntry)
            } finally {
                $stream.Dispose()
            }
        }
        if ($UnsafeLinkTarget) {
            $entryType = if ($HardLink) {
                [System.Formats.Tar.TarEntryType]::HardLink
            } else {
                [System.Formats.Tar.TarEntryType]::SymbolicLink
            }
            $link = [System.Formats.Tar.PaxTarEntry]::new(
                $entryType,
                'codegraph-linux-x64/lib/unsafe-link'
            )
            $link.LinkName = $UnsafeLinkTarget
            $writer.WriteEntry($link)
        }
    } finally {
        $writer.Dispose()
        $gzip.Dispose()
        $file.Dispose()
    }
    return $archive
}

try {
$expectedArtifacts = [ordered]@{
    'darwin-arm64' = [ordered]@{
        name = 'codegraph-darwin-arm64.tar.gz'
        size = 56627196
        sha256 = 'cf5ee435a6e44d097b2f98f2b7b8b9422bb1094844404efed82519c5da1af2cf'
    }
    'darwin-x64' = [ordered]@{
        name = 'codegraph-darwin-x64.tar.gz'
        size = 57729407
        sha256 = '0a0ccc29bf7da9d10be1458d89d7e15c55927ae24cd95e9fa3de4bdfea059dde'
    }
    'linux-arm64' = [ordered]@{
        name = 'codegraph-linux-arm64.tar.gz'
        size = 61327175
        sha256 = '9f17750aedf45d51f68caae39ed21d6e2a7290b2326e5c53f95a165918ebd1d8'
    }
    'linux-x64' = [ordered]@{
        name = 'codegraph-linux-x64.tar.gz'
        size = 61744667
        sha256 = '2ba65e87a1210b706bb1e67d5e48b5fc4a1935e43dbb3fb5f31c5597840d2e58'
    }
    'win32-arm64' = [ordered]@{
        name = 'codegraph-win32-arm64.zip'
        size = 48389210
        sha256 = 'de125e792b5eed7dee8def2ab9bd7e762f372012f75f595e59d3b0c8714b0d55'
    }
    'win32-x64' = [ordered]@{
        name = 'codegraph-win32-x64.zip'
        size = 52398062
        sha256 = 'd6798622b4f44ee6757c94335f437ee27a9ff7d3537b554cb6a2b3baf11bc4a1'
    }
}

Invoke-Topic05ProvisionTest 'release lock exists as a regular file' {
    Assert-Topic05Provision (Test-Path -LiteralPath $lockPath -PathType Leaf) `
        'template/.omp/codegraph/upstream-lock.json is missing'
}

if (Test-Path -LiteralPath $lockPath -PathType Leaf) {
    $lock = Get-Content -Raw -LiteralPath $lockPath -Encoding UTF8 | ConvertFrom-Json

    Invoke-Topic05ProvisionTest 'release identity and license are exact' {
        Assert-Topic05ExactPropertySet -Value $lock -Context 'lock' -Expected @(
            'schema_version', 'upstream', 'release_url', 'version', 'tag', 'commit', 'license',
            'license_file', 'download_origin', 'allowed_final_hosts', 'checksum_asset', 'artifacts'
        )
        Assert-Topic05Provision ($lock.schema_version -eq 1) 'lock schema must be 1'
        Assert-Topic05Provision ($lock.upstream -ceq 'colbymchenry/codegraph') 'upstream must be exact'
        Assert-Topic05Provision ($lock.release_url -ceq 'https://github.com/colbymchenry/codegraph/releases/tag/v1.5.0') `
            'release URL must be exact'
        Assert-Topic05Provision ($lock.version -ceq '1.5.0') 'version must be exact'
        Assert-Topic05Provision ($lock.tag -ceq 'v1.5.0') 'tag must be exact'
        Assert-Topic05Provision ($lock.commit -ceq 'ea72e1b190921232aa7bd02e96bef5bbe4fe0ab6') `
            'commit must be exact'
        Assert-Topic05Provision ($lock.license -ceq 'MIT') 'license must be MIT'
        Assert-Topic05ExactPropertySet -Value $lock.license_file -Context 'license_file' `
            -Expected @('repository_path', 'sha256')
        Assert-Topic05Provision ($lock.license_file.repository_path -ceq 'LICENSE') `
            'license repository path must be exact'
        Assert-Topic05Provision (
            $lock.license_file.sha256 -ceq 'e6d98f98c666bebe065ac2492a0a19232cc318d4d67bac3ca42ffb77bacc8809'
        ) 'license digest must be exact'
    }

    Invoke-Topic05ProvisionTest 'download origin and checksum authority are closed' {
        Assert-Topic05Provision (
            $lock.download_origin -ceq 'https://github.com/colbymchenry/codegraph/releases/download/v1.5.0/'
        ) 'download origin must be exact'
        Assert-Topic05Provision (
            (@($lock.allowed_final_hosts) -join '|') -ceq 'github.com|release-assets.githubusercontent.com'
        ) 'allowed redirect hosts must be exact'
        Assert-Topic05ExactPropertySet -Value $lock.checksum_asset -Context 'checksum_asset' `
            -Expected @('name', 'sha256')
        Assert-Topic05Provision ($lock.checksum_asset.name -ceq 'SHA256SUMS') `
            'checksum asset name must be exact'
        Assert-Topic05Provision (
            $lock.checksum_asset.sha256 -ceq '434166207a163b5fe40f0052df5ea20be1e4ba56d7b4eaa00795cc75c8c0f3ed'
        ) 'checksum asset digest must be exact'
    }

    Invoke-Topic05ProvisionTest 'all six platform artifacts have exact immutable metadata' {
        $artifacts = @($lock.artifacts)
        Assert-Topic05Provision ($artifacts.Count -eq 6) 'all six release platforms are required'
        Assert-Topic05Provision ((@($artifacts.platform | Sort-Object -Unique)).Count -eq 6) `
            'artifact platforms must be unique'
        Assert-Topic05Provision ((@($artifacts.name | Sort-Object -Unique)).Count -eq 6) `
            'artifact names must be unique'

        foreach ($platform in $expectedArtifacts.Keys) {
            $rows = @($artifacts | Where-Object platform -CEQ $platform)
            Assert-Topic05Provision ($rows.Count -eq 1) "platform must occur exactly once: $platform"
            $row = $rows[0]
            $expected = $expectedArtifacts[$platform]
            Assert-Topic05ExactPropertySet -Value $row -Context "artifact $platform" `
                -Expected @('platform', 'name', 'size', 'sha256')
            Assert-Topic05Provision ($row.name -ceq $expected.name) "artifact name mismatch: $platform"
            Assert-Topic05Provision ([long]$row.size -eq [long]$expected.size -and [long]$row.size -gt 0) `
                "artifact size mismatch: $platform"
            Assert-Topic05Provision ($row.sha256 -ceq $expected.sha256) "artifact digest mismatch: $platform"
            Assert-Topic05Provision ($row.sha256 -cmatch '^[0-9a-f]{64}$') `
                "artifact digest format mismatch: $platform"
        }
    }
}

Invoke-Topic05ProvisionTest 'provisioning library and entry points exist' {
    Assert-Topic05Provision (Test-Path -LiteralPath $libraryPath -PathType Leaf) `
        'scripts/lib/topic05-codegraph.ps1 is missing'
    Assert-Topic05Provision (Test-Path -LiteralPath $provisionPath -PathType Leaf) `
        'scripts/provision-codegraph.ps1 is missing'
    Assert-Topic05Provision (Test-Path -LiteralPath $cleanupPath -PathType Leaf) `
        'scripts/cleanup-codegraph.ps1 is missing'
}

Invoke-Topic05ProvisionTest 'network stream copy is output-silent before final URI publication' {
    $librarySource = Get-Content -Raw -LiteralPath $libraryPath -Encoding UTF8
    Assert-Topic05Provision ($librarySource.Contains(
        '[void]$response.Content.CopyToAsync($output).GetAwaiter().GetResult()'
    )) 'network copy may leak a Task result and turn the final URI into Object[]'
}

if (Test-Path -LiteralPath $libraryPath -PathType Leaf) {
    . $libraryPath

    Invoke-Topic05ProvisionTest 'component manifest closes dependencies source bytes and generated records' {
        $component = Read-Topic05CodeGraphComponentManifest `
            -LiteralPath $componentManifestPath -TemplateRoot $templateRoot
        Assert-Topic05ExactPropertySet -Value $component -Context 'component manifest' -Expected @(
            'schema_version', 'record_type', 'component', 'component_version', 'minimum_pwsh_version',
            'requires', 'upstream_lock', 'files', 'generated_target_files'
        )
        Assert-Topic05Provision ($component.component -ceq 'codegraph') 'component name must be exact'
        Assert-Topic05Provision ((@($component.files).Count) -eq 6) 'component source set must contain six files'
        Assert-Topic05Provision ((@($component.generated_target_files) -join '|') -ceq
            '.omp/codegraph/runtime.json|.omp/codegraph/install-record.json') `
            'generated target record set must be exact'
    }

    $script:ProbeVersion = '1.5.0'
    $script:ProbeNodePath = $null
    $script:ProbeCliPath = $null

    function Invoke-Topic05CodeGraphVersionProbe {
        param(
            [Parameter(Mandatory)][string]$NodePath,
            [Parameter(Mandatory)][string]$CliPath
        )
        $script:ProbeNodePath = $NodePath
        $script:ProbeCliPath = $CliPath
        return $script:ProbeVersion
    }

    $script:RealDownload = (Get-Command Invoke-Topic05CodeGraphDownload).ScriptBlock
    $script:DownloadSource = $null
    $script:DownloadFinalUri = 'https://release-assets.githubusercontent.com/fixture/codegraph.zip'
    $script:DownloadRequestUri = $null
    $script:DownloadAllowedHosts = @()

    function Invoke-Topic05CodeGraphDownload {
        param(
            [Parameter(Mandatory)][uri]$Uri,
            [Parameter(Mandatory)][string]$Destination,
            [Parameter(Mandatory)][string[]]$AllowedFinalHosts
        )
        $script:DownloadRequestUri = $Uri.AbsoluteUri
        $script:DownloadAllowedHosts = @($AllowedFinalHosts)
        Copy-Item -LiteralPath $script:DownloadSource -Destination $Destination
        return $script:DownloadFinalUri
    }

    Invoke-Topic05ProvisionTest 'lock parser rejects unknown and duplicate authority' {
        $root = New-Topic05ProvisionRoot
        $archive = New-Topic05FakeBundleArchive -Root $root
        $fixtureLock = New-Topic05FixtureLock -Root $root -ArtifactPath $archive
        $valid = Read-Topic05CodeGraphLock -LiteralPath $fixtureLock
        Assert-Topic05Provision ($valid.version -ceq '1.5.0') 'valid fixture lock did not parse'

        $unknown = Get-Content -Raw -LiteralPath $fixtureLock | ConvertFrom-Json
        $unknown | Add-Member -NotePropertyName unexpected -NotePropertyValue $true
        $unknownPath = Join-Path $root 'unknown.json'
        $unknown | ConvertTo-Json -Depth 10 | Set-Content -LiteralPath $unknownPath -Encoding UTF8
        Assert-Topic05Throws -MessagePattern '*unknown*' -Body {
            Read-Topic05CodeGraphLock -LiteralPath $unknownPath | Out-Null
        }

        $duplicate = Get-Content -Raw -LiteralPath $fixtureLock | ConvertFrom-Json
        $duplicate.artifacts = @($duplicate.artifacts) + @($duplicate.artifacts[0])
        $duplicatePath = Join-Path $root 'duplicate.json'
        $duplicate | ConvertTo-Json -Depth 10 | Set-Content -LiteralPath $duplicatePath -Encoding UTF8
        Assert-Topic05Throws -MessagePattern '*duplicate*' -Body {
            Read-Topic05CodeGraphLock -LiteralPath $duplicatePath | Out-Null
        }
    }

    Invoke-Topic05ProvisionTest 'platform selection is exact for this runtime' {
        $expectedPlatform = if ([Runtime.InteropServices.RuntimeInformation]::IsOSPlatform(
            [Runtime.InteropServices.OSPlatform]::Windows
        )) {
            if ([Runtime.InteropServices.RuntimeInformation]::OSArchitecture -eq
                [Runtime.InteropServices.Architecture]::Arm64) { 'win32-arm64' } else { 'win32-x64' }
        } elseif ([Runtime.InteropServices.RuntimeInformation]::IsOSPlatform(
            [Runtime.InteropServices.OSPlatform]::OSX
        )) {
            if ([Runtime.InteropServices.RuntimeInformation]::OSArchitecture -eq
                [Runtime.InteropServices.Architecture]::Arm64) { 'darwin-arm64' } else { 'darwin-x64' }
        } else {
            if ([Runtime.InteropServices.RuntimeInformation]::OSArchitecture -eq
                [Runtime.InteropServices.Architecture]::Arm64) { 'linux-arm64' } else { 'linux-x64' }
        }
        Assert-Topic05Provision ((Get-Topic05CodeGraphPlatform) -ceq $expectedPlatform) `
            'platform mapping does not match RuntimeInformation'
    }

    Invoke-Topic05ProvisionTest 'managed cache root is exact and rejects empty or filesystem-root profiles' {
        $root = New-Topic05ProvisionRoot
        $expected = [IO.Path]::GetFullPath((Join-Path $root '.omp\cache\codegraph'))
        Assert-Topic05Provision (
            (Get-Topic05CodeGraphManagedCacheRoot -UserProfilePath $root) -ceq $expected
        ) 'managed cache root is not profile-scoped'
        Assert-Topic05Throws -MessagePattern '*empty*' -Body {
            Get-Topic05CodeGraphManagedCacheRoot -UserProfilePath ' ' | Out-Null
        }
        Assert-Topic05Throws -MessagePattern '*filesystem root*' -Body {
            Get-Topic05CodeGraphManagedCacheRoot -UserProfilePath ([IO.Path]::GetPathRoot($root)) | Out-Null
        }
    }

    Invoke-Topic05ProvisionTest 'offline and network acquisition modes are closed and mutually exclusive' {
        $root = New-Topic05ProvisionRoot
        $archive = New-Topic05FakeBundleArchive -Root $root
        $fixtureLock = New-Topic05FixtureLock -Root $root -ArtifactPath $archive
        Assert-Topic05Throws -MessagePattern '*mutually exclusive*' -Body {
            Install-Topic05CodeGraphBundle -LockPath $fixtureLock -CacheRoot (Join-Path $root 'both') `
                -ArtifactPath $archive -AllowNetwork | Out-Null
        }
        Assert-Topic05Throws -MessagePattern '*explicitly allowed*' -Body {
            Install-Topic05CodeGraphBundle -LockPath $fixtureLock -CacheRoot (Join-Path $root 'neither') |
                Out-Null
        }
        Assert-Topic05Provision (-not (Test-Path -LiteralPath (Join-Path $root 'both'))) `
            'invalid mixed acquisition created cache bytes'
        Assert-Topic05Provision (-not (Test-Path -LiteralPath (Join-Path $root 'neither'))) `
            'missing acquisition permission created cache bytes'
    }

    Invoke-Topic05ProvisionTest 'tar.gz extraction accepts regular files and rejects escaping or hard links' {
        $root = New-Topic05ProvisionRoot
        $valid = New-Topic05FakeTarGz -Root $root
        $destination = Join-Path $root 'tar-valid'
        [void](New-Item -ItemType Directory -Path $destination)
        Expand-Topic05CodeGraphTarGz -ArchivePath $valid -Destination $destination `
            -ExpectedTopLevel 'codegraph-linux-x64'
        Assert-Topic05Provision (Test-Path -LiteralPath (Join-Path $destination 'lib\dist\index.js') -PathType Leaf) `
            'valid tar.gz was not extracted'

        $escaping = New-Topic05FakeTarGz -Root $root -UnsafeLinkTarget '../../escape'
        Assert-Topic05Throws -MessagePattern '*link*escapes*' -Body {
            Expand-Topic05CodeGraphTarGz -ArchivePath $escaping -Destination (Join-Path $root 'tar-escape') `
                -ExpectedTopLevel 'codegraph-linux-x64'
        }
        $hardLink = New-Topic05FakeTarGz -Root $root -UnsafeLinkTarget 'target' -HardLink
        Assert-Topic05Throws -MessagePattern '*hard links*not supported*' -Body {
            Expand-Topic05CodeGraphTarGz -ArchivePath $hardLink -Destination (Join-Path $root 'tar-hardlink') `
                -ExpectedTopLevel 'codegraph-linux-x64'
        }
    }

    if ((Get-Topic05CodeGraphPlatform) -ceq 'win32-x64') {
        Invoke-Topic05ProvisionTest 'offline archive publishes one verified receipt atomically' {
            $root = New-Topic05ProvisionRoot
            $archive = New-Topic05FakeBundleArchive -Root $root
            $fixtureLock = New-Topic05FixtureLock -Root $root -ArtifactPath $archive
            $cache = Join-Path $root 'cache'
            $receipt = Install-Topic05CodeGraphBundle -LockPath $fixtureLock -CacheRoot $cache `
                -ArtifactPath $archive

            $final = Join-Path $cache 'v1.5.0\win32-x64'
            Assert-Topic05Provision (([IO.Path]::GetFullPath($receipt.bundle_root)) -ceq ([IO.Path]::GetFullPath($final))) `
                'receipt bundle_root is not the final managed path'
            Assert-Topic05Provision (Test-Path -LiteralPath $receipt.receipt_path -PathType Leaf) `
                'receipt file was not published last'
            Assert-Topic05Provision ($receipt.artifact.sha256 -ceq (
                (Get-FileHash -LiteralPath $archive -Algorithm SHA256).Hash.ToLowerInvariant()
            )) 'receipt artifact digest mismatch'
            Assert-Topic05Provision ($receipt.bundle_tree_sha256 -cmatch '^[0-9a-f]{64}$') `
                'bundle tree hash is invalid'
            $probeRoot = Split-Path -Parent $script:ProbeNodePath
            Assert-Topic05Provision (
                $probeRoot.StartsWith((Join-Path $cache 'v1.5.0\win32-x64.staging-'), [StringComparison]::OrdinalIgnoreCase)
            ) 'version probe did not run inside the confined staging root'
            Assert-Topic05Provision ($script:ProbeNodePath -ceq (Join-Path $probeRoot 'node.exe')) `
                'version probe did not receive the staged vendored Node path'
            Assert-Topic05Provision ($script:ProbeCliPath -ceq (Join-Path $probeRoot 'lib\dist\bin\codegraph.js')) `
                'version probe did not receive the staged CLI entry path'
            Assert-Topic05Provision (@(Get-ChildItem -LiteralPath $cache -Directory -Filter '*.staging-*').Count -eq 0) `
                'successful publication left staging directories'
        }

        Invoke-Topic05ProvisionTest 'missing size-mismatched and digest-mismatched archives leave no cache' {
            $root = New-Topic05ProvisionRoot
            $archive = New-Topic05FakeBundleArchive -Root $root
            $validLock = New-Topic05FixtureLock -Root $root -ArtifactPath $archive

            foreach ($case in @(
                [pscustomobject]@{ Name = 'missing'; Path = (Join-Path $root 'missing.zip'); Lock = $validLock; Pattern = '*artifact*not*found*' },
                [pscustomobject]@{ Name = 'size'; Path = $archive; Lock = (New-Topic05FixtureLock -Root $root -ArtifactPath $archive -SizeAdjustment 1); Pattern = '*size*mismatch*' },
                [pscustomobject]@{ Name = 'digest'; Path = $archive; Lock = (New-Topic05FixtureLock -Root $root -ArtifactPath $archive -Sha256 ('0' * 64)); Pattern = '*digest*mismatch*' }
            )) {
                $cache = Join-Path $root ("cache-" + $case.Name)
                Assert-Topic05Throws -MessagePattern $case.Pattern -Body {
                    Install-Topic05CodeGraphBundle -LockPath $case.Lock -CacheRoot $cache `
                        -ArtifactPath $case.Path | Out-Null
                }
                Assert-Topic05Provision ((Get-Topic05TreeFingerprint -LiteralPath $cache) -ceq '<absent>') `
                    "$($case.Name) failure changed the cache"
            }
        }

        Invoke-Topic05ProvisionTest 'archive traversal and multiple roots are rejected before publication' {
            $root = New-Topic05ProvisionRoot
            foreach ($entry in @('../escape.txt', '/absolute.txt', 'C:/drive.txt', 'second-root/file.txt')) {
                $archive = New-Topic05FakeBundleArchive -Root $root -ExtraEntries @($entry)
                $fixtureLock = New-Topic05FixtureLock -Root $root -ArtifactPath $archive
                $cache = Join-Path $root ('cache-' + [guid]::NewGuid().ToString('N'))
                Assert-Topic05Throws -MessagePattern '*archive*' -Body {
                    Install-Topic05CodeGraphBundle -LockPath $fixtureLock -CacheRoot $cache `
                        -ArtifactPath $archive | Out-Null
                }
                Assert-Topic05Provision ((Get-Topic05TreeFingerprint -LiteralPath $cache) -ceq '<absent>') `
                    "unsafe entry changed cache: $entry"
            }
        }

        Invoke-Topic05ProvisionTest 'missing required bundle files and wrong version are rejected' {
            $root = New-Topic05ProvisionRoot
            foreach ($missing in @(
                'bin\codegraph.cmd', 'node.exe', 'lib\package.json',
                'lib\dist\index.js', 'lib\dist\bin\codegraph.js'
            )) {
                $archive = New-Topic05FakeBundleArchive -Root $root -Omit @($missing)
                $fixtureLock = New-Topic05FixtureLock -Root $root -ArtifactPath $archive
                Assert-Topic05Throws -Context $missing -MessagePattern '*required*' -Body {
                    Install-Topic05CodeGraphBundle -LockPath $fixtureLock `
                        -CacheRoot (Join-Path $root ('cache-' + [guid]::NewGuid().ToString('N'))) `
                        -ArtifactPath $archive | Out-Null
                }
            }

            $archive = New-Topic05FakeBundleArchive -Root $root
            $fixtureLock = New-Topic05FixtureLock -Root $root -ArtifactPath $archive
            $script:ProbeVersion = '1.4.9'
            try {
                Assert-Topic05Throws -MessagePattern '*version*mismatch*' -Body {
                    Install-Topic05CodeGraphBundle -LockPath $fixtureLock `
                        -CacheRoot (Join-Path $root 'wrong-version-cache') -ArtifactPath $archive | Out-Null
                }
            } finally {
                $script:ProbeVersion = '1.5.0'
            }
        }

        Invoke-Topic05ProvisionTest 'valid cache reuse is stable and a conflicting cache is never overwritten' {
            $root = New-Topic05ProvisionRoot
            $archive = New-Topic05FakeBundleArchive -Root $root
            $fixtureLock = New-Topic05FixtureLock -Root $root -ArtifactPath $archive
            $cache = Join-Path $root 'cache'
            $first = Install-Topic05CodeGraphBundle -LockPath $fixtureLock -CacheRoot $cache `
                -ArtifactPath $archive
            $receiptBefore = Get-Content -Raw -LiteralPath $first.receipt_path
            $receiptTimeBefore = (Get-Item -LiteralPath $first.receipt_path).LastWriteTimeUtc
            Start-Sleep -Milliseconds 30
            $second = Install-Topic05CodeGraphBundle -LockPath $fixtureLock -CacheRoot $cache `
                -ArtifactPath $archive
            Assert-Topic05Provision ((Get-Content -Raw -LiteralPath $second.receipt_path) -ceq $receiptBefore) `
                'cache reuse rewrote receipt bytes'
            Assert-Topic05Provision ((Get-Item -LiteralPath $second.receipt_path).LastWriteTimeUtc -eq $receiptTimeBefore) `
                'cache reuse rewrote receipt timestamp'

            Set-Content -LiteralPath (Join-Path $first.bundle_root 'lib\dist\index.js') `
                -Value 'tampered' -Encoding UTF8 -NoNewline
            $conflictBefore = Get-Topic05TreeFingerprint -LiteralPath $first.bundle_root
            Assert-Topic05Throws -MessagePattern '*conflict*' -Body {
                Install-Topic05CodeGraphBundle -LockPath $fixtureLock -CacheRoot $cache `
                    -ArtifactPath $archive | Out-Null
            }
            Assert-Topic05Provision (
                (Get-Topic05TreeFingerprint -LiteralPath $first.bundle_root) -ceq $conflictBefore
            ) 'conflicting cache was overwritten'
        }

        Invoke-Topic05ProvisionTest 'network acquisition consumes only the locked URL and allowed final host' {
            $root = New-Topic05ProvisionRoot
            $archive = New-Topic05FakeBundleArchive -Root $root
            $fixtureLock = New-Topic05FixtureLock -Root $root -ArtifactPath $archive
            $script:DownloadSource = $archive
            $script:DownloadFinalUri = 'https://release-assets.githubusercontent.com/fixture/codegraph.zip'
            $receipt = Install-Topic05CodeGraphBundle -LockPath $fixtureLock `
                -CacheRoot (Join-Path $root 'network-cache') -AllowNetwork
            Assert-Topic05Provision (
                $script:DownloadRequestUri -ceq
                'https://github.com/colbymchenry/codegraph/releases/download/v1.5.0/codegraph-win32-x64.zip'
            ) 'network request was not derived from the locked origin and artifact name'
            Assert-Topic05Provision (
                ($script:DownloadAllowedHosts -join '|') -ceq 'github.com|release-assets.githubusercontent.com'
            ) 'network acquisition did not receive the closed final-host set'
            Assert-Topic05Provision ($receipt.platform -ceq 'win32-x64') `
                'network acquisition did not publish the verified bundle'

            $script:DownloadFinalUri = 'https://example.invalid/redirected.zip'
            try {
                Assert-Topic05Throws -MessagePattern '*redirect host*not allowed*' -Body {
                    Install-Topic05CodeGraphBundle -LockPath $fixtureLock `
                        -CacheRoot (Join-Path $root 'bad-network-cache') -AllowNetwork | Out-Null
                }
            } finally {
                $script:DownloadFinalUri = 'https://release-assets.githubusercontent.com/fixture/codegraph.zip'
            }
            Assert-Topic05Provision (-not (Test-Path -LiteralPath (Join-Path $root 'bad-network-cache'))) `
                'disallowed final host left cache bytes'
        }

        Invoke-Topic05ProvisionTest 'cleanup planning accepts only an exact managed bundle or worktree index' {
            $root = New-Topic05ProvisionRoot
            $archive = New-Topic05FakeBundleArchive -Root $root
            $fixtureLock = New-Topic05FixtureLock -Root $root -ArtifactPath $archive
            $profile = Join-Path $root 'profile'
            $managed = Join-Path $profile '.omp\cache\codegraph'
            $receipt = Install-Topic05CodeGraphBundle -LockPath $fixtureLock -CacheRoot $managed `
                -ArtifactPath $archive
            $confirmation = "v1.5.0:$($receipt.platform):$($receipt.artifact.sha256)"
            $bundlePlan = Get-Topic05CodeGraphCleanupPlan -Kind bundle `
                -LiteralPath $receipt.bundle_root -Confirmation $confirmation -ManagedCacheRoot $managed
            Assert-Topic05Provision ($bundlePlan.kind -ceq 'bundle' -and $bundlePlan.apply -eq $false) `
                'exact managed bundle did not produce a dry cleanup plan'
            Assert-Topic05Throws -MessagePattern '*confirmation*mismatch*' -Body {
                Get-Topic05CodeGraphCleanupPlan -Kind bundle -LiteralPath $receipt.bundle_root `
                    -Confirmation 'wrong' -ManagedCacheRoot $managed | Out-Null
            }
            foreach ($unsafeTarget in @($profile, $managed, (Split-Path -Parent $receipt.bundle_root))) {
                Assert-Topic05Throws -Context $unsafeTarget -MessagePattern '*scope*mismatch*' -Body {
                    Get-Topic05CodeGraphCleanupPlan -Kind bundle -LiteralPath $unsafeTarget `
                        -Confirmation $confirmation -ManagedCacheRoot $managed | Out-Null
                }
            }

            $worktree = Join-Path $root 'worktree'
            [void](New-Item -ItemType Directory -Path $worktree)
            & git -C $worktree init --quiet
            Assert-Topic05Provision ($LASTEXITCODE -eq 0) 'fixture worktree initialization failed'
            $index = Join-Path $worktree '.codegraph'
            [void](New-Item -ItemType Directory -Path $index)
            Set-Content -LiteralPath (Join-Path $index 'cache.db') -Value 'cache' -NoNewline
            $indexPlan = Get-Topic05CodeGraphCleanupPlan -Kind index -LiteralPath $index `
                -Confirmation ([IO.Path]::GetFullPath($worktree)) -ManagedCacheRoot $managed
            Assert-Topic05Provision ($indexPlan.kind -ceq 'index' -and $indexPlan.file_count -eq 1) `
                'exact worktree index did not produce the expected cleanup plan'
            Assert-Topic05Throws -MessagePattern '*confirmation*mismatch*' -Body {
                Get-Topic05CodeGraphCleanupPlan -Kind index -LiteralPath $index `
                    -Confirmation $root -ManagedCacheRoot $managed | Out-Null
            }
            Assert-Topic05Throws -MessagePattern '*index*name*mismatch*' -Body {
                Get-Topic05CodeGraphCleanupPlan -Kind index -LiteralPath $worktree `
                    -Confirmation $worktree -ManagedCacheRoot $managed | Out-Null
            }

            $bundleBefore = Get-Topic05TreeFingerprint -LiteralPath $receipt.bundle_root
            $moved = Invoke-Topic05CodeGraphCleanup -Kind bundle -LiteralPath $receipt.bundle_root `
                -Confirmation $confirmation -ManagedCacheRoot $managed -Apply
            Assert-Topic05Provision ($moved.status -ceq 'moved_to_recoverable_trash' -and $moved.apply) `
                'confirmed bundle cleanup did not report a recoverable move'
            Assert-Topic05Provision (-not (Test-Path -LiteralPath $receipt.bundle_root)) `
                'confirmed bundle remained at its managed path'
            Assert-Topic05Provision (Test-Path -LiteralPath $moved.trash_path -PathType Container) `
                'confirmed bundle cleanup did not create recoverable trash'
            Assert-Topic05Provision (
                (Get-Topic05TreeFingerprint -LiteralPath $moved.trash_path) -ceq $bundleBefore
            ) 'recoverable bundle trash bytes differ from the managed bundle'
        }
    }
}

if (Test-Path -LiteralPath $provisionPath -PathType Leaf) {
    Invoke-Topic05ProvisionTest 'provision entry point defaults to a byte-inert dry run' {
        $root = New-Topic05ProvisionRoot
        $archive = New-Topic05FakeBundleArchive -Root $root
        $fixtureLock = New-Topic05FixtureLock -Root $root -ArtifactPath $archive
        $cache = Join-Path $root 'cache'
        $output = @(& pwsh -NoProfile -File $provisionPath -LockPath $fixtureLock `
            -CacheRoot $cache -ArtifactPath $archive 2>&1)
        Assert-Topic05Provision ($LASTEXITCODE -eq 0) "dry-run exit was $LASTEXITCODE"
        Assert-Topic05Provision ((Get-Topic05TreeFingerprint -LiteralPath $cache) -ceq '<absent>') `
            'dry-run created cache bytes'
        $plan = ($output -join "`n") | ConvertFrom-Json
        Assert-Topic05Provision ($plan.status -ceq 'planned' -and $plan.apply -eq $false) `
            'dry-run did not emit the closed plan result'
    }
}

if (Test-Path -LiteralPath $cleanupPath -PathType Leaf) {
    Invoke-Topic05ProvisionTest 'index cleanup is dry-run first and moves only the confirmed cache' {
        $root = New-Topic05ProvisionRoot
        & git -C $root init --quiet
        Assert-Topic05Provision ($LASTEXITCODE -eq 0) 'fixture git init failed'
        $index = Join-Path $root '.codegraph'
        [void](New-Item -ItemType Directory -Path $index)
        Set-Content -LiteralPath (Join-Path $index 'cache.db') -Value 'cache' -NoNewline
        $before = Get-Topic05TreeFingerprint -LiteralPath $index

        $preview = @(& pwsh -NoProfile -File $cleanupPath -Kind index -LiteralPath $index `
            -Confirmation ([IO.Path]::GetFullPath($root)) 2>&1)
        Assert-Topic05Provision ($LASTEXITCODE -eq 0) "cleanup preview failed: $($preview -join ' ')"
        Assert-Topic05Provision ((Get-Topic05TreeFingerprint -LiteralPath $index) -ceq $before) `
            'cleanup preview changed index bytes'

        $apply = @(& pwsh -NoProfile -File $cleanupPath -Kind index -LiteralPath $index `
            -Confirmation ([IO.Path]::GetFullPath($root)) -Apply 2>&1)
        Assert-Topic05Provision ($LASTEXITCODE -eq 0) "cleanup apply failed: $($apply -join ' ')"
        Assert-Topic05Provision (-not (Test-Path -LiteralPath $index)) 'confirmed index still exists'
        $trash = @(Get-ChildItem -LiteralPath $root -Directory -Filter '.codegraph.trash-*')
        Assert-Topic05Provision ($trash.Count -eq 1) 'cleanup did not create one recoverable trash directory'
        Assert-Topic05Provision ((Get-Topic05TreeFingerprint -LiteralPath $trash[0].FullName) -ceq $before) `
            'recoverable trash bytes differ from the original index'
    }
}

if ($script:Failed -gt 0) {
    Write-Host "FAIL Topic 05 provisioning lock ($($script:Passed) passed, $($script:Failed) failed)" `
        -ForegroundColor Red
    exit 1
}

Write-Host "PASS Topic 05 provisioning lock ($($script:Passed) cases)" -ForegroundColor Green
exit 0
} finally {
    Remove-Topic05ProvisionRoots
}
