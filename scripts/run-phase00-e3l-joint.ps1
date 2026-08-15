#Requires -Version 5.1

[CmdletBinding()]
param(
    [ValidateRange(5,999)][int]$Attempt = 5,
    [string]$Model = 'omniroute/codex/gpt-5.6-sol-high',
    [string]$OmpExecutable
)

Set-StrictMode -Version 2.0

$script:Phase00E3ILCliAttempt = $Attempt
$script:Phase00E3ILCliModel = $Model
$script:Phase00E3ILCliOmpExecutable = $OmpExecutable

$script:Phase00E3ILJointRoot = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path
. (Join-Path $PSScriptRoot 'run-phase00-e3i.ps1')
. (Join-Path $PSScriptRoot 'lib\phase00-e3l-evidence.ps1')

function Get-Phase00E3ILJointExpectedPaths {
    param(
        [Parameter(Mandatory)][string]$EvidenceRoot,
        [Parameter(Mandatory)][ValidateRange(5,999)][int]$Attempt
    )

    $e3iRaw = Join-Path $EvidenceRoot 'E3-I\raw'
    $e3lRaw = Join-Path $EvidenceRoot 'E3-L\raw'
    $paths = @()
    foreach ($session in @('a','b')) {
        $stem = "session-$session-attempt-{0:D3}" -f $Attempt
        $paths += @(
            Join-Path $e3iRaw "$stem.stdout.jsonl"
            Join-Path $e3iRaw "$stem.stderr.txt"
            Join-Path $e3iRaw "$stem.run.json"
        )
        $ids = if ($session -eq 'a') {
            @(
                'e3i-project-1','e3i-project-2','e3i-project-3',
                'e3i-runtime-1','e3i-runtime-2','e3i-runtime-3'
            )
        } else { @('e3i-cli-1','e3i-cli-2','e3i-cli-3') }
        $paths += @($ids | ForEach-Object {
            Join-Path $e3iRaw "$stem.canary.$_.jsonl"
        })
    }
    $paths += Join-Path $e3lRaw ("joint-attempt-{0:D3}.json" -f $Attempt)
    @($paths)
}

function Get-Phase00E3ILPinnedRuntimeIdentity {
    param([Parameter(Mandatory)][string]$OmpExecutable)

    $path = [IO.Path]::GetFullPath($OmpExecutable)
    if (-not (Test-Path -LiteralPath $path -PathType Leaf)) {
        throw "Pinned OMP executable does not exist: $path"
    }
    $sha256 = (Get-FileHash -Algorithm SHA256 -LiteralPath $path).Hash
    if ($sha256 -cne $script:Phase00E3LRuntimeSha256) {
        throw "Pinned OMP executable SHA-256 mismatch: $sha256"
    }
    $probe = Invoke-Phase00E3ICapturedProcess -FilePath $path `
        -Arguments @('--version') -WorkingDirectory $script:Phase00E3ILJointRoot `
        -Environment @{} -TimeoutSeconds 30
    $version = $probe.Stdout.Trim()
    if ($probe.TimedOut -or $probe.ExitCode -ne 0 -or
        $version -cne $script:Phase00E3LRuntimeVersion) {
        throw "Pinned OMP executable version mismatch: $version"
    }
    [pscustomobject][ordered]@{
        Path = $path
        Version = $version
        Sha256 = $sha256
    }
}

