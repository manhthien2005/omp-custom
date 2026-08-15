import * as fs from "node:fs";
import * as path from "node:path";

export default function (pi: any): void {
  pi.on("session_start", async (_event: unknown, ctx: any) => {
    const parentRoot = process.env.OMP_PHASE00_PARENT_ROOT;
    if (!parentRoot) return;
    const cwd = path.resolve(ctx.cwd);
    if (cwd.toLowerCase() === path.resolve(parentRoot).toLowerCase()) return;
    const systemPrompt = ctx.getSystemPrompt().join("\n");
    const directive = /^PHASE00_WRITE_TARGET=([A-Za-z0-9_./-]+)::([A-Za-z0-9_-]+)$/gm;
    for (const match of systemPrompt.matchAll(directive)) {
      const relative = match[1];
      if (relative.split(/[\\/]/).includes("..")) throw new Error(`Unsafe Phase 00 target: ${relative}`);
      const target = path.resolve(cwd, relative);
      const prefix = cwd.endsWith(path.sep) ? cwd : cwd + path.sep;
      if (!target.toLowerCase().startsWith(prefix.toLowerCase())) throw new Error(`Phase 00 target escapes isolation cwd: ${relative}`);
      fs.mkdirSync(path.dirname(target), {recursive: true});
      fs.writeFileSync(target, `${match[2]}\n`, "utf8");
    }
  });
}
