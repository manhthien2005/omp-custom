import { discoverAgents } from "@oh-my-pi/pi-coding-agent/task";
import { buildOutputValidator } from "@oh-my-pi/pi-coding-agent/tools/output-schema-validator";

export default function topic06AgentDiscoveryProbe(api) {
  api.on("session_start", async (_event, context) => {
    const discovery = await discoverAgents(context.cwd);
    const selected = discovery.agents
      .filter((agent) => ["cheap-scout", "worker", "reviewer"].includes(agent.name))
      .map((agent) => {
        const built = buildOutputValidator(agent.output);
        return {
          name: agent.name,
          output: agent.output,
          model: agent.model,
          thinkingLevel: agent.thinkingLevel,
          blocking: agent.blocking,
          spawns: agent.spawns ?? [],
          schemaError: built.error ?? null,
          rejectsMalformed: built.validator?.validate({}).success === false,
        };
      })
      .sort((left, right) => left.name.localeCompare(right.name));
    process.stdout.write(`TOPIC06_AGENT_DISCOVERY=${JSON.stringify(selected)}\n`);
    context.shutdown();
  });
}
