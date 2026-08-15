import fs from "node:fs";
import path from "node:path";

const PROFILE = Object.freeze([
  ["contextPromotion.enabled", false],
  ["compaction.enabled", false],
  ["compaction.strategy", "off"],
  ["compaction.midTurnEnabled", false],
  ["compaction.thresholdPercent", -1],
  ["compaction.thresholdTokens", -1],
  ["compaction.keepRecentTokens", 20_000],
  ["compaction.autoContinue", false],
  ["compaction.idleEnabled", false],
  ["compaction.remoteEnabled", false],
  ["compaction.remoteStreamingV2Enabled", false],
]);

function countNamed(items, name) {
  return Array.isArray(items) ? items.filter((item) => item?.name === name).length : -1;
}

export default function topic07RuntimeProbe(api) {
  const settings = api?.pi?.settings;
  const settingsSurface = typeof settings?.get === "function" && typeof settings?.override === "function";
  let perturbationApplied = false;
  if (settingsSurface) {
    settings.override("compaction.enabled", true);
    perturbationApplied = settings.get("compaction.enabled") === true;
  }

  let scheduled = false;
  api.on("session_start", (_event, ctx) => {
    if (scheduled) return;
    scheduled = true;
    const beforeContinuityHandler = settingsSurface ? settings.get("compaction.enabled") : null;
    ctx.setTimeout(() => {
      let result;
      try {
        api.appendEntry("topic07:runtime-probe", { schema_version: 1, model_free: true });
        const sessionFile = ctx?.sessionManager?.getSessionFile?.() ?? null;
        const artifactsDir = ctx?.sessionManager?.getArtifactsDir?.() ?? null;
        const artifactMarkerPath = typeof artifactsDir === "string"
          ? path.join(artifactsDir, "topic07-runtime-probe.txt")
          : null;
        if (artifactMarkerPath) {
          fs.mkdirSync(artifactsDir, { recursive: true });
          fs.writeFileSync(artifactMarkerPath, "topic07 model-free runtime probe\n", "utf8");
        }
        const exactProfile = settingsSurface && PROFILE.every(([name, expected]) =>
          Object.is(settings.get(name), expected));
        result = {
          ok: true,
          task_tool_count: countNamed(api.getAllTools(), "task"),
          safe_compact_command_count: countNamed(api.getCommands(), "safe-compact"),
          settings_get_available: typeof settings?.get === "function",
          settings_override_available: typeof settings?.override === "function",
          perturbation_applied: perturbationApplied,
          before_continuity_handler: beforeContinuityHandler,
          exact_profile_after_handlers: exactProfile,
          topic07_last_managed_handler_observed:
            perturbationApplied && beforeContinuityHandler === true && exactProfile,
          session_file: sessionFile,
          session_file_exists_before_shutdown:
            typeof sessionFile === "string" && fs.existsSync(sessionFile),
          artifacts_dir: artifactsDir,
          artifact_marker_path: artifactMarkerPath,
        };
      } catch (error) {
        result = { ok: false, error: String(error?.message ?? error).slice(0, 200) };
        process.exitCode = 1;
      }
      process.stdout.write(`TOPIC07_RUNTIME_PROBE=${JSON.stringify(result)}\n`);
      ctx.shutdown();
    }, 0);
  });
}
