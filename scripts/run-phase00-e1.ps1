#Requires -Version 5.1

[CmdletBinding()]
param(
    [Parameter(Mandatory)]
    [ValidateSet('AgentJtd','AgentJsonSchema','CallerOnly','CallerOverAgent','SessionOnly','ProviderStrictOffControl','ProviderStrictOn')]
    [string]$CaseId,
    [ValidateRange(1,999)][int]$Attempt = 1,
    [Parameter(Mandatory)][string]$OmpExecutable,
    [string]$Model = 'omniroute/codex/gpt-5.6-sol-high',
    [switch]$AllowOverwrite
)

Set-StrictMode -Version 2.0

. (Join-Path $PSScriptRoot 'lib\phase00-e1-evidence.ps1')

Invoke-Phase00E1EvidenceCase @PSBoundParameters
