#!/usr/bin/env node
import fs from "node:fs";
import { LIMITS } from "./agent-boundary-schema.mjs";
import {
  BoundaryError,
  canonicalJson,
  composeAgentPacket,
  composeHandoffPacket,
  normalizeBoundaryReceipt,
  parseJsonNoDuplicateKeys,
  validateHandoffPacket,
  validatePacket,
  validateSemanticResult,
} from "./agent-boundary-core.mjs";

function safeFailure(reasonCode, message) {
  return {
    ok: false,
    reason_code: reasonCode,
    message: String(message).slice(0, 240) || "The managed boundary rejected the request.",
  };
}

function execute(envelope) {
  if (!envelope || typeof envelope !== "object" || Array.isArray(envelope) ||
      Object.keys(envelope).sort().join("|") !== "operation|value" || typeof envelope.operation !== "string") {
    return safeFailure("packet_invalid", "The CLI request envelope is invalid.");
  }
  switch (envelope.operation) {
    case "compose": return composeAgentPacket(envelope.value);
    case "compose-handoff": return composeHandoffPacket(envelope.value);
    case "lint-packet": return validatePacket(envelope.value);
    case "lint-handoff": return validateHandoffPacket(envelope.value);
    case "validate-semantic": return validateSemanticResult(envelope.value);
    case "normalize-receipt": return normalizeBoundaryReceipt(envelope.value);
    default: return safeFailure("packet_invalid", "The CLI operation is unsupported.");
  }
}

let result;
let exitCode = 0;
try {
  const bytes = fs.readFileSync(0);
  if (bytes.length > LIMITS.maxInputBytes) throw new BoundaryError("packet_too_large", "CLI input exceeds the byte limit.");
  const text = new TextDecoder("utf-8", { fatal: true }).decode(bytes);
  result = execute(parseJsonNoDuplicateKeys(text));
  if (!result.ok) exitCode = 2;
} catch (error) {
  if (error instanceof BoundaryError) {
    result = safeFailure(error.reason_code, error.message);
    exitCode = error.reason_code === "internal_error" ? 5 : 2;
  } else {
    result = safeFailure("internal_error", "The CLI encountered an internal failure.");
    exitCode = 5;
  }
}

process.stdout.write(`${canonicalJson(result)}\n`);
process.exitCode = exitCode;

