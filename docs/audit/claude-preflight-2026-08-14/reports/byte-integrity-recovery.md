# Historical Evidence Byte-Integrity Recovery

## Result

- 975 existing snapshot entries inspected.
- 838 entries already matched raw bytes.
- 132 entries were restored to their existing snapshot SHA-256 values.
- 5 entries remain normalized-text-equivalent but are not raw-byte-reproducible.
- No snapshot, manifest, or pinned SHA-256 value was changed.

## Root cause

The original candidate was hashed while generated CRLF or mixed-EOL files were untracked.
With `core.autocrlf=input` and no repository attributes, Git stored LF blobs while the original
working tree retained pre-clean-filter bytes. A later checkout exposed the mismatch.

## Closed limitations

- `docs/archive/reviews/opus5-response-to-gpt56-counter-review.md` — `5c1f4ed33f3b9e57001a54a81dfc55f835e11521d19ce8bde145056ed1477c2b`
- `docs/evidence/phase-00/E3-J/raw/J1-attempt-002.run.json` — `b08da68322a73112e1495aa1bd888dadde7c1dde608add5c3632401c07e532b5`
- `docs/evidence/phase-00/E3-J/raw/J1-attempt-003.run.json` — `e348796c0d7323a920fde8ac90de5daae2e8fa898978a233fa09a0ff89cc7b59`
- `docs/evidence/phase-00/E3-J/raw/J1.run.json` — `27afe78ce8d9daec2f0a0cd058829428156a50a2d0e090ed81581bd8bbdfe76a`
- `spec/phases/phase-00-foundation.md` — `fd01490b089317f6253e4426a431af3d9275cffafd0ce56a200c4a02d2758b9b`

## One additional pinned path outside the snapshot set

`docs/evidence/current-product/topic-03/deepseek-smoke.yml` is bound by
`docs/evidence/current-product/topic-03/manifest.yml` but does not appear in
`02-POST-CLEANUP-CANDIDATE-SNAPSHOT.jsonl` at all, so the snapshot-driven repair never saw it.
It was repaired against the pre-existing manifest pin rather than the snapshot:

- pinned SHA-256 (unchanged, `manifest.yml` row): `112f4ccc147f51ca88c42ac9e30011588002f8876111a37231cae1b4cd994ba1`
- checkout SHA-256 before repair: `f0060ee04c15f18d84bf730ba2aebc299717e6126f30adf61ce09c5f3e59ede9`
- reconstruction applied: all-CRLF, the unique authorized candidate that matched
- verification: `git diff --ignore-space-at-eol --exit-code` exits `0` for this path

The pinned value was read, never written. The restored working-tree count is therefore 133
paths, not 132: the 132 snapshot entries plus this one manifest-pinned path.

A repository-wide sweep of every machine-readable manifest under `docs/evidence`, `docs/audit`,
`registry`, `spec`, `evals`, and `template` found 334 `path` + `sha256` pairs. After this repair
every pair that resolves to a file in this repository matches its pinned value exactly. The
remaining unresolved rows point outside this repository by design: five
`packages/coding-agent/src/**` rows in `docs/evidence/phase-00/E3-L/source-identity.json` name
upstream OMP source files, and three `.omp/skills/**` rows in
`docs/evidence/current-product/topic-08/behavior-manifest.json` are install-relative paths.

## Non-claims

- The five unavailable mixed-EOL byte sequences were not reconstructed or replaced.
- Passing normalized-text comparison is not claimed as raw-byte identity.
- No provider, live install, remote repository, or external backup was used.
