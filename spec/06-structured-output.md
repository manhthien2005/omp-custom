# 06 — Structured Output

> OPUS PROPOSED SPEC v1 | How result contracts become enforced instead of suggested.
> Verified against `tools/yield.ts`, `task/types.ts`, `discovery/helpers.ts`.

---

## A. The Current Gap

Four schema files exist under `template/.omp/schemas/`. Four agent prompts say
"Return schema: `agent-result`". Nothing connects them.

OMP has no `.omp/schemas/` discovery. Grepping the entire discovery layer for a
`schemas` directory returns nothing — the only directories OMP reads under a
config dir are `commands`, `rules`, `prompts`, `extensions`, `instructions`,
`hooks`, `tools`, `skills`, and `agents`. So the four YAML files are inert, and
the phrase "Return schema: `agent-result`" is a request the model may honour by
imitation and may equally ignore. There is no validation, no retry, no failure.

That is the whole of the problem. The fix is not to invent a loader.

---

## B. How OMP Actually Enforces Output

Two verified mechanisms, both real.

### 1. `output:` in agent frontmatter

`parseAgentFields` reads an `output` key straight off the frontmatter and
carries it into `ParsedAgentFields.output`. `task/types.ts` describes a
caller-provided schema as one whose "presence overrides the selected agent's
schema" — confirming agents carry a schema of their own, sourced from this
field.

This is the mechanism the template should use. Each worker declares its result
contract in its own file, once, next to the prose that describes it.

### 2. `outputSchema` on the `task` call

Every variant of the task schema (`task/index.ts`, `createTaskSchema`) accepts:

```
"outputSchema?": "object | boolean | string | null"
"schemaMode?":   '"permissive" | "strict"'
```

A caller-supplied `outputSchema` overrides the agent's own. This is the escape
hatch for a one-off shape, not the default path.

### 3. What `yield` does with it

`YieldTool`'s constructor builds a validator from `session.outputSchema` and
wraps the schema so the model must submit `{result: {data: …}}` or
`{result: {error: "…"}}`. Then:

- On mismatch, it throws a message naming the exact validation issues and the
  number of retries left. The model sees the error and resubmits.
- After `MAX_SCHEMA_RETRIES = 3` consecutive failures it **accepts the
  non-conforming payload anyway** and flags `schemaOverridden: true`.
- An untyped empty result fails 3 times and then aborts the child outright.

The override at retry 4 is the critical operational fact. A schema is a strong
nudge with a bounded retry budget, not a hard gate. A worker that cannot
produce the shape will eventually return something else, marked. The Tech Lead
must treat `schemaOverridden` as a signal, not ignore it.

### 4. Incremental sections

`type: ["findings"]` submits one section non-terminally and accumulates.
`type: "result"` finalizes. Section labels are validated against the schema's
top-level property names when the schema is closed; unknown labels are
rejected immediately with the valid list.

This is useful for the Reviewer, which naturally produces findings one at a
time, and for the Verifier, which produces per-criterion results.

---

## C. Proposed Design

Convert each of the four YAML files into a JSON Schema embedded in the
frontmatter of the agent that returns it.

| Contract | Home | Rationale |
|---|---|---|
| `agent-result` | `implementer.md` frontmatter `output:` | The Implementer is its primary producer |
| `agent-result` (explorer variant) | `explorer.md` frontmatter `output:` | Explorer's shape differs — no `files_changed` |
| `verification-result` | `verifier.md` frontmatter `output:` | Sole producer |
| `review-result` | `reviewer.md` frontmatter `output:` | Sole producer |
| `task-packet` | Not an output — see below | Produced by the session, consumed as prose |

### The task-packet is different

`task-packet` describes what the *session* sends *into* a worker via the `task`
tool's `task:` string parameter. That parameter is a plain string. There is no
input schema to enforce, and OMP does not offer one.

So `task-packet` stays documentation — but it is documentation with a job: it
is the checklist the session follows when composing the `task:` string, and the
thing `13-validation-and-evaluation.md` can assert against by inspecting what
was actually sent. Keep the YAML, retitle it as a composition guide, and stop
implying runtime enforcement.

