#Requires -Version 7.4
[CmdletBinding()]
param([string]$NamePattern = '*')

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$repositoryRoot = (Resolve-Path (Join-Path $PSScriptRoot '..\..')).Path
$safeInitPath = Join-Path $repositoryRoot 'template\.omp\codegraph\safe-init.mjs'
$wrapperPath = Join-Path $repositoryRoot 'template\.omp\codegraph\codegraph-process.ps1'
$fakeCliPath = Join-Path $repositoryRoot 'scripts\tests\fixtures\topic05\fake-codegraph.mjs'
$provisionLibraryPath = Join-Path $repositoryRoot 'scripts\lib\topic05-codegraph.ps1'
$topic04FixtureHelperPath = Join-Path $repositoryRoot 'scripts\lib\topic04-test-fixtures.ps1'
$stateSourceRoot = Join-Path $repositoryRoot 'template\.omp\state'
$upstreamLockSource = Join-Path $repositoryRoot 'template\.omp\codegraph\upstream-lock.json'
$nodePath = (Get-Command node -ErrorAction Stop).Source
$tempBase = [IO.Path]::GetFullPath([IO.Path]::GetTempPath()).TrimEnd('\', '/')
$tempPrefix = 'omp-topic05-adapter-'
$script:TempRoots = [Collections.Generic.List[string]]::new()
$script:Passed = 0
$script:Failed = 0

. $topic04FixtureHelperPath
foreach ($moduleName in @(
    'AgentTasks.Common.ps1', 'AgentTasks.Store.ps1', 'AgentTasks.Git.ps1',
    'AgentTasks.Lifecycle.ps1', 'AgentTasks.Candidate.ps1', 'AgentTasks.Transfer.ps1'
)) {
    . (Join-Path $stateSourceRoot (Join-Path 'lib' $moduleName))
}

function Assert-Topic05Adapter {
    param([Parameter(Mandatory)][bool]$Condition, [Parameter(Mandatory)][string]$Message)
    if (-not $Condition) { throw $Message }
}

function Invoke-Topic05AdapterTest {
    param([Parameter(Mandatory)][string]$Name, [Parameter(Mandatory)][scriptblock]$Body)
    if ($Name -notlike $NamePattern) { return }
    try {
        & $Body
        $script:Passed++
        Write-Host "PASS $Name" -ForegroundColor Green
    } catch {
        $script:Failed++
        Write-Host "FAIL $Name :: $($_.Exception.Message)" -ForegroundColor Red
    }
}

function New-Topic05AdapterRoot {
    $path = Join-Path $tempBase ($tempPrefix + [guid]::NewGuid().ToString('N'))
    [void](New-Item -ItemType Directory -Path $path)
    [void]$script:TempRoots.Add([IO.Path]::GetFullPath($path))
    return $path
}

function Remove-Topic05AdapterRoots {
    foreach ($path in @($script:TempRoots)) {
        $resolved = [IO.Path]::GetFullPath($path).TrimEnd('\', '/')
        $parent = [IO.Path]::GetDirectoryName($resolved).TrimEnd('\', '/')
        $leaf = [IO.Path]::GetFileName($resolved)
        if ($parent -cne $tempBase -or -not $leaf.StartsWith($tempPrefix, [StringComparison]::Ordinal)) {
            throw "Refusing unsafe Topic 05 adapter cleanup target: $resolved"
        }
        if (Test-Path -LiteralPath $resolved) { Remove-Item -LiteralPath $resolved -Recurse -Force }
    }
}

function New-Topic05InitFixture {
    $root = New-Topic05AdapterRoot
    $bundle = Join-Path $root 'cache\v1.5.0\win32-x64'
    $library = Join-Path $bundle 'lib\dist\index.js'
    [void](New-Item -ItemType Directory -Path (Split-Path -Parent $library) -Force)
    Set-Content -LiteralPath (Join-Path $bundle 'lib\package.json') -Encoding UTF8 -Value @'
{"name":"codegraph-fixture","version":"1.5.0","type":"module"}
'@
    Set-Content -LiteralPath $library -Encoding UTF8 -Value @'
import fs from "node:fs";
import path from "node:path";

function log(root, event) {
  fs.appendFileSync(path.join(root, ".codegraph", "init.log"), `${event}\n`, "utf8");
}

class CodeGraphFixture {
  static async init(root, options) {
    fs.mkdirSync(path.join(root, ".codegraph"), { recursive: true });
    log(root, `init:${JSON.stringify(options)}`);
    return new CodeGraphFixture(root);
  }
  constructor(root) { this.root = root; }
  async indexAll() {
    log(this.root, "indexAll");
    if (process.env.OMP_TOPIC05_INIT_MODE === "throw") throw new Error("fixture_index_throw");
    if (process.env.OMP_TOPIC05_INIT_MODE === "failed") return { success: false };
    fs.writeFileSync(path.join(this.root, ".codegraph", "codegraph.db"), "fixture-index", "utf8");
    return {
      success: true,
      filesIndexed: 4,
      filesErrored: 1,
      nodesCreated: 12,
      edgesCreated: 11,
      durationMs: 7,
    };
  }
  destroy() { log(this.root, "destroy"); }
}

export const CodeGraph = CodeGraphFixture;
export default { CodeGraph };
'@

    $project = Join-Path $root 'project'
    [void](New-Item -ItemType Directory -Path (Join-Path $project 'src') -Force)
    Set-Content -LiteralPath (Join-Path $project 'src\app.js') -Value 'export const value = 1;' -NoNewline
    Set-Content -LiteralPath (Join-Path $project 'codegraph.json') -Value '{"sentinel":true}' -NoNewline
    & git -C $project init --quiet
    if ($LASTEXITCODE -ne 0) { throw 'fixture git init failed' }
    & git -C $project config user.email 'topic05@example.invalid'
    & git -C $project config user.name 'Topic 05 Fixture'
    & git -C $project add -- src/app.js codegraph.json
    & git -C $project commit --quiet -m baseline
    if ($LASTEXITCODE -ne 0) { throw 'fixture git commit failed' }
    return [pscustomobject]@{ Root = $root; Bundle = $bundle; Project = $project }
}

function Invoke-Topic05SafeInit {
    param([Parameter(Mandatory)][object]$Fixture, [string]$Mode)
    $beforeMode = $env:OMP_TOPIC05_INIT_MODE
    try {
        if ($Mode) { $env:OMP_TOPIC05_INIT_MODE = $Mode } else { Remove-Item Env:OMP_TOPIC05_INIT_MODE -ErrorAction SilentlyContinue }
        $output = @(& $nodePath $safeInitPath --bundle-root $Fixture.Bundle `
            --project-root $Fixture.Project 2>&1)
        return [pscustomobject]@{ ExitCode = $LASTEXITCODE; Text = ($output -join "`n") }
    } finally {
        if ($null -eq $beforeMode) { Remove-Item Env:OMP_TOPIC05_INIT_MODE -ErrorAction SilentlyContinue }
        else { $env:OMP_TOPIC05_INIT_MODE = $beforeMode }
    }
}

function Set-Topic05AdapterJson {
    param([Parameter(Mandatory)][string]$LiteralPath, [Parameter(Mandatory)][object]$Value)
    $parent = Split-Path -Parent $LiteralPath
    if (-not (Test-Path -LiteralPath $parent -PathType Container)) {
        [void](New-Item -ItemType Directory -Path $parent -Force)
    }
    [IO.File]::WriteAllText(
        $LiteralPath,
        (($Value | ConvertTo-Json -Depth 30) + "`n"),
        [Text.UTF8Encoding]::new($false)
    )
}

function Get-Topic05AdapterSha256 {
    param([Parameter(Mandatory)][string]$LiteralPath)
    return (Get-FileHash -LiteralPath $LiteralPath -Algorithm SHA256).Hash.ToLowerInvariant()
}

function ConvertTo-Topic05Base64Url {
    param([Parameter(Mandatory)][string]$Value)
    return [Convert]::ToBase64String([Text.UTF8Encoding]::new($false, $true).GetBytes($Value)).TrimEnd('=').Replace('+', '-').Replace('/', '_')
}

function New-Topic05RuntimeFixture {
    param([string]$Mode = 'healthy')

    . $provisionLibraryPath
    $root = New-Topic05AdapterRoot
    $project = Join-Path $root 'project'
    $targetOmp = Join-Path $project '.omp'
    $codegraphTarget = Join-Path $targetOmp 'codegraph'
    [void](New-Item -ItemType Directory -Path (Join-Path $project 'src') -Force)
    [void](New-Item -ItemType Directory -Path $codegraphTarget -Force)
    Set-Content -LiteralPath (Join-Path $project 'src\app.js') -Value 'export const value = 1;' -NoNewline
    Copy-Item -LiteralPath $stateSourceRoot -Destination $targetOmp -Recurse
    Copy-Item -LiteralPath $safeInitPath -Destination (Join-Path $codegraphTarget 'safe-init.mjs')
    Copy-Item -LiteralPath $wrapperPath -Destination (Join-Path $codegraphTarget 'codegraph-process.ps1')
    Copy-Item -LiteralPath $upstreamLockSource -Destination (Join-Path $codegraphTarget 'upstream-lock.json')

    $bundle = Join-Path $root 'cache\v1.5.0\win32-x64'
    [void](New-Item -ItemType Directory -Path (Join-Path $bundle 'bin') -Force)
    [void](New-Item -ItemType Directory -Path (Join-Path $bundle 'lib\dist\bin') -Force)
    Set-Content -LiteralPath (Join-Path $bundle 'bin\codegraph.cmd') -Value '@exit /b 1' -NoNewline
    try {
        [void](New-Item -ItemType HardLink -Path (Join-Path $bundle 'node.exe') -Target $nodePath)
    } catch {
        Copy-Item -LiteralPath $nodePath -Destination (Join-Path $bundle 'node.exe')
    }
    Set-Content -LiteralPath (Join-Path $bundle 'lib\package.json') -Encoding UTF8 -Value @'
{"name":"codegraph-fixture","version":"1.5.0","type":"module"}
'@
    Set-Content -LiteralPath (Join-Path $bundle 'lib\dist\index.js') -Encoding UTF8 -Value @'
import fs from "node:fs";
import path from "node:path";

class CodeGraphFixture {
  static async init(root, options) {
    if (options?.index !== false) throw new Error("unsafe_init_options");
    fs.mkdirSync(path.join(root, ".codegraph"), { recursive: true });
    return new CodeGraphFixture(root);
  }
  constructor(root) { this.root = root; }
  async indexAll() {
    fs.writeFileSync(path.join(this.root, ".codegraph", ".gitignore"), "*\n!.gitignore\n", "utf8");
    fs.writeFileSync(path.join(this.root, ".codegraph", "codegraph.db"), "fixture-index", "utf8");
    return { success: true, filesIndexed: 4, filesErrored: 1, nodesCreated: 12, edgesCreated: 11, durationMs: 7 };
  }
  destroy() {}
}


export const CodeGraph = CodeGraphFixture;
export default { CodeGraph };
'@
    Copy-Item -LiteralPath $fakeCliPath -Destination (Join-Path $bundle 'lib\dist\bin\codegraph.js')

    $requiredPaths = [ordered]@{
        launcher = 'bin/codegraph.cmd'
        node = 'node.exe'
        package = 'lib/package.json'
        library_entry = 'lib/dist/index.js'
        cli_entry = 'lib/dist/bin/codegraph.js'
    }
    $required = [ordered]@{}
    foreach ($entry in $requiredPaths.GetEnumerator()) {
        $full = Join-Path $bundle $entry.Value.Replace('/', [IO.Path]::DirectorySeparatorChar)
        $required[$entry.Key] = [ordered]@{ path = $entry.Value; sha256 = Get-Topic05AdapterSha256 $full }
    }
    $officialLock = Get-Content -Raw -LiteralPath $upstreamLockSource | ConvertFrom-Json
    $artifact = @($officialLock.artifacts | Where-Object platform -CEQ 'win32-x64')[0]
    $receiptPath = Join-Path $bundle 'receipt.json'
    $receipt = [ordered]@{
        schema_version = 1
        record_type = 'codegraph_bundle_receipt'
        upstream = 'colbymchenry/codegraph'
        version = '1.5.0'
        tag = 'v1.5.0'
        commit = 'ea72e1b190921232aa7bd02e96bef5bbe4fe0ab6'
        platform = 'win32-x64'
        bundle_root = [IO.Path]::GetFullPath($bundle)
        receipt_path = [IO.Path]::GetFullPath($receiptPath)
        artifact = [ordered]@{
            name = [string]$artifact.name
            size = [long]$artifact.size
            sha256 = [string]$artifact.sha256
        }
        required_files = $required
        bundle_tree_sha256 = Get-Topic05CodeGraphTreeHash -BundleRoot $bundle
        provisioned_at_utc = '2026-08-13T00:00:00.0000000Z'
    }
    Set-Topic05AdapterJson -LiteralPath $receiptPath -Value $receipt

    $stateManifestPath = Join-Path $targetOmp 'state\manifest.json'
    $lockTargetPath = Join-Path $codegraphTarget 'upstream-lock.json'
    $componentManifestPath = Join-Path $codegraphTarget 'component-manifest.json'
    $componentManifest = [ordered]@{
        schema_version = 1
        record_type = 'codegraph_component_manifest'
        component = 'codegraph'
        component_version = '1.0.0'
        minimum_pwsh_version = '7.4'
        requires = @([ordered]@{
            component = 'state'
            path = '.omp/state/manifest.json'
            schema_version = 1
            record_type = 'agent_tasks_component_manifest'
            sha256 = Get-Topic05AdapterSha256 $stateManifestPath
        })
        upstream_lock = [ordered]@{
            path = '.omp/codegraph/upstream-lock.json'
            sha256 = Get-Topic05AdapterSha256 $lockTargetPath
            version = '1.5.0'
            tag = 'v1.5.0'
            commit = 'ea72e1b190921232aa7bd02e96bef5bbe4fe0ab6'
        }
        files = @()
        generated_target_files = @('.omp/codegraph/runtime.json', '.omp/codegraph/install-record.json')
    }
    Set-Topic05AdapterJson -LiteralPath $componentManifestPath -Value $componentManifest

    $installedSafeInit = Join-Path $codegraphTarget 'safe-init.mjs'
    $installedWrapper = Join-Path $codegraphTarget 'codegraph-process.ps1'
    $runtimePath = Join-Path $codegraphTarget 'runtime.json'
    $runtime = [ordered]@{
        schema_version = 1
        record_type = 'codegraph_target_runtime'
        component = 'codegraph'
        component_version = '1.0.0'
        created_at_utc = '2026-08-13T00:00:00.0000000Z'
        target_omp = [IO.Path]::GetFullPath($targetOmp)
        component_manifest_sha256 = Get-Topic05AdapterSha256 $componentManifestPath
        upstream_lock_sha256 = Get-Topic05AdapterSha256 $lockTargetPath
        receipt_sha256 = Get-Topic05AdapterSha256 $receiptPath
        upstream = 'colbymchenry/codegraph'
        version = '1.5.0'
        tag = 'v1.5.0'
        commit = 'ea72e1b190921232aa7bd02e96bef5bbe4fe0ab6'
        platform = 'win32-x64'
        artifact_sha256 = [string]$artifact.sha256
        paths = [ordered]@{
            bundle_root = [IO.Path]::GetFullPath($bundle)
            receipt = [IO.Path]::GetFullPath($receiptPath)
            launcher = [IO.Path]::GetFullPath((Join-Path $bundle 'bin\codegraph.cmd'))
            node = [IO.Path]::GetFullPath((Join-Path $bundle 'node.exe'))
            library_entry = [IO.Path]::GetFullPath((Join-Path $bundle 'lib\dist\index.js'))
            cli_entry = [IO.Path]::GetFullPath((Join-Path $bundle 'lib\dist\bin\codegraph.js'))
            safe_init = [IO.Path]::GetFullPath($installedSafeInit)
            process_wrapper = [IO.Path]::GetFullPath($installedWrapper)
            pwsh = [IO.Path]::GetFullPath((Get-Command pwsh).Source)
        }
    }
    Set-Topic05AdapterJson -LiteralPath $runtimePath -Value $runtime

    & git -C $project init --quiet
    & git -C $project config user.email 'topic05@example.invalid'
    & git -C $project config user.name 'Topic 05 Fixture'
    & git -C $project config core.autocrlf false
    & git -C $project add -- .
    & git -C $project commit --quiet -m baseline
    if ($LASTEXITCODE -ne 0) { throw 'runtime fixture git commit failed' }

    $behaviorPath = Join-Path $root 'behavior.json'
    $logPath = Join-Path $root 'fake.log'
    Set-Topic05AdapterJson -LiteralPath $behaviorPath -Value ([ordered]@{
        mode = $Mode
        log_path = [IO.Path]::GetFullPath($logPath)
        graph_text = 'graph fixture result'
        mutate_path = [IO.Path]::GetFullPath((Join-Path $project 'src\app.js'))
        mutate_content = 'mutated by fake'
    })
    return [pscustomobject]@{
        Root = $root
        Project = $project
        TargetOmp = $targetOmp
        RuntimePath = $runtimePath
        WrapperPath = $installedWrapper
        BehaviorPath = $behaviorPath
        LogPath = $logPath
        Bundle = $bundle
    }
}

function Invoke-Topic05Wrapper {
    param(
        [Parameter(Mandatory)][object]$Fixture,
        [string]$Question = 'How does value flow?',
        [string]$QuestionBase64,
        [int]$MaxFiles = 6
    )
    if (-not $PSBoundParameters.ContainsKey('QuestionBase64')) {
        $QuestionBase64 = ConvertTo-Topic05Base64Url -Value $Question
    }
    $beforeFixture = $env:OMP_TOPIC05_CODEGRAPH_FIXTURE
    $beforeSecret = $env:CODEGRAPH_SHOULD_NOT_LEAK
    $beforeNodeOptions = $env:NODE_OPTIONS
    $beforeNodePath = $env:NODE_PATH
    try {
        $env:OMP_TOPIC05_CODEGRAPH_FIXTURE = $Fixture.BehaviorPath
        $env:CODEGRAPH_SHOULD_NOT_LEAK = 'secret-value'
        $env:NODE_OPTIONS = '--no-warnings'
        $env:NODE_PATH = 'secret-node-path'
        $start = [Diagnostics.ProcessStartInfo]::new()
        $start.FileName = (Get-Command pwsh).Source
        $start.UseShellExecute = $false
        $start.CreateNoWindow = $true
        $start.RedirectStandardInput = $true
        $start.RedirectStandardOutput = $true
        $start.RedirectStandardError = $true
        foreach ($argument in @(
            '-NoProfile', '-File', $Fixture.WrapperPath, '-Operation', 'retrieve',
            '-RuntimePath', $Fixture.RuntimePath, '-WorkingDirectory', $Fixture.Project,
            '-QuestionBase64', $QuestionBase64, '-MaxFiles', [string]$MaxFiles
        )) { [void]$start.ArgumentList.Add($argument) }
        $process = [Diagnostics.Process]::new()
        $process.StartInfo = $start
        try {
            [void]$process.Start()
            $process.StandardInput.Close()
            $stdoutTask = $process.StandardOutput.ReadToEndAsync()
            $stderrTask = $process.StandardError.ReadToEndAsync()
            $process.WaitForExit()
            $stdout = $stdoutTask.GetAwaiter().GetResult().Trim()
            $stderr = $stderrTask.GetAwaiter().GetResult().Trim()
            $exitCode = $process.ExitCode
        } finally { $process.Dispose() }
        return [pscustomobject]@{
            ExitCode = $exitCode
            Text = $stdout
            Diagnostic = $stderr
            Parsed = ($stdout | ConvertFrom-Json)
        }
    } finally {
        foreach ($entry in @(
            @('OMP_TOPIC05_CODEGRAPH_FIXTURE', $beforeFixture),
            @('CODEGRAPH_SHOULD_NOT_LEAK', $beforeSecret),
            @('NODE_OPTIONS', $beforeNodeOptions),
            @('NODE_PATH', $beforeNodePath)
        )) {
            if ($null -eq $entry[1]) { Remove-Item ("Env:" + $entry[0]) -ErrorAction SilentlyContinue }
            else { Set-Item ("Env:" + $entry[0]) -Value $entry[1] }
        }
    }
}

function Start-Topic05WrapperChild {
    param([Parameter(Mandatory)][object]$Fixture, [string]$Question = 'Concurrent retrieval')
    $start = [Diagnostics.ProcessStartInfo]::new()
    $start.FileName = (Get-Command pwsh).Source
    $start.UseShellExecute = $false
    $start.CreateNoWindow = $true
    $start.RedirectStandardInput = $true
    $start.RedirectStandardOutput = $true
    $start.RedirectStandardError = $true
    foreach ($argument in @(
        '-NoProfile', '-File', $Fixture.WrapperPath, '-Operation', 'retrieve',
        '-RuntimePath', $Fixture.RuntimePath, '-WorkingDirectory', $Fixture.Project,
        '-QuestionBase64', (ConvertTo-Topic05Base64Url $Question), '-MaxFiles', '6'
    )) { [void]$start.ArgumentList.Add($argument) }
    $start.Environment['OMP_TOPIC05_CODEGRAPH_FIXTURE'] = $Fixture.BehaviorPath
    $start.Environment['CODEGRAPH_SHOULD_NOT_LEAK'] = 'secret-value'
    $start.Environment['NODE_OPTIONS'] = '--no-warnings'
    $start.Environment['NODE_PATH'] = 'secret-node-path'
    $process = [Diagnostics.Process]::new()
    $process.StartInfo = $start
    [void]$process.Start()
    $process.StandardInput.Close()
    return [pscustomobject]@{
        Process = $process
        StdoutTask = $process.StandardOutput.ReadToEndAsync()
        StderrTask = $process.StandardError.ReadToEndAsync()
    }
}

function Complete-Topic05WrapperChild {
    param([Parameter(Mandatory)][object]$Child, [int]$TimeoutMs = 30000)
    try {
        if (-not $Child.Process.WaitForExit($TimeoutMs)) {
            try { $Child.Process.Kill($true) } catch { try { $Child.Process.Kill() } catch {} }
            throw 'concurrent wrapper child timed out'
        }
        $stdout = $Child.StdoutTask.GetAwaiter().GetResult().Trim()
        $stderr = $Child.StderrTask.GetAwaiter().GetResult().Trim()
        return [pscustomobject]@{
            ExitCode = $Child.Process.ExitCode
            Text = $stdout
            Diagnostic = $stderr
            Parsed = ($stdout | ConvertFrom-Json)
        }
    } finally { $Child.Process.Dispose() }
}

function Set-Topic05FakeBehavior {
    param(
        [Parameter(Mandatory)][object]$Fixture,
        [Parameter(Mandatory)][Collections.IDictionary]$Values
    )
    $document = [ordered]@{
        mode = 'healthy'
        log_path = [IO.Path]::GetFullPath($Fixture.LogPath)
        graph_text = 'graph fixture result'
        mutate_path = [IO.Path]::GetFullPath((Join-Path $Fixture.Project 'src\app.js'))
        mutate_content = 'mutated by fake'
    }
    foreach ($entry in $Values.GetEnumerator()) { $document[$entry.Key] = $entry.Value }
    Set-Topic05AdapterJson -LiteralPath $Fixture.BehaviorPath -Value $document
}

function Initialize-Topic05ExistingIndex {
    param([Parameter(Mandatory)][object]$Fixture)
    $index = Join-Path $Fixture.Project '.codegraph'
    [void](New-Item -ItemType Directory -Path $index -Force)
    Set-Content -LiteralPath (Join-Path $index '.gitignore') -Value "*`n!.gitignore`n" -NoNewline
    Set-Content -LiteralPath (Join-Path $index 'codegraph.db') -Value 'existing-index' -NoNewline
}

function Get-Topic05FixtureLockPath {
    param([Parameter(Mandatory)][object]$Fixture)
    $algorithm = [Security.Cryptography.SHA256]::Create()
    try {
        $root = [IO.Path]::GetFullPath($Fixture.Project).TrimEnd('\', '/')
        $bytes = [Text.UTF8Encoding]::new($false).GetBytes($root)
        $hash = ([BitConverter]::ToString($algorithm.ComputeHash($bytes))).Replace('-', '').ToLowerInvariant()
    } finally { $algorithm.Dispose() }
    $cacheRoot = Split-Path -Parent (Split-Path -Parent $Fixture.Bundle)
    return Join-Path (Join-Path $cacheRoot 'locks') ($hash + '.lock')
}

function New-Topic05StateTask {
    param(
        [Parameter(Mandatory)][object]$Fixture,
        [string[]]$OwnedIgnoredOutputs = @('.codegraph/.gitignore'),
        [ValidateSet('mutating', 'read_only')][string]$ExecutionMode = 'mutating'
    )
    $payload = [ordered]@{
        objective = 'Exercise Topic 05 read-only binding.'
        authority = @('user')
        acceptance_criteria = @([ordered]@{
            id = 'AC-001'; text = 'Retrieval remains bound to current source.'; mandatory = $true
        })
        obligations = @('verification')
        execution_mode = $ExecutionMode
        write_scope = @([ordered]@{ kind = 'subtree'; path = 'src' })
        owned_ignored_outputs = @($OwnedIgnoredOutputs)
        workflow_class = 'standard'
        locked_decisions = @()
    }
    $result = Invoke-Topic04CliObject `
        -CliPath (Join-Path $Fixture.TargetOmp 'state\agent-tasks.ps1') `
        -FixtureRoot $Fixture.Root -WorkingDirectory $Fixture.Project -Operation 'create-task' `
        -Request $payload -SessionRef 'codex:topic05-owner'
    if ($result.ExitCode -ne 0) {
        throw "Topic 05 state task creation failed: $($result.Stderr) $($result.Stdout)"
    }
    return [string]$result.Parsed.data.task_id
}

function Freeze-Topic05StateTask {
    param([Parameter(Mandatory)][object]$Fixture, [Parameter(Mandatory)][string]$TaskId)
    $context = Resolve-AgentTasksContext -WorkingDirectory $Fixture.Project
    $authority = Get-AgentTasksTaskAuthority -StateRoot $context.StateRoot -TaskId $TaskId
    $request = [ordered]@{
        task_id = $TaskId
        acceptance_inputs = @([ordered]@{ path = 'src/app.js'; role = 'source' })
        scope_dispositions = @()
        expected_revision = [long]$authority.Revision.revision
        expected_revision_sha256 = [string]$authority.RevisionSha256
        expected_lease_generation = [long]$authority.Revision.lease_generation
    }
    $result = Invoke-Topic04CliObject `
        -CliPath (Join-Path $Fixture.TargetOmp 'state\agent-tasks.ps1') `
        -FixtureRoot $Fixture.Root -WorkingDirectory $Fixture.Project -Operation 'freeze' `
        -Request $request -SessionRef 'codex:topic05-owner'
    if ($result.ExitCode -ne 0) {
        throw "Topic 05 candidate freeze failed: $($result.Stderr) $($result.Stdout)"
    }
    return [string]$result.Parsed.data.candidate_id
}

function New-Topic05LinkedRuntimeFixture {
    param([Parameter(Mandatory)][object]$Fixture)
    $linked = Join-Path $Fixture.Root 'linked-worktree'
    $branch = 'topic05-linked-' + [guid]::NewGuid().ToString('N')
    & git -C $Fixture.Project worktree add --quiet -b $branch $linked
    if ($LASTEXITCODE -ne 0) { throw 'Topic 05 linked-worktree creation failed' }
    $targetOmp = Join-Path $linked '.omp'
    Copy-Item -Path (Join-Path $Fixture.TargetOmp 'state\*') `
        -Destination (Join-Path $targetOmp 'state') -Recurse -Force
    foreach ($name in @(
        'component-manifest.json', 'upstream-lock.json', 'safe-init.mjs', 'codegraph-process.ps1'
    )) {
        Copy-Item -LiteralPath (Join-Path $Fixture.TargetOmp (Join-Path 'codegraph' $name)) `
            -Destination (Join-Path $targetOmp (Join-Path 'codegraph' $name)) -Force
    }
    $runtimePath = Join-Path $targetOmp 'codegraph\runtime.json'
    $runtime = Get-Content -Raw -LiteralPath $runtimePath | ConvertFrom-Json
    $runtime.target_omp = [IO.Path]::GetFullPath($targetOmp)
    $runtime.paths.safe_init = [IO.Path]::GetFullPath((Join-Path $targetOmp 'codegraph\safe-init.mjs'))
    $runtime.paths.process_wrapper = [IO.Path]::GetFullPath((Join-Path $targetOmp 'codegraph\codegraph-process.ps1'))
    Set-Topic05AdapterJson -LiteralPath $runtimePath -Value $runtime
    return [pscustomobject]@{
        Root = $Fixture.Root
        Project = $linked
        TargetOmp = $targetOmp
        RuntimePath = $runtimePath
        WrapperPath = [string]$runtime.paths.process_wrapper
        BehaviorPath = $Fixture.BehaviorPath
        LogPath = $Fixture.LogPath
        Bundle = $Fixture.Bundle
    }
}

try {
    Invoke-Topic05AdapterTest 'adapter files and stateful fake exist' {
        Assert-Topic05Adapter (Test-Path -LiteralPath $fakeCliPath -PathType Leaf) `
            'stateful fake CodeGraph executable is missing'
        Assert-Topic05Adapter (Test-Path -LiteralPath $safeInitPath -PathType Leaf) `
            'safe-init.mjs is missing'
        Assert-Topic05Adapter (Test-Path -LiteralPath $wrapperPath -PathType Leaf) `
            'codegraph-process.ps1 is missing'
    }

    if (Test-Path -LiteralPath $safeInitPath -PathType Leaf) {
        Invoke-Topic05AdapterTest 'safe init imports the selected bundle and calls init index destroy in order' {
            $fixture = New-Topic05InitFixture
            $result = Invoke-Topic05SafeInit -Fixture $fixture
            Assert-Topic05Adapter ($result.ExitCode -eq 0) "safe init failed: $($result.Text)"
            $parsed = $result.Text | ConvertFrom-Json
            Assert-Topic05Adapter ($parsed.schema_version -eq 1 -and $parsed.ok -eq $true) `
                'safe init result boundary is invalid'
            Assert-Topic05Adapter (
                (Get-Content -LiteralPath (Join-Path $fixture.Project '.codegraph\init.log') -Raw).Trim() -ceq
                "init:{`"index`":false}`nindexAll`ndestroy"
            ) 'safe init call order or index:false contract changed'
            Assert-Topic05Adapter ($parsed.files_indexed -eq 4 -and $parsed.files_errored -eq 1) `
                'safe init did not project exact indexing counts'
        }

        Invoke-Topic05AdapterTest 'safe init writes only the project cache and preserves source hooks and config' {
            $fixture = New-Topic05InitFixture
            $sourceBefore = (Get-FileHash -LiteralPath (Join-Path $fixture.Project 'src\app.js')).Hash
            $configBefore = (Get-FileHash -LiteralPath (Join-Path $fixture.Project 'codegraph.json')).Hash
            $hooksBefore = @(
                Get-ChildItem -LiteralPath (Join-Path $fixture.Project '.git\hooks') -File |
                    Sort-Object Name | ForEach-Object { "$($_.Name):$((Get-FileHash -LiteralPath $_.FullName).Hash)" }
            ) -join '|'
            $result = Invoke-Topic05SafeInit -Fixture $fixture
            Assert-Topic05Adapter ($result.ExitCode -eq 0) "safe init failed: $($result.Text)"
            Assert-Topic05Adapter ((Get-FileHash -LiteralPath (Join-Path $fixture.Project 'src\app.js')).Hash -ceq $sourceBefore) `
                'safe init changed project source'
            Assert-Topic05Adapter ((Get-FileHash -LiteralPath (Join-Path $fixture.Project 'codegraph.json')).Hash -ceq $configBefore) `
                'safe init changed codegraph.json'
            $hooksAfter = @(
                Get-ChildItem -LiteralPath (Join-Path $fixture.Project '.git\hooks') -File |
                    Sort-Object Name | ForEach-Object { "$($_.Name):$((Get-FileHash -LiteralPath $_.FullName).Hash)" }
            ) -join '|'
            Assert-Topic05Adapter ($hooksAfter -ceq $hooksBefore) 'safe init changed Git hooks'
            Assert-Topic05Adapter (-not (Test-Path -LiteralPath (Join-Path $fixture.Project '.omp'))) `
                'safe init created project .omp bytes'
        }

        Invoke-Topic05AdapterTest 'safe init failure is nonzero and still destroys the graph' {
            foreach ($mode in @('failed', 'throw')) {
                $fixture = New-Topic05InitFixture
                $result = Invoke-Topic05SafeInit -Fixture $fixture -Mode $mode
                Assert-Topic05Adapter ($result.ExitCode -ne 0) "$mode indexAll unexpectedly succeeded"
                $events = (Get-Content -LiteralPath (Join-Path $fixture.Project '.codegraph\init.log') -Raw).Trim()
                Assert-Topic05Adapter ($events.EndsWith("indexAll`ndestroy", [StringComparison]::Ordinal)) `
                    "$mode failure did not destroy the graph"
                Assert-Topic05Adapter ($result.Text -notmatch 'fixture_index_throw') `
                    "$mode failure leaked raw exception text"
            }
        }
    }

    if (Test-Path -LiteralPath $wrapperPath -PathType Leaf) {
        Invoke-Topic05AdapterTest 'healthy observation lazily initializes and returns the closed envelope' {
            $fixture = New-Topic05RuntimeFixture
            $question = "-trace 'value'`nwithout shell interpretation"
            $result = Invoke-Topic05Wrapper -Fixture $fixture -Question $question -MaxFiles 7
            Assert-Topic05Adapter ($result.ExitCode -eq 0) `
                "wrapper failed (exit=$($result.ExitCode)): $($result.Text) [$($result.Diagnostic)]"
            $envelope = $result.Parsed
            Assert-Topic05Adapter (
                $envelope.schema_version -eq 1 -and $envelope.ok -eq $true -and
                $envelope.status -ceq 'completed' -and $envelope.reason_code -ceq 'ok' -and
                $null -eq $envelope.fallback
            ) "wrapper success envelope is not closed: $($result.Text) [$($result.Diagnostic)]"
            Assert-Topic05Adapter ($envelope.data.text -ceq 'graph fixture result') `
                'wrapper did not return the bounded graph result'
            Assert-Topic05Adapter (
                $envelope.data.binding.mode -ceq 'observation' -and
                $envelope.data.binding.worktree_root -ceq [IO.Path]::GetFullPath($fixture.Project)
            ) 'wrapper did not use canonical observation binding'
            Assert-Topic05Adapter (
                $envelope.data.codegraph.lazy_initialized -eq $true -and
                $envelope.data.codegraph.initial_files_errored -eq 1 -and
                @($envelope.data.codegraph.gap_signals) -contains 'initial_files_errored'
            ) 'wrapper did not report lazy-init parse gaps'
            Assert-Topic05Adapter (Test-Path -LiteralPath (Join-Path $fixture.Project '.codegraph\codegraph.db')) `
                'lazy initialization did not create the worktree-local index'

            $records = @(Get-Content -LiteralPath $fixture.LogPath | ForEach-Object { $_ | ConvertFrom-Json })
            $explore = @($records | Where-Object { $_.argv[0] -ceq 'explore' })
            Assert-Topic05Adapter ($explore.Count -eq 1 -and $explore[0].question -ceq $question) `
                'question did not arrive after -- as one literal argument'
            Assert-Topic05Adapter ($explore[0].max_files -eq 7) 'max_files did not reach the fixed CLI operation'
            Assert-Topic05Adapter (
                $explore[0].environment.NODE_OPTIONS -eq $null -and
                $explore[0].environment.NODE_PATH -eq $null -and
                $explore[0].environment.leaked_codegraph_key -eq $null
            ) 'inherited process-control environment reached CodeGraph'
        }

        Invoke-Topic05AdapterTest 'malformed question is rejected before CodeGraph starts' {
            $fixture = New-Topic05RuntimeFixture
            $result = Invoke-Topic05Wrapper -Fixture $fixture -QuestionBase64 '***'
            Assert-Topic05Adapter ($result.Parsed.ok -eq $false -and $result.Parsed.reason_code -ceq 'query_failed') `
                'malformed question did not fail closed'
            Assert-Topic05Adapter (-not (Test-Path -LiteralPath $fixture.LogPath)) `
                'malformed question started CodeGraph'
        }

        Invoke-Topic05AdapterTest 'runtime and receipt tampering refuses before CodeGraph starts' {
            $cases = [ordered]@{
                runtime = 'artifact_identity_mismatch'
                runtime_shape = 'runtime_manifest_invalid'
                receipt = 'runtime_manifest_invalid'
                package = 'artifact_identity_mismatch'
                tree = 'artifact_identity_mismatch'
                component_missing = 'component_uninstalled'
                node_missing = 'executable_missing'
            }
            foreach ($kind in $cases.Keys) {
                $fixture = New-Topic05RuntimeFixture
                if ($kind -ceq 'runtime') {
                    $runtime = Get-Content -Raw -LiteralPath $fixture.RuntimePath | ConvertFrom-Json
                    $runtime.artifact_sha256 = '0' * 64
                    Set-Topic05AdapterJson -LiteralPath $fixture.RuntimePath -Value $runtime
                } elseif ($kind -ceq 'runtime_shape') {
                    $runtime = Get-Content -Raw -LiteralPath $fixture.RuntimePath | ConvertFrom-Json
                    $runtime | Add-Member -NotePropertyName unexpected -NotePropertyValue $true
                    Set-Topic05AdapterJson -LiteralPath $fixture.RuntimePath -Value $runtime
                } elseif ($kind -ceq 'receipt') {
                    Add-Content -LiteralPath (Join-Path $fixture.Bundle 'receipt.json') -Value ' '
                } elseif ($kind -ceq 'package') {
                    Set-Content -LiteralPath (Join-Path $fixture.Bundle 'lib\package.json') `
                        -Value '{"name":"codegraph-fixture","version":"1.5.0","type":"module","tampered":true}' `
                        -NoNewline
                } elseif ($kind -ceq 'tree') {
                    Set-Content -LiteralPath (Join-Path $fixture.Bundle 'lib\extra.js') `
                        -Value 'unexpected bundle byte' -NoNewline
                } elseif ($kind -ceq 'component_missing') {
                    Remove-Item -LiteralPath (Join-Path $fixture.TargetOmp 'codegraph\component-manifest.json')
                } else {
                    Remove-Item -LiteralPath (Join-Path $fixture.Bundle 'node.exe')
                }
                $result = Invoke-Topic05Wrapper -Fixture $fixture
                Assert-Topic05Adapter (
                    $result.Parsed.ok -eq $false -and
                    $result.Parsed.reason_code -ceq $cases[$kind]
                ) "$kind tamper mapped to $($result.Parsed.reason_code), expected $($cases[$kind])"
                Assert-Topic05Adapter (-not (Test-Path -LiteralPath $fixture.LogPath)) `
                    "$kind tamper started CodeGraph"
            }
        }

        Invoke-Topic05AdapterTest 'source mutation discards graph payload' {
            $fixture = New-Topic05RuntimeFixture -Mode source_mutation
            $result = Invoke-Topic05Wrapper -Fixture $fixture
            Assert-Topic05Adapter (
                $result.Parsed.ok -eq $false -and $result.Parsed.reason_code -ceq 'source_changed' -and
                $null -eq $result.Parsed.data -and $result.Parsed.fallback -ceq 'native'
            ) "source mutation was accepted as graph evidence: $($result.Text) [$($result.Diagnostic)]"
            Assert-Topic05Adapter ($result.Text -notmatch 'graph fixture result') `
                'discarded graph text survived in the failure envelope'
        }

        Invoke-Topic05AdapterTest 'status and process failures map to the closed fallback reasons' {
            $fixture = New-Topic05RuntimeFixture
            Initialize-Topic05ExistingIndex -Fixture $fixture
            $cases = @(
                [ordered]@{ mode = 'partial'; reason = 'index_partial' },
                [ordered]@{ mode = 'pending_refs'; reason = 'index_pending_refs' },
                [ordered]@{ mode = 'worktree_mismatch'; reason = 'worktree_mismatch' },
                [ordered]@{ mode = 'project_mismatch'; reason = 'worktree_mismatch' },
                [ordered]@{ mode = 'index_path_mismatch'; reason = 'worktree_mismatch' },
                [ordered]@{ mode = 'indexing'; reason = 'index_unhealthy' },
                [ordered]@{ mode = 'failed'; reason = 'index_unhealthy' },
                [ordered]@{ mode = 'null_state'; reason = 'index_unhealthy' },
                [ordered]@{ mode = 'reindex_recommended'; reason = 'index_unhealthy' },
                [ordered]@{ mode = 'pending_changes'; reason = 'index_unhealthy' },
                [ordered]@{ mode = 'empty_graph'; reason = 'graph_gap' },
                [ordered]@{ mode = 'version_mismatch'; reason = 'version_mismatch' },
                [ordered]@{ mode = 'uninitialized'; reason = 'index_sync_failed' },
                [ordered]@{ mode = 'nonzero'; target_command = 'explore'; reason = 'query_failed' },
                [ordered]@{ mode = 'stdout_overflow'; target_command = 'explore'; reason = 'output_truncated' },
                [ordered]@{ mode = 'stderr_overflow'; target_command = 'explore'; reason = 'output_truncated' }
            )
            foreach ($case in $cases) {
                Set-Topic05FakeBehavior -Fixture $fixture -Values $case
                $result = Invoke-Topic05Wrapper -Fixture $fixture
                Assert-Topic05Adapter (
                    $result.Parsed.ok -eq $false -and
                    $result.Parsed.reason_code -ceq $case.reason -and
                    $result.Parsed.fallback -ceq 'native' -and $null -eq $result.Parsed.data
                ) "$($case.mode) mapped to $($result.Parsed.reason_code), expected $($case.reason)"
                Assert-Topic05Adapter ($result.Text -notmatch 'secret details|secret-value|secret-node-path') `
                    "$($case.mode) leaked a child diagnostic or environment value"
            }

            Set-Topic05FakeBehavior -Fixture $fixture -Values ([ordered]@{
                mode = 'healthy'; graph_text = ('g' * 40000)
            })
            $oversized = Invoke-Topic05Wrapper -Fixture $fixture
            Assert-Topic05Adapter ($oversized.Parsed.reason_code -ceq 'output_truncated') `
                'post-parse 32 KiB graph boundary did not fail closed'

            Set-Topic05FakeBehavior -Fixture $fixture -Values ([ordered]@{
                mode = 'timeout'; target_command = '--version'; delay_ms = 11000
            })
            $timed = Invoke-Topic05Wrapper -Fixture $fixture
            Assert-Topic05Adapter ($timed.Parsed.reason_code -ceq 'timeout' -and $timed.Parsed.data -eq $null) `
                'bounded child timeout did not discard the result'
        }

        Invoke-Topic05AdapterTest 'question validation rejects noncanonical UTF-8 NUL and oversized input before launch' {
            $fixture = New-Topic05RuntimeFixture
            $invalidUtf8 = [Convert]::ToBase64String([byte[]](0xC3, 0x28)).TrimEnd('=').Replace('+', '-').Replace('/', '_')
            $cases = @(
                'YR',
                $invalidUtf8,
                (ConvertTo-Topic05Base64Url -Value ([string][char]0)),
                (ConvertTo-Topic05Base64Url -Value ('a' * 1025)),
                (ConvertTo-Topic05Base64Url -Value ' leading-space')
            )
            foreach ($encoded in $cases) {
                $result = Invoke-Topic05Wrapper -Fixture $fixture -QuestionBase64 $encoded
                Assert-Topic05Adapter ($result.Parsed.reason_code -ceq 'query_failed') `
                    'invalid question crossed the wrapper boundary'
            }
            Assert-Topic05Adapter (-not (Test-Path -LiteralPath $fixture.LogPath)) `
                'invalid question launched CodeGraph'
        }

        Invoke-Topic05AdapterTest 'stream overflow kills the child before its operation timeout' {
            $fixture = New-Topic05RuntimeFixture
            Initialize-Topic05ExistingIndex -Fixture $fixture
            Set-Topic05FakeBehavior -Fixture $fixture -Values ([ordered]@{
                mode = 'infinite_stdout'; target_command = '--version'
            })
            $watch = [Diagnostics.Stopwatch]::StartNew()
            $result = Invoke-Topic05Wrapper -Fixture $fixture
            $watch.Stop()
            Assert-Topic05Adapter (
                $result.Parsed.reason_code -ceq 'output_truncated' -and
                $watch.Elapsed.TotalSeconds -lt 5
            ) "runaway stdout was not killed at the byte boundary: reason=$($result.Parsed.reason_code), seconds=$($watch.Elapsed.TotalSeconds)"
        }

        Invoke-Topic05AdapterTest 'lock recovery is exact and malformed ownership refuses immediately' {
            $fixture = New-Topic05RuntimeFixture
            Initialize-Topic05ExistingIndex -Fixture $fixture
            $lockPath = Get-Topic05FixtureLockPath -Fixture $fixture
            [void](New-Item -ItemType Directory -Path (Split-Path -Parent $lockPath) -Force)
            Set-Content -LiteralPath $lockPath -Value '{malformed' -NoNewline
            $watch = [Diagnostics.Stopwatch]::StartNew()
            $malformed = Invoke-Topic05Wrapper -Fixture $fixture
            $watch.Stop()
            Assert-Topic05Adapter (
                $malformed.Parsed.reason_code -ceq 'index_busy' -and $watch.Elapsed.TotalSeconds -lt 5
            ) 'malformed lock was reclaimed or waited through the full contention window'
            Assert-Topic05Adapter (Test-Path -LiteralPath $lockPath -PathType Leaf) `
                'malformed lock metadata was deleted'

            Remove-Item -LiteralPath $lockPath -Force
            Set-Topic05AdapterJson -LiteralPath $lockPath -Value ([ordered]@{
                schema_version = 1
                worktree_sha256 = [IO.Path]::GetFileNameWithoutExtension($lockPath)
                pid = 2147483000
                process_start_utc = '2000-01-01T00:00:00.0000000Z'
                created_at_utc = '2000-01-01T00:00:00.0000000Z'
            })
            $stale = Invoke-Topic05Wrapper -Fixture $fixture
            Assert-Topic05Adapter ($stale.Parsed.reason_code -ceq 'ok') `
                'dead exact process identity was not reclaimed'
            Assert-Topic05Adapter (-not (Test-Path -LiteralPath $lockPath)) `
                'owned replacement lock was not released after stale recovery'

            $current = [Diagnostics.Process]::GetCurrentProcess()
            Set-Topic05AdapterJson -LiteralPath $lockPath -Value ([ordered]@{
                schema_version = 1
                worktree_sha256 = [IO.Path]::GetFileNameWithoutExtension($lockPath)
                pid = $PID
                process_start_utc = $current.StartTime.ToUniversalTime().AddSeconds(-1).ToString('o')
                created_at_utc = [DateTime]::UtcNow.ToString('o')
            })
            $pidReuse = Invoke-Topic05Wrapper -Fixture $fixture
            Assert-Topic05Adapter ($pidReuse.Parsed.reason_code -ceq 'ok') `
                'PID reuse with a different process start time was treated as live ownership'

            Set-Topic05FakeBehavior -Fixture $fixture -Values ([ordered]@{
                mode = 'healthy'; replace_lock_path = [IO.Path]::GetFullPath($lockPath)
            })
            $replaced = Invoke-Topic05Wrapper -Fixture $fixture
            Assert-Topic05Adapter ($replaced.Parsed.reason_code -ceq 'ok') `
                'lock replacement fixture did not complete retrieval'
            Assert-Topic05Adapter (
                (Test-Path -LiteralPath $lockPath -PathType Leaf) -and
                (Get-Content -Raw -LiteralPath $lockPath) -ceq '{"replacement":true}'
            ) 'wrapper deleted lock metadata that no longer belonged to it'

            Remove-Item -LiteralPath $lockPath -Force
            Set-Topic05FakeBehavior -Fixture $fixture -Values ([ordered]@{
                mode = 'timeout'; target_command = 'explore'; delay_ms = 1200
            })
            $firstChild = Start-Topic05WrapperChild -Fixture $fixture -Question 'first concurrent query'
            Start-Sleep -Milliseconds 100
            $secondChild = Start-Topic05WrapperChild -Fixture $fixture -Question 'second concurrent query'
            $firstResult = Complete-Topic05WrapperChild -Child $firstChild
            $secondResult = Complete-Topic05WrapperChild -Child $secondChild
            Assert-Topic05Adapter (
                $firstResult.Parsed.reason_code -ceq 'ok' -and
                $secondResult.Parsed.reason_code -ceq 'ok'
            ) 'concurrent retrieval did not wait and serialize successfully'
            Assert-Topic05Adapter (-not (Test-Path -LiteralPath $lockPath)) `
                'serialized retrieval left its owned lock'

            $current = [Diagnostics.Process]::GetCurrentProcess()
            Set-Topic05AdapterJson -LiteralPath $lockPath -Value ([ordered]@{
                schema_version = 1
                worktree_sha256 = [IO.Path]::GetFileNameWithoutExtension($lockPath)
                pid = $PID
                process_start_utc = $current.StartTime.ToUniversalTime().ToString('o')
                created_at_utc = [DateTime]::UtcNow.ToString('o')
            })
            Set-Topic05FakeBehavior -Fixture $fixture -Values ([ordered]@{ mode = 'healthy' })
            $busyWatch = [Diagnostics.Stopwatch]::StartNew()
            $busy = Invoke-Topic05Wrapper -Fixture $fixture
            $busyWatch.Stop()
            Assert-Topic05Adapter (
                $busy.Parsed.reason_code -ceq 'index_busy' -and
                $busyWatch.Elapsed.TotalSeconds -ge 14 -and $busyWatch.Elapsed.TotalSeconds -lt 20
            ) "live exact owner did not produce bounded index_busy: reason=$($busy.Parsed.reason_code), seconds=$($busyWatch.Elapsed.TotalSeconds)"
            Assert-Topic05Adapter (Test-Path -LiteralPath $lockPath -PathType Leaf) `
                'busy retrieval deleted the live owner lock'
        }

        Invoke-Topic05AdapterTest 'Topic 04 binding is read-only exact and requires cache ownership' {
            $owned = New-Topic05RuntimeFixture
            $ownedTask = New-Topic05StateTask -Fixture $owned
            $ownedResult = Invoke-Topic05Wrapper -Fixture $owned
            Assert-Topic05Adapter (
                $ownedResult.Parsed.reason_code -ceq 'ok' -and
                $ownedResult.Parsed.data.binding.mode -ceq 'task' -and
                $ownedResult.Parsed.data.binding.task_id -ceq $ownedTask
            ) 'one matching owned task did not bind exactly'

            $unowned = New-Topic05RuntimeFixture
            [void](New-Topic05StateTask -Fixture $unowned -OwnedIgnoredOutputs @())
            $unownedResult = Invoke-Topic05Wrapper -Fixture $unowned
            Assert-Topic05Adapter ($unownedResult.Parsed.reason_code -ceq 'state_cache_not_owned') `
                'task without .codegraph/.gitignore ownership was allowed to index'
            Assert-Topic05Adapter (-not (Test-Path -LiteralPath $unowned.LogPath)) `
                'unowned task started CodeGraph'

            $ambiguous = New-Topic05RuntimeFixture
            [void](New-Topic05StateTask -Fixture $ambiguous -ExecutionMode read_only)
            [void](New-Topic05StateTask -Fixture $ambiguous -ExecutionMode read_only)
            $ambiguousResult = Invoke-Topic05Wrapper -Fixture $ambiguous
            Assert-Topic05Adapter ($ambiguousResult.Parsed.reason_code -ceq 'state_binding_ambiguous') `
                'two matching active observations were silently selected'
        }

        Invoke-Topic05AdapterTest 'frozen candidate cannot acquire a late index and valid preexisting index stays queryable' {
            $missing = New-Topic05RuntimeFixture
            $missingTask = New-Topic05StateTask -Fixture $missing
            [void](Freeze-Topic05StateTask -Fixture $missing -TaskId $missingTask)
            $missingResult = Invoke-Topic05Wrapper -Fixture $missing
            Assert-Topic05Adapter ($missingResult.Parsed.reason_code -ceq 'candidate_index_missing') `
                'frozen candidate lazily created an index'
            Assert-Topic05Adapter (-not (Test-Path -LiteralPath $missing.LogPath)) `
                'frozen candidate without index started CodeGraph'

            $valid = New-Topic05RuntimeFixture
            Initialize-Topic05ExistingIndex -Fixture $valid
            $validTask = New-Topic05StateTask -Fixture $valid
            $candidateId = Freeze-Topic05StateTask -Fixture $valid -TaskId $validTask
            $validResult = Invoke-Topic05Wrapper -Fixture $valid
            Assert-Topic05Adapter (
                $validResult.Parsed.reason_code -ceq 'ok' -and
                $validResult.Parsed.data.binding.candidate_id -ceq $candidateId -and
                $validResult.Parsed.data.codegraph.lazy_initialized -eq $false
            ) 'healthy index frozen into candidate identity was not queryable'

            Set-Topic05FakeBehavior -Fixture $valid -Values ([ordered]@{ mode = 'source_mutation' })
            $drift = Invoke-Topic05Wrapper -Fixture $valid
            Assert-Topic05Adapter (
                $drift.Parsed.reason_code -ceq 'candidate_drift' -and $null -eq $drift.Parsed.data
            ) 'candidate drift during retrieval retained graph evidence'
        }

        Invoke-Topic05AdapterTest 'main and linked worktrees receive separate indexes and lock identities' {
            $main = New-Topic05RuntimeFixture
            $linked = New-Topic05LinkedRuntimeFixture -Fixture $main
            $mainResult = Invoke-Topic05Wrapper -Fixture $main
            $linkedResult = Invoke-Topic05Wrapper -Fixture $linked
            Assert-Topic05Adapter (
                $mainResult.Parsed.reason_code -ceq 'ok' -and $linkedResult.Parsed.reason_code -ceq 'ok'
            ) "main or linked worktree retrieval failed: main=$($mainResult.Text), linked=$($linkedResult.Text)"
            $mainIndex = [IO.Path]::GetFullPath((Join-Path $main.Project '.codegraph'))
            $linkedIndex = [IO.Path]::GetFullPath((Join-Path $linked.Project '.codegraph'))
            Assert-Topic05Adapter (
                $mainResult.Parsed.data.codegraph.index_path -ceq $mainIndex -and
                $linkedResult.Parsed.data.codegraph.index_path -ceq $linkedIndex -and
                $mainIndex -cne $linkedIndex
            ) 'linked worktree borrowed the main-worktree index'
            Assert-Topic05Adapter (
                (Test-Path -LiteralPath (Join-Path $mainIndex 'codegraph.db')) -and
                (Test-Path -LiteralPath (Join-Path $linkedIndex 'codegraph.db'))
            ) 'one worktree-local index was not created'
            $mainLock = Get-Topic05FixtureLockPath -Fixture $main
            $linkedLock = Get-Topic05FixtureLockPath -Fixture $linked
            Assert-Topic05Adapter ($mainLock -cne $linkedLock) 'worktree lock hash was reused'
            Assert-Topic05Adapter (
                -not (Test-Path -LiteralPath $mainLock) -and -not (Test-Path -LiteralPath $linkedLock)
            ) 'owned per-worktree lock was not released'
            $exploreRoots = @(
                Get-Content -LiteralPath $main.LogPath | ForEach-Object { $_ | ConvertFrom-Json } |
                    Where-Object { $_.argv[0] -ceq 'explore' } | ForEach-Object root | Sort-Object -Unique
            )
            Assert-Topic05Adapter ($exploreRoots.Count -eq 2) `
                'fake CLI did not observe two distinct canonical worktree roots'
        }
    }

    if ($script:Failed -gt 0) {
        Write-Host "FAIL Topic 05 adapter ($($script:Passed) passed, $($script:Failed) failed)" -ForegroundColor Red
        exit 1
    }
    Write-Host "PASS Topic 05 adapter ($($script:Passed) cases)" -ForegroundColor Green
    exit 0
} finally {
    Remove-Topic05AdapterRoots
}
