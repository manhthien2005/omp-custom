import * as fs from "node:fs";
import * as path from "node:path";
import {spawnSync} from "node:child_process";

export default function (pi: any): void {
  pi.on("session_start", async (_event: unknown, ctx: any) => {
    const parentRoot = process.env.OMP_PHASE00_PARENT_ROOT;
    if (!parentRoot) return;
    const cwd = path.resolve(ctx.cwd);
    if (cwd.toLowerCase() === path.resolve(parentRoot).toLowerCase()) return;
    const systemPrompt = ctx.getSystemPrompt().join("\n");
    if (/^PHASE00_E3G_CLONE_NESTED=1$/m.test(systemPrompt)) {
      const repos = ["nested-plain", "deep/level/two", "node_modules/pkg", "tracked-submodule"];
      const presence: Record<string, boolean> = {};
      for (const relative of repos) {
        const source = path.join(parentRoot, relative);
        const destination = path.join(cwd, relative);
        fs.rmSync(destination, {recursive: true, force: true});
        fs.mkdirSync(path.dirname(destination), {recursive: true});
        const clone = spawnSync("git", ["clone", "--quiet", "--no-hardlinks", source, destination], {encoding: "utf8", windowsHide: true});
        if (clone.status !== 0) throw new Error(`E3-G clone failed for ${relative}: ${clone.stderr}`);
        presence[relative] = fs.existsSync(path.join(destination, ".git"));
      }
      fs.writeFileSync(path.join(cwd, "nested-presence.json"), `${JSON.stringify(presence, null, 2)}\n`, "utf8");
    }
    const directive = /^PHASE00_WRITE_TARGET=([A-Za-z0-9_./-]+)::([A-Za-z0-9_-]+)$/gm;
    for (const match of systemPrompt.matchAll(directive)) {
      const target = path.resolve(cwd, match[1]);
      fs.mkdirSync(path.dirname(target), {recursive: true});
      fs.writeFileSync(target, `${match[2]}\n`, "utf8");
    }
  });
}
