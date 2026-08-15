import assert from "node:assert/strict";
import crypto from "node:crypto";
import fs from "node:fs";
import path from "node:path";
import test from "node:test";

import {
  estimateApproxTokens,
  validateBehaviorManifest,
} from "../../template/.omp/contracts/behavior-core.mjs";

const repositoryRoot = path.resolve(import.meta.dirname, "../..");
const fromRoot = (...parts) => path.join(repositoryRoot, ...parts);

function readText(relativePath) {
  return fs.readFileSync(fromRoot(relativePath), "utf8");
}

function parseFrontmatter(relativePath) {
  const text = readText(relativePath).replace(/\r\n?/gu, "\n");
  const match = text.match(/^---\n([\s\S]*?)\n---\n?([\s\S]*)$/u);
  assert.ok(match, `${relativePath} must have closed frontmatter`);
  const frontmatter = match[1];
  const name = frontmatter.match(/^name:\s*(.+)$/mu)?.[1]?.trim();
  const foldedDescription = frontmatter.match(/^description:\s*>\s*\n((?:[ \t]+[^\n]*(?:\n|$))+)/mu)?.[1];
  const inlineDescription = frontmatter.match(/^description:\s*([^>].*)$/mu)?.[1]?.trim();
  const description = foldedDescription === undefined ? inlineDescription :
    foldedDescription.split("\n").map((line) => line.trim()).filter(Boolean).join(" ");
  const autoloadText = frontmatter.match(/^autoloadSkills:\s*(\[[^\n]*\])$/mu)?.[1];
  return {
    text,
    frontmatter,
    body: match[2].trim(),
    name,
    description,
    autoloadSkills: autoloadText === undefined ? [] : JSON.parse(autoloadText),
    alwaysApply: /^alwaysApply:/mu.test(frontmatter),
  };
}

function parseTriggerFixture(relativePath) {
  const text = readText(relativePath).replace(/\r\n?/gu, "\n");
  const expectation = text.match(/^expectation:\s*(should_trigger|should_not_trigger)$/mu)?.[1];
  const skill = text.match(/^skill:\s*([a-z0-9-]+)$/mu)?.[1];
  const cases = [...text.matchAll(/^\s{2}-\s+("(?:[^"\\]|\\.)*")\s*$/gmu)]
    .map((match) => JSON.parse(match[1]));
  return { text, expectation, skill, cases };
}

function sha256File(relativePath) {
  return crypto.createHash("sha256").update(fs.readFileSync(fromRoot(relativePath))).digest("hex");
}

test("ships the approved manifest-selected skill roster and Worker-only autoload", () => {
  const manifest = JSON.parse(readText("template/.omp/contracts/behavior-manifest.json"));
  const validation = validateBehaviorManifest(manifest);
  assert.equal(validation.ok, true, validation.message);
  assert.deepEqual(manifest.skills.filter((row) => row.status === "active").map((row) => row.name), [
    "task-triage",
    "systematic-debugging",
    "evidence-before-completion",
  ]);

  const worker = parseFrontmatter("template/.omp/agents/worker.md");
  const cheapScout = parseFrontmatter("template/.omp/agents/cheap-scout.md");
  const reviewer = parseFrontmatter("template/.omp/agents/reviewer.md");
  assert.deepEqual(worker.autoloadSkills, ["evidence-before-completion"]);
  assert.deepEqual(cheapScout.autoloadSkills, []);
  assert.deepEqual(reviewer.autoloadSkills, []);
  assert.deepEqual(manifest.roles.worker.required_autoload, worker.autoloadSkills);
  assert.deepEqual(manifest.roles["cheap-scout"].required_autoload, cheapScout.autoloadSkills);
  assert.deepEqual(manifest.roles.reviewer.required_autoload, reviewer.autoloadSkills);
});

test("keeps descriptions, bodies, catalog, and RULES inside approved budgets", () => {
  const manifest = JSON.parse(readText("template/.omp/contracts/behavior-manifest.json"));
  const skills = manifest.skills.filter((row) => row.status === "active").map((row) => ({
    row,
    parsed: parseFrontmatter(`template/${row.path}`),
  }));
  for (const { row, parsed } of skills) {
    assert.equal(parsed.name, row.name);
    assert.ok(parsed.description);
    assert.ok(estimateApproxTokens(parsed.description) <= 80, `${row.name} description is oversized`);
    assert.ok(estimateApproxTokens(parsed.body) <= row.body_max_tokens, `${row.name} body is oversized`);
    assert.equal(parsed.alwaysApply, false);
  }
  const listingTokens = skills.reduce((sum, { parsed }) => sum + estimateApproxTokens(parsed.description), 0);
  assert.ok(listingTokens <= 900);
  assert.ok(estimateApproxTokens(readText("template/.omp/RULES.md")) <= 700);
  assert.equal(fs.existsSync(fromRoot("template/.omp/SYSTEM.md")), false);
});

test("binds every active skill to exact bytes, provenance, and positive and negative fixtures", () => {
  const manifest = JSON.parse(readText("template/.omp/contracts/behavior-manifest.json"));
  const fixtureTexts = new Set();
  const provenance = new Map(manifest.provenance.map((row) => [row.id, row]));
  for (const row of manifest.skills.filter((skill) => skill.status === "active")) {
    assert.match(row.sha256, /^[a-f0-9]{64}$/u);
    assert.equal(row.sha256, sha256File(`template/${row.path}`));
    const source = provenance.get(row.provenance_id);
    assert.ok(source, `${row.name} must have provenance`);
    assert.equal(source.license_id, row.license_id);

    const positive = parseTriggerFixture(row.positive_trigger_fixture);
    const negative = parseTriggerFixture(row.negative_trigger_fixture);
    assert.equal(positive.skill, row.name);
    assert.equal(negative.skill, row.name);
    assert.equal(positive.expectation, "should_trigger");
    assert.equal(negative.expectation, "should_not_trigger");
    assert.ok(positive.cases.length > 0);
    assert.ok(negative.cases.length > 0);
    assert.equal(new Set(positive.cases).size, positive.cases.length);
    assert.equal(new Set(negative.cases).size, negative.cases.length);
    assert.equal(fixtureTexts.has(positive.text), false);
    fixtureTexts.add(positive.text);
    assert.equal(fixtureTexts.has(negative.text), false);
    fixtureTexts.add(negative.text);
  }
  const triageNegative = parseTriggerFixture(
    "evals/triggers/topic08/task-triage-negative.yml",
  ).cases.join("\n");
  for (const command of ["/quick", "/standard", "/orchestrated"]) {
    assert.match(triageNegative, new RegExp(command.replace("/", "\\/"), "u"));
  }
});

test("generates a non-null skill lock from the behavior manifest", () => {
  const manifest = JSON.parse(readText("template/.omp/contracts/behavior-manifest.json"));
  const lock = readText("registry/skill-lock.yml");
  assert.match(lock, /^version: "2\.0"$/mu);
  assert.match(lock, /^source_manifest: template\/\.omp\/contracts\/behavior-manifest\.json$/mu);
  assert.doesNotMatch(lock, /hash:\s*null/u);
  for (const row of manifest.skills.filter((skill) => skill.status === "active")) {
    assert.match(lock, new RegExp(`name: ${row.name}[\\s\\S]*?hash: ${row.sha256}`, "u"));
  }
});
