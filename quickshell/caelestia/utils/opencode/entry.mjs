import { createInterface } from "node:readline";
import { OllamaAdapter, ClaudeAdapter } from "./providers.mjs";
import { CodexAdapter } from "./codex.mjs";

const provider = process.argv[2] || "opencode";
if (provider === "opencode") {
  // Lazy import: other backends need neither the OpenCode SDK nor its service.
  await import("./bridge.mjs");
} else {
  const emit = value => process.stdout.write(JSON.stringify(value) + "\n");
  const Adapter = { ollama: OllamaAdapter, claude: ClaudeAdapter, codex: CodexAdapter }[provider];
  if (!Adapter) throw new Error("Unknown AI provider.");
  const adapter = new Adapter(emit);
  const input = createInterface({ input: process.stdin });
  let queue = Promise.resolve();
  input.on("line", line => {
    queue = queue.then(() => adapter.command(JSON.parse(line))).catch(error => emit({ type: "error", message: error.message }));
  });
  const close = () => { adapter.close(); process.exit(0); };
  input.on("close", close);
  process.on("SIGTERM", close);
  process.on("SIGINT", close);
}