### Keep the YAML files

They remain valuable as:

- the human-readable source of truth,
- the input to a small generator that emits the JSON Schema into agent
  frontmatter (so the two never drift by hand),
- a validation target: `validate-template.ps1` can check that every YAML
  contract has a corresponding `output:` block in the right agent file.

What changes is the claim. They stop being described as enforcement and start
being described as source.

---

## D. Schema Content Rules

Derived from the verified `yield` behaviour:

1. **Prefer flat, closed objects.** `withSectionVariants` expands a closed
   object schema into a union that also accepts each top-level property alone,
   which is what makes incremental yields work. Deeply nested schemas lose
   this.
2. **Keep required fields minimal.** Every required field the model struggles
   with burns one of three retries. Require only what the Tech Lead cannot
   proceed without.
3. **Avoid `$ref`.** The constructor dereferences and then *throws* if any
   `$ref` survives, falling back to an unconstrained object. Inline everything.
4. **Do not require chain-of-thought fields.** `RULES.md` and the context
   budget both forbid transcript forwarding; a schema field that invites
   narration works against them.
5. **String fields that carry evidence should have `maxLength`.** This is the
   only structural lever available against a Verifier that pastes an entire
   test log into `evidence`.

---

## E. The `status: completed` Contradiction (F-21)

`agent-result.schema.yml` states as a rule that `status: completed` requires at
least one entry in `verification_results`, while listing
`verification_results` under `optional_fields`. As written, the constraint is
unenforceable prose.

JSON Schema can express this directly:

```
allOf: [
  { if:   { properties: { status: { const: "completed" } } },
    then: { required: ["verification_results"],
            properties: { verification_results: { minItems: 1 } } } }
]
```

But `tryEnforceStrictSchema` will likely reject a conditional as
non-strict-representable, which drops the agent to non-strict mode. That is
acceptable — non-strict still validates, it just does not constrain decoding.

Simpler alternative that stays strict: make `verification_results` required
unconditionally, with an empty array permitted, and enforce the
"completed implies non-empty" rule in the Tech Lead's acceptance check. Opus
recommends this: strict decoding is worth more than schema-level elegance, and
the Tech Lead already has to inspect the field.

---

## F. Failure Modes

| Mode | Cause | Detection | Response |
|---|---|---|---|
| Schema override | 4th consecutive validation failure | `schemaOverridden: true` in result | Tech Lead rejects result; re-dispatch with simpler schema |
| Child abort | 4 consecutive empty untyped results | Task returns aborted | Investigate the worker prompt; schema likely unclear |
| Unresolved `$ref` | Schema uses `$ref` | Silent fallback to unconstrained object | Lint schemas for `$ref` in validation |
| Non-strict downgrade | Schema not strict-representable | `strict = false` on the tool | Acceptable; note in validation output |
| Unknown section label | Incremental yield with wrong label | Immediate rejection listing valid labels | Model self-corrects; no action |

The first row is the one that matters. A `schemaOverridden` result that the
Tech Lead accepts silently is exactly the "false completion" `RULES.md`
invariant 1 forbids.

---

## G. Verification

- Each of the four worker agents has an `output:` block in frontmatter.
- No `output:` block contains `$ref`.
- Every schema's required-field set is a subset of what the agent's prompt
  actually instructs it to produce.
- A fixture task run per worker returns a result that validates without
  triggering `schemaOverridden`.
- The Tech Lead's acceptance path explicitly checks `schemaOverridden`.

---

## H. Open Items

| # | Item | Resolution path |
|---|---|---|
| S-1 | Generator from YAML → frontmatter `output:`, or hand-maintained? | Generator preferred; hand-maintained acceptable for v0 with a validation check |
| S-2 | Does `output:` frontmatter accept YAML-inline JSON Schema, or a path? | Needs one experiment; `unknown` type suggests inline |
| S-3 | Explorer and Implementer share `agent-result` or diverge? | Diverge — Explorer has no `files_changed` |
