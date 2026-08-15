# Progressive Retrieval and Optional CodeGraph

<!-- topic05-operator-guide -->

KD-029 keeps retrieval simple: choose the actor and retrieval capability independently, start
with the source that best fits the question, and escalate within a bounded budget. Native
`read`/`grep`/`glob` remains the baseline. CodeGraph is an optional, default-off capability adapter
for relationship and blast-radius questions; it is not a required workflow stage.

## Selection and authority

The four legal arms are Lead/native, Lead/CodeGraph, Scout/native then Lead, and
Scout/CodeGraph then Lead. Cheap Scout is read-only advisory retrieval. It cannot edit, review,
integrate, verify acceptance, or issue a verdict. Reviewer chooses native, CodeGraph, or mixed
retrieval independently and rereads current source for every load-bearing finding.

Graph output is a bounded hypothesis, never source truth. An absence claim requires current
native-source corroboration. Do not persist both a raw graph payload and an equivalent summary
across session boundaries.

## Capability and process boundary

The selected integration is the checked-in capability adapter. No MCP server, no interactive
upstream installer, and no hooks, daemon, or auto-update are part of this path. The adapter invokes
only the pinned managed bundle through absolute recorded paths with shell execution disabled.

Models may provide only the bounded question and max_files. They cannot choose an executable,
command, working directory, environment, or index path. The wrapper validates its closed runtime
record, component manifest, receipt, version, platform, and artifact digest before retrieval.

## Worktree, state, and fallback

There is one physical `.codegraph` index per Git worktree; shared and symlinked indexes are
refused. Initialization happens before a candidate is frozen. A frozen candidate never triggers
lazy initialization. Topic 04 state owns `.codegraph/.gitignore`, candidate identity, and source
snapshot binding; the adapter checks both candidate and source again after the query.

Every unavailable, partial, failed, timed-out, or unhealthy CodeGraph outcome names native
retrieval as the fallback—never an opaque model retry loop. The Lead continues with
`read`/`grep`/`glob`; Cheap Scout follows Flash `xhigh`, then Pro `xhigh`, then returns retrieval to
the Lead when DeepSeek is unavailable. No premium or unrelated provider silently substitutes for
that chain.

## Install, remove, and retained data

Default installation does not provision or discover CodeGraph. Explicitly add the `codegraph`
component and either provide the pinned offline artifact or separately authorize its pinned
download. The state component is required. The managed binary bundle is shared read-only; indexes
remain worktree-local.

Uninstall restores template-owned files but retains the exact known bundle and indexes. Use
`scripts/cleanup-codegraph.ps1` in dry-run mode, inspect the resolved exact path, then apply an
explicit bundle or index cleanup. The cleanup helper never searches broadly and never manages Git
worktrees.

## Evidence and promotion

The benchmark compares the four arms on identical snapshots, with graph runs split into cold and
warm conditions and native targets unable to see CodeGraph files, instructions, or environment.
Model spend requires an explicit switch and exact confirmation. Usage fields come only from
provider telemetry; missing values remain `not_measured`. DeepSeek unavailability is
`ENVIRONMENT_BLOCKED`, not evidence of a replacement provider.

Correctness, contamination, identity, and fallback gates run before efficiency. A recommendation
is task-class-specific. No run makes CodeGraph a universal default or creates a
CodeGraph-specific percentage threshold; changing the default requires a new recorded decision.

