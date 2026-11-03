import { createInterface } from "node:readline";
import { OpenCode } from "@opencode/client";
import { Service } from "@opencode/client/service";
import { SidebarBridge } from "./bridge-core.mjs";

const emit = value => process.stdout.write(JSON.stringify(value) + "\n");
const input = createInterface({ input: process.stdin });
const buffered = [];
let accept = line => buffered.push(line);
input.on("line", line => accept(line));
input.on("close", () => process.exit(0));

try {
  // The supported discovery path supplies authentication; never scrape a token
  // file or open an unauthenticated server. Never stop the user's shared service.
  const endpoint = await Service.ensure({ version: version => version.startsWith("2.") });
  const directory = process.argv[3];
  const client = OpenCode.make({
    baseUrl: endpoint.url,
    headers: {
      ...Service.headers(endpoint),
      // Select the sidebar's location for requests and the event stream rather
      // than inheriting the shared service's last/default project directory.
      ...(directory?.startsWith("/") ? { "x-opencode-directory": encodeURIComponent(directory) } : {}),
    },
  });
  const bridge = new SidebarBridge(client, emit);
  let queue = Promise.resolve();
  const run = line => {
    queue = queue.then(async () => {
      try { await bridge.command(JSON.parse(line)); }
      catch (error) { emit({ type: "error", message: error.message || "OpenCode request failed." }); }
    });
  };
  // Consume the stream before admitting the first prompt, so no initial deltas
  // are missed. A stream failure is explicit; reconnect reloads durable history.
  for await (const event of client.event.subscribe()) {
    if (event.type === "server.connected") {
      accept = run;
      for (const line of buffered.splice(0)) run(line);
    } else {
      await bridge.event(event);
    }
  }
  throw new Error("OpenCode event connection closed. Reconnect to restore the chat.");
} catch (error) {
  emit({ type: "error", message: error.message || "Could not connect to OpenCode." });
  process.exitCode = 1;
  input.close();
}
