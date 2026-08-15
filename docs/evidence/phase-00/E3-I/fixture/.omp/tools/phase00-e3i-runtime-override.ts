import path from "node:path";
import type { CustomToolFactory } from "@oh-my-pi/pi-coding-agent";

const normalize = (value: string): string =>
  path.resolve(value).replace(/[\\/]+$/, "").toLowerCase();

const factory: CustomToolFactory = (pi) => {
  const parentCwd = process.env.OMP_PHASE00_E3IL_PARENT_CWD;
  if (!parentCwd || normalize(pi.cwd) !== normalize(parentCwd)) return [];

  const assertParentScope = (): void => {
    const currentParent = process.env.OMP_PHASE00_E3IL_PARENT_CWD;
    if (!currentParent || normalize(pi.cwd) !== normalize(currentParent)) {
      throw new Error("P00_E3L_PARENT_SCOPE_MISMATCH");
    }
  };

  const reader = {
    name: "phase00_e3l_read_apply",
    label: "Phase 00 E3-L Live Apply Reader",
    description: "Reads only task.isolation.apply from the live parent settings object.",
    loadMode: "essential" as const,
    parameters: pi.zod.object({}),
    async execute() {
      assertParentScope();
      const value = pi.pi.settings.get("task.isolation.apply");
      if (typeof value !== "boolean") {
        throw new Error("P00_E3L_READER_NON_BOOLEAN");
      }
      const details = {
        probe: "phase00-e3l-live-reader-v1",
        setting: "task.isolation.apply",
        operation: "pi.pi.settings.get",
        value,
        scope: "parent-only",
      };
      return {
        content: [{ type: "text" as const, text: JSON.stringify(details) }],
        details,
      };
    },
  };

  const tools = [reader];
  if (process.env.OMP_PHASE00_E3IL_ENABLE_OVERRIDE !== "1") return tools;

  tools.push({
    name: "phase00_e3i_override_apply_true",
    label: "Phase 00 E3-I Runtime Override",
    description: "Sets only task.isolation.apply=true in the disposable parent session.",
    loadMode: "essential" as const,
    parameters: pi.zod.object({}),
    async execute() {
      assertParentScope();

      const before = pi.pi.settings.get("task.isolation.apply");
      pi.pi.settings.override("task.isolation.apply", true);
      const after = pi.pi.settings.get("task.isolation.apply");
      const details = {
        probe: "phase00-e3i-runtime-override-v1",
        setting: "task.isolation.apply",
        before,
        operation: "pi.pi.settings.override",
        requested: true,
        after,
        calledSet: false,
        calledFlushOrSave: false,
        scope: "parent-only",
      };
      return {
        content: [{ type: "text" as const, text: JSON.stringify(details) }],
        details,
      };
    },
  });
  return tools;
};

export default factory;
