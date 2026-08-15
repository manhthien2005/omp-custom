# Topic 05 retrieval benchmark

This harness measures two independent choices: who retrieves and which retrieval capability they
use. The four arms are Lead/native (A), Lead/CodeGraph (B), Cheap Scout/native then Lead (C), and
Cheap Scout/CodeGraph then Lead (D). A versus B and C versus D isolate the capability boundary;
A versus C and B versus D isolate the Scout boundary.

`plan` is the default and writes nothing. `deterministic` creates only disposable fixture
repositories and immutable sanitized run records; it never resolves provider credentials or
starts OMP. Deterministic PASS proves fixture, adapter-oracle, contamination, record, and fallback
behavior only. It is not model-campaign PASS.

Native A/C targets are separate copies with no CodeGraph tool, component instructions, executable
reference, `.codegraph` path, or inherited `CODEGRAPH_*` variable. CodeGraph B/D targets are
separate prepared copies of the identical frozen source snapshot. Every pair records native once
with `cache_condition: absent`; B/D record cold initialization separately from the immediately
following warm retrieval. Cold cost is never hidden in fixture setup.

A live model pilot is never automatic. It requires all of `-Mode model-pilot`,
`-AllowModelSpend`, exact `-Confirmation RUN_TOPIC05_MODEL_PILOT`, and an explicit Lead identity
in `provider/model:effort` form. Cheap Scout remains DeepSeek Flash `xhigh` primary and DeepSeek
Pro `xhigh` fallback only. If neither route is runnable, C/D are `ENVIRONMENT_BLOCKED`; Codex,
Claude, Gemini, or the Lead model never impersonates Scout.

Before its first model request, model-pilot validates a real installed CodeGraph target and the
shared pinned bundle. It reuses an already verified managed cache by default. An offline first use
adds `-CodeGraphArtifactPath`; a network first use additionally requires the separate explicit
`-AllowCodeGraphDownload` switch. Those acquisition controls are mutually exclusive. Failure to
prepare the adapter stops the whole campaign before Lead or Scout spend.

Token fields come only from provider telemetry. Missing provider usage, cache-read usage, or
residual context is `not_measured`; character estimates cannot support a token claim. Failed,
blocked, timed-out, and fallback runs remain immutable campaign data.

Run-record paths are deterministic for campaign, seed, pair, fixture, arm, and cache condition.
Existing records are never overwritten; choose a fresh output directory for a new campaign.

Correctness and contamination gates run before efficiency. Reports compare only paired identical
snapshot hashes and keep B/D cold and warm results separate. Allowed recommendations are B, D,
both for named task classes, neither, or inconclusive. A finite pilot can reject an obvious
regression but cannot promote CodeGraph, establish a universal default, or invent a
CodeGraph-specific percentage threshold.
