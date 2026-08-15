import { createHash } from "node:crypto";
import fs from "node:fs";
import path from "node:path";

function fail(code) {
  process.stdout.write(`${JSON.stringify({
    schema_version: 1,
    record_type: "round0912_fake_runtime_result",
    status: "FAIL",
    code,
    provider_calls: 0,
    model_processes_started: 0,
  })}\n`);
  process.exitCode = 2;
}

const counterPath = process.env.ROUND0912_FAKE_COUNTER;
const promptArguments = process.argv.slice(2);
if (!counterPath || !path.isAbsolute(counterPath)) {
  fail("counter_path_missing");
} else if (!fs.existsSync(path.join(process.cwd(), ".git"))) {
  fail("scratch_git_missing");
} else if (promptArguments.length !== 1 || Buffer.byteLength(promptArguments[0], "utf8") > 8_192) {
  fail("prompt_boundary_invalid");
} else {
  const current = fs.existsSync(counterPath)
    ? Number.parseInt(fs.readFileSync(counterPath, "utf8").trim(), 10)
    : 0;
  if (!Number.isSafeInteger(current) || current < 0) {
    fail("counter_invalid");
  } else {
    fs.writeFileSync(counterPath, `${current + 1}\n`, "utf8");
    process.stdout.write(`${JSON.stringify({
      schema_version: 1,
      record_type: "round0912_fake_runtime_result",
      status: "PASS",
      code: "ok",
      cwd_is_git: true,
      prompt_sha256: createHash("sha256").update(promptArguments[0], "utf8").digest("hex"),
      provider_calls: 0,
      model_processes_started: 0,
    })}\n`);
  }
}
