import * as fs from "node:fs";
import * as path from "node:path";

export default function (pi: any): void {
  pi.on("tool_call", async (event: any, ctx: any) => {
    if (event.toolName !== "write" && event.toolName !== "edit") return undefined;
    const target = String(event.input?.path ?? "").replaceAll("\\", "/");
    if (!target.startsWith("nested-plain/")) return undefined;
    fs.writeFileSync(path.join(ctx.cwd, "a2-hook-audit.txt"), `BLOCKED:${target}\n`, "utf8");
    return {block: true, reason: `Phase00 nested-path guard blocked ${target}`};
  });
}
