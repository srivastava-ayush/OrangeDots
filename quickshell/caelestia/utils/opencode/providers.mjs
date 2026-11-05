import { spawn } from "node:child_process";
import { createInterface } from "node:readline";
import { randomUUID } from "node:crypto";

export function localOllamaUrl(value) {
  const url = new URL(value || "http://127.0.0.1:11434");
  if (url.protocol !== "http:" || !["localhost", "127.0.0.1", "[::1]"].includes(url.hostname) || url.username || url.password || url.search || url.hash || !["", "/"].includes(url.pathname))
    throw new Error("Ollama must use a local loopback HTTP URL, without credentials or a path.");
  return url.origin;
}

export class ChatAdapter {
  constructor(emit) { this.emit = emit; this.rows = []; this.busy = false; this.sessionID = ""; }
  async init(command) {
    if (!command.directory?.startsWith("/")) throw new Error("Choose an absolute working directory.");
    this.directory = command.directory;
    this.model = command.model || "";
    this.effort = command.effort || "";
    this.sessionID = command.sessionID || "";
    this.rows = (command.history || []).filter(row => ["user", "assistant"].includes(row.role) && typeof row.text === "string").slice(-40).map(row => ({ id: row.id || randomUUID(), role: row.role, text: row.text.slice(-60000) }));
    this.snapshot();
    this.emit({ type: "ready" });
  }
  snapshot() { this.flush(); this.emit({ type: "snapshot", rows: this.rows.slice(-40), permissions: this.permissions || [], busy: this.busy, forms: 0 }); }
  session(id) { this.sessionID = id; this.emit({ type: "session", id, directory: this.directory }); }
  flush() {
    clearTimeout(this.flushTimer); this.flushTimer = undefined;
    if (this.pending) this.emit({ type: "delta", id: this.answer.id, text: this.pending });
    this.pending = "";
  }
  delta(text) {
    if (!this.busy || !text) return;
    this.answer.text = (this.answer.text + text).slice(-60000);
    this.pending = ((this.pending || "") + text).slice(-60000);
    this.flushTimer ??= setTimeout(() => this.flush(), 50);
  }
  async command(command) {
    if (command.type === "init") return this.init(command);
    if (command.type === "reset") {
      await this.stop();
      await this.job;
      this.emit({ type: "reset-ready" });
      return;
    }
    if (command.type === "stop") return this.stop();
    if (command.type === "permission") return this.permission?.(command);
    if (command.type !== "send" || this.busy || !command.text?.trim()) return;
    if (!this.directory) throw new Error("Connect before sending a message.");
    if (typeof command.effort === "string") this.effort = command.effort;
    this.busy = true;
    this.rows.push({ id: randomUUID(), role: "user", text: command.text });
    this.answer = { id: randomUUID(), role: "assistant", text: "" };
    this.rows.push(this.answer);
    this.rows = this.rows.slice(-40);
    this.snapshot();
    // Do not block stdin: Stop/permission replies must work during generation.
    this.job = this.run(command.text).catch(error => {
      if (error.name !== "AbortError") this.emit({ type: "error", message: error.message });
    }).finally(() => { this.busy = false; this.snapshot(); });
  }
  close() { clearTimeout(this.flushTimer); Promise.resolve(this.stop?.()).catch(() => {}); }
}

export class OllamaAdapter extends ChatAdapter {
  async init(command) { this.url = localOllamaUrl(command.ollamaUrl); await super.init(command); }
  async run() {
    if (!this.model) throw new Error("Choose an installed Ollama model in Nexus → Panels → Sidebar.");
    this.abort = new AbortController();
    const response = await fetch(`${this.url}/api/chat`, {
      method: "POST", headers: { "Content-Type": "application/json" }, signal: this.abort.signal,
      body: JSON.stringify({ model: this.model, stream: true, keep_alive: 0, ...(this.effort ? { think: this.effort === "on" ? true : this.effort === "off" ? false : this.effort } : {}), messages: this.rows.filter(row => row !== this.answer).map(row => ({ role: row.role, content: row.text })) }),
    });
    if (!response.ok) throw new Error(`Ollama returned ${response.status}. Check the local server and installed model.`);
    let buffer = "";
    const consume = line => {
      if (!line.trim()) return;
      const event = JSON.parse(line);
      if (event.error) throw new Error(event.error);
      this.delta(event.message?.content || "");
    };
    for await (const chunk of response.body.pipeThrough(new TextDecoderStream())) {
      buffer += chunk;
      let newline;
      while ((newline = buffer.indexOf("\n")) >= 0) { consume(buffer.slice(0, newline)); buffer = buffer.slice(newline + 1); }
    }
    consume(buffer);
  }
  stop() { this.abort?.abort(); }
}

export class ClaudeAdapter extends ChatAdapter {
  async run(text) {
    this.cancelled = false;
    const args = ["-p", "--verbose", "--output-format", "stream-json", "--include-partial-messages", "--bare", "--tools", "", "--disallowedTools", "mcp__*", "--strict-mcp-config", "--mcp-config", '{"mcpServers":{}}'];
    if (this.model) args.push("--model", this.model);
    if (this.effort) args.push("--effort", this.effort);
    if (this.sessionID) args.push("--resume", this.sessionID);
    await new Promise((resolve, reject) => {
      const proc = this.proc = spawn("claude", args, { cwd: this.directory, stdio: ["pipe", "pipe", "pipe"] });
      proc.stdin.on("error", () => {});
      let stderr = "", failure = "";
      proc.stderr.on("data", chunk => { stderr = (stderr + chunk).slice(-3000); });
      const lines = createInterface({ input: proc.stdout });
      lines.on("line", line => {
        try {
          const event = JSON.parse(line);
          if (event.session_id && event.session_id !== this.sessionID) this.session(event.session_id);
          if (event.type === "stream_event" && event.event?.delta?.type === "text_delta") this.delta(event.event.delta.text);
          if (event.type === "assistant" && !this.answer.text) this.delta(event.message?.content?.filter(part => part.type === "text").map(part => part.text).join("\n") || "");
          if (event.type === "result") {
            if (event.is_error) failure = event.result || event.errors?.join("\n") || "Claude Code could not complete the response.";
            else if (!this.answer.text && event.result) this.delta(event.result);
          }
        } catch (_) { failure = "Invalid Claude Code stream. Update the CLI and retry."; }
      });
      proc.on("error", error => reject(new Error(error.code === "ENOENT" ? "Install Claude Code and sign in with claude auth login." : error.message)));
      proc.on("close", code => {
        this.proc = undefined;
        if (code && !this.cancelled) reject(new Error(failure || stderr || "Claude Code exited unexpectedly."));
        else if (failure) reject(new Error(failure));
        else resolve();
        this.cancelled = false;
      });
      proc.stdin.end(text);
    });
  }
  stop() { this.cancelled = true; this.proc?.kill("SIGTERM"); }
}