function ConvertTo-Phase00E3ILRelativeEvidencePath {
    param(
        [Parameter(Mandatory)][string]$Path,
        [Parameter(Mandatory)][string]$EvidenceRoot
    )

    $root = [IO.Path]::GetFullPath($EvidenceRoot).TrimEnd('\','/')
    $resolved = [IO.Path]::GetFullPath($Path)
    $prefix = $root + [IO.Path]::DirectorySeparatorChar
    if (-not $resolved.StartsWith($prefix, [StringComparison]::OrdinalIgnoreCase)) {
        throw "Raw artifact escapes evidence root: $resolved"
    }
    'docs/evidence/phase-00/' + `
        $resolved.Substring($prefix.Length).Replace('\','/')
}

function Get-Phase00E3ILArtifactReference {
    param(
        [Parameter(Mandatory)][string]$Path,
        [Parameter(Mandatory)][string]$EvidenceRoot
    )

    if (-not (Test-Path -LiteralPath $Path -PathType Leaf)) {
        throw "Expected raw artifact is missing: $Path"
    }
    [ordered]@{
        path = ConvertTo-Phase00E3ILRelativeEvidencePath $Path $EvidenceRoot
        sha256 = (Get-FileHash -Algorithm SHA256 -LiteralPath $Path).Hash
    }
}

function Get-Phase00E3ILSelectionFromInvocation {
    param(
        [Parameter(Mandatory)]$Invocation,
        [Parameter(Mandatory)][ValidateSet('A','B')][string]$Session
    )

    if (Test-Phase00HasProperty $Invocation 'SelectionEnvelope') {
        return Get-Phase00PropertyValue $Invocation 'SelectionEnvelope'
    }
    $transport = Test-Phase00E3ILSessionTransport -Session $Session `
        -ParentEvents @(Get-Phase00PropertyValue $Invocation 'ParentEvents') `
        -CanaryEvents (Get-Phase00PropertyValue $Invocation 'CanaryEvents') `
        -TimedOut ([bool](Get-Phase00PropertyValue $Invocation 'TimedOut'))
    Test-Phase00E3ILSelectionEnvelope -SessionTransport $transport `
        -Boundary (Get-Phase00PropertyValue $Invocation 'Boundary') `
        -LiveHomeMutationAttributable `
            ([bool](Get-Phase00PropertyValue $Invocation 'LiveHomeMutationAttributable')) `
        -CleanupError ([string](Get-Phase00PropertyValue $Invocation 'CleanupError'))
}

function Add-Phase00E3ILSelectionMetadata {
    param(
        [Parameter(Mandatory)]$Selection,
        [Parameter(Mandatory)][int]$Attempt,
        [Parameter(Mandatory)]$Runtime
    )

    foreach ($entry in @(
        @('Attempt',$Attempt),
        @('Selected',$true),
        @('RuntimeVersion',$Runtime.Version),
        @('RuntimeSha256',$Runtime.Sha256),
        @('SupportedHost',$script:Phase00E3LSupportedHost)
    )) {
        $Selection | Add-Member NoteProperty $entry[0] $entry[1] -Force
    }
    $Selection
}

function New-Phase00E3ILJointSessionRecord {
    param(
        [Parameter(Mandatory)]$Invocation,
        [Parameter(Mandatory)]$Selection,
        [Parameter(Mandatory)]$E3LOracle,
        [Parameter(Mandatory)][string]$EvidenceRoot
    )

    $canaries = @(Get-Phase00PropertyValue $Invocation 'CanaryArtifacts' | ForEach-Object {
        $reference = Get-Phase00E3ILArtifactReference `
            (Get-Phase00PropertyValue $_ 'Path') $EvidenceRoot
        [ordered]@{
            id = [string](Get-Phase00PropertyValue $_ 'Id')
            path = $reference.path
            sha256 = $reference.sha256
        }
    })
    $analysis = Get-Phase00PropertyValue $Invocation 'Analysis'
    $boundary = Get-Phase00PropertyValue $Invocation 'Boundary'
    $recoveredProviderRetry = @(
        Get-Phase00PropertyValue $Selection 'Reasons'
    ) -contains 'E3IL_NESTED_PROVIDER_RECOVERY'
    if (-not $recoveredProviderRetry -and
        (Test-Phase00HasProperty $Invocation 'ParentEvents')) {
        $parentEvents = @(Get-Phase00PropertyValue $Invocation 'ParentEvents')
        if (@(Get-Phase00ParentRecoveredProviderRetries `
            -Events $parentEvents).Count -gt 0) {
            $recoveredProviderRetry = $true
        }
    }
    if (-not $recoveredProviderRetry -and
        (Test-Phase00HasProperty $Invocation 'CanaryEvents')) {
        $canaryEvents = Get-Phase00PropertyValue $Invocation 'CanaryEvents'
        if ($canaryEvents -is [System.Collections.IDictionary]) {
            foreach ($canaryId in @($canaryEvents.Keys)) {
                if (@(Get-Phase00E3ILRecoveredProviderFailures `
                    -Events @($canaryEvents[$canaryId])).Count -gt 0) {
                    $recoveredProviderRetry = $true
                    break
                }
            }
        }
    }
    [ordered]@{
        invoked = $true
        run = Get-Phase00E3ILArtifactReference `
            (Get-Phase00PropertyValue $Invocation 'RunPath') $EvidenceRoot
        parent_stdout = Get-Phase00E3ILArtifactReference `
            (Get-Phase00PropertyValue $Invocation 'StdoutPath') $EvidenceRoot
        parent_stderr = Get-Phase00E3ILArtifactReference `
            (Get-Phase00PropertyValue $Invocation 'StderrPath') $EvidenceRoot
        canaries = $canaries
        transport_status = [string](Get-Phase00PropertyValue $Selection 'Status')
        transport_reasons = @(Get-Phase00PropertyValue $Selection 'Reasons')
        e3_i_status = [string](Get-Phase00PropertyValue $analysis 'Status')
        e3_l_status = [string](Get-Phase00PropertyValue $E3LOracle 'Status')
        provider_terminal = `
            (Get-Phase00PropertyValue $Selection 'Status') -eq 'BLOCKED_ENVIRONMENT'
        recovered_provider_retry = $recoveredProviderRetry
        boundary = [ordered]@{
            parent_content_unchanged = Get-Phase00PropertyValue $boundary 'ParentContentUnchanged'
            parent_head_unchanged = Get-Phase00PropertyValue $boundary 'ParentHeadUnchanged'
            parent_status_unchanged = Get-Phase00PropertyValue $boundary 'ParentStatusUnchanged'
            fixture_hashes_unchanged = Get-Phase00PropertyValue $boundary 'FixtureHashesUnchanged'
            live_home_unchanged = Get-Phase00PropertyValue $boundary 'LiveHomeUnchanged'
            cleanup_succeeded = Get-Phase00PropertyValue $boundary 'CleanupSucceeded'
        }
    }
}

function Invoke-Phase00E3ILJointAttempt {
    param(
        [Parameter(Mandatory)][ValidateRange(5,999)][int]$Attempt,
        [Parameter(Mandatory)][string]$Model,
        [Parameter(Mandatory)][string]$OmpExecutable,
        [Parameter(Mandatory)][scriptblock]$SessionInvoker,
        [string]$EvidenceRoot = (Join-Path $script:Phase00E3ILJointRoot `
            'docs\evidence\phase-00'),
        [string]$SourceIdentityPath = (Join-Path $script:Phase00E3ILJointRoot `
            'docs\evidence\phase-00\E3-L\source-identity.json')
    )

    $runtime = Get-Phase00E3ILPinnedRuntimeIdentity $OmpExecutable
    $expectedPaths = @(Get-Phase00E3ILJointExpectedPaths $EvidenceRoot $Attempt)
    $collisions = @($expectedPaths | Where-Object { Test-Path -LiteralPath $_ })
    if ($collisions.Count -ne 0) {
        throw 'Joint attempt evidence already exists; use a new explicit attempt number.'
    }
    if (-not (Test-Path -LiteralPath $SourceIdentityPath -PathType Leaf)) {
        throw 'E3-L source identity artifact is missing.'
    }
    $sourceIdentityHash = (Get-FileHash -Algorithm SHA256 `
        -LiteralPath $SourceIdentityPath).Hash

    $aInvocation = & $SessionInvoker -Session A -Attempt $Attempt -Model $Model `
        -OmpExecutable $OmpExecutable
    $aSelection = Get-Phase00E3ILSelectionFromInvocation $aInvocation A
    Add-Phase00E3ILSelectionMetadata $aSelection $Attempt $runtime | Out-Null
    $aOracle = Test-Phase00E3LSessionAOracle $aSelection
    $aRecord = New-Phase00E3ILJointSessionRecord $aInvocation $aSelection `
        $aOracle $EvidenceRoot

    $bInvoked = $false
    $bRecord = $null
    if ($aSelection.Status -eq 'ELIGIBLE') {
        $bInvocation = & $SessionInvoker -Session B -Attempt $Attempt -Model $Model `
            -OmpExecutable $OmpExecutable
        $bInvoked = $true
        $bSelection = Get-Phase00E3ILSelectionFromInvocation $bInvocation B
        Add-Phase00E3ILSelectionMetadata $bSelection $Attempt $runtime | Out-Null
        $bOracle = Test-Phase00E3LSessionBOracle $bSelection
        $bRecord = New-Phase00E3ILJointSessionRecord $bInvocation $bSelection `
            $bOracle $EvidenceRoot
    } else {
        $bRecord = [ordered]@{
            invoked = $false
            skip_reason = "A_$($aSelection.Status)"
        }
    }

    $jointPath = Join-Path (Join-Path $EvidenceRoot 'E3-L\raw') `
        ("joint-attempt-{0:D3}.json" -f $Attempt)
    [IO.Directory]::CreateDirectory((Split-Path -Parent $jointPath)) | Out-Null
    $record = [ordered]@{
        schema_version = 1
        experiment = 'E3-I+E3-L'
        attempt = $Attempt
        selected = $false
        model = $Model
        runtime = [ordered]@{
            version = $runtime.Version
            sha256 = $runtime.Sha256
            executable = '<PINNED_OMP_EXECUTABLE>'
        }
        source_identity = [ordered]@{
            path = 'docs/evidence/phase-00/E3-L/source-identity.json'
            sha256 = $sourceIdentityHash
        }
        sessions = [ordered]@{ a = $aRecord; b = $bRecord }
        automatic_retry = $false
        e3_i_conclusion_consumed = $false
        e3_l_conclusion_consumed = $false
    }
    [IO.File]::WriteAllText(
        $jointPath,
        ($record | ConvertTo-Json -Depth 18) + "`n",
        [Text.UTF8Encoding]::new($false)
    )
    [pscustomobject][ordered]@{
        Status = 'CAPTURED_UNSELECTED'
        Attempt = $Attempt
        SessionBInvoked = $bInvoked
        JointPath = $jointPath
        JointSha256 = (Get-FileHash -Algorithm SHA256 -LiteralPath $jointPath).Hash
        SessionA = $aInvocation
        SessionB = if ($bInvoked) { $bInvocation } else { $null }
    }
}

if ($MyInvocation.InvocationName -ne '.') {
    if ([string]::IsNullOrWhiteSpace($script:Phase00E3ILCliOmpExecutable)) {
        throw 'Direct joint execution requires -OmpExecutable.'
    }
    $realInvoker = {
        param($Session,$Attempt,$Model,$OmpExecutable)
        Invoke-Phase00E3IEvidenceSession -Session $Session -Attempt $Attempt `
            -Model $Model -OmpExecutable $OmpExecutable
    }
    Invoke-Phase00E3ILJointAttempt -Attempt $script:Phase00E3ILCliAttempt `
        -Model $script:Phase00E3ILCliModel `
        -OmpExecutable $script:Phase00E3ILCliOmpExecutable `
        -SessionInvoker $realInvoker
}
