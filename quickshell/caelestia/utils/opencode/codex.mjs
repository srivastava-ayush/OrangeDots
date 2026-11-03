import { spawn } from "node:child_process";
import { createInterface } from "node:readline";
import { ChatAdapter } from "./providers.mjs";

// Native app-server protocol retains Codex authentication, sessions and approvals.
// Read-only sandbox is intentional; this sidebar never requests elevated access.
export class CodexAdapter extends ChatAdapter {
  async init(command) {
    this.requests = new Map(); this.approvals = new Map(); this.serial = 0;
    this.proc = spawn("codex", ["app-server"], { cwd: command.directory, stdio: ["pipe", "pipe", "pipe"] });
    this.proc.stdin.on("error", () => {});
    this.proc.on("error", () => this.fail(new Error("Install Codex CLI and sign in with codex login.")));
    this.proc.stderr.resume();
    createInterface({ input: this.proc.stdout }).on("line", line => {
      try { this.receive(JSON.parse(line)); } catch (error) { this.fail(error); }
    });
    this.proc.on("close", () => this.fail(new Error("Codex app-server closed. Reconnect to continue.")));
    await this.rpc("initialize", { clientInfo: { name: "orangeshell", title: "OrangeShell AI sidebar", version: "1.0.0" } });
    this.send({ method: "initialized", params: {} });
    if (command.sessionID) await this.rpc("thread/resume", { threadId: command.sessionID, cwd: command.directory, approvalPolicy: "untrusted", sandbox: "read-only" });
    await super.init(command);
  }
  send(message) { this.proc.stdin.write(JSON.stringify(message) + "\n"); }
  rpc(method, params) {
    const id = ++this.serial;
    return new Promise((resolve, reject) => {
      const timeout = setTimeout(() => { this.requests.delete(id); reject(new Error(`Codex ${method} timed out.`)); }, 20000);
      this.requests.set(id, { resolve: value => { clearTimeout(timeout); resolve(value); }, reject: error => { clearTimeout(timeout); reject(error); } });
      this.send({ method, params, id });
    });
  }
  fail(error) {
    for (const request of this.requests.values()) request.reject(error);
    this.requests.clear();
    this.finish?.(error);
    if (!this.closing) this.emit({ type: "error", message: error.message });
  }
  receive(message) {
    if (!message.method && message.id !== undefined) {
      const request = this.requests.get(message.id);
      this.requests.delete(message.id);
      if (message.error) request?.reject(new Error(message.error.message));
      else request?.resolve(message.result);
      return;
    }
    const params = message.params || {};
    if (params.threadId && params.threadId !== this.sessionID) return;
    if (message.id !== undefined) {
      if (["item/commandExecution/requestApproval", "item/fileChange/requestApproval"].includes(message.method)) {
        const id = String(message.id);
        this.approvals.set(id, message.id);
        this.permissions ||= [];
        this.permissions.push({ id, action: message.method.includes("commandExecution") ? "run command" : "change files", resources: [params.command || params.reason || params.grantRoot || "Codex request"], metadata: params });
        this.emit({ type: "permissions", items: this.permissions });
      } else if (message.method === "item/permissions/requestApproval") {
        this.send({ id: message.id, result: { permissions: {} } });
      } else this.send({ id: message.id, error: { code: -32601, message: "Unsupported interactive request; use Codex CLI." } });
      return;
    }
    if (message.method === "item/agentMessage/delta") this.delta(params.delta || "");
    if (message.method === "turn/completed") {
      const error = params.turn?.error;
      this.finish?.(error ? new Error(error.message || "Codex turn failed.") : undefined);
    }
  }
  async run(text) {
    this.cancelled = false;
    if (!this.sessionID) {
      const thread = await this.rpc("thread/start", { cwd: this.directory, approvalPolicy: "untrusted", sandbox: "read-only", ...(this.model ? { model: this.model } : {}) });
      this.session(thread.thread.id);
    }
    const done = new Promise((resolve, reject) => { this.finish = error => { this.finish = undefined; error ? reject(error) : resolve(); }; });
    // Attach a rejection handler immediately: the server can exit while the
    // turn/start RPC is still pending, rejecting both promises together.
    done.catch(() => {});
    try {
      const result = await this.rpc("turn/start", { threadId: this.sessionID, input: [{ type: "text", text }], effort: this.effort || null });
      this.turnID = result.turn.id;
      if (this.cancelled) await this.stop();
      await done;
    } finally {
      this.finish = undefined;
      this.turnID = undefined;
      this.permissions = [];
      this.approvals.clear();
    }
  }
  async permission(command) {
    const id = this.approvals.get(command.id);
    if (id === undefined || !["once", "reject"].includes(command.decision)) throw new Error("Invalid Codex approval.");
    this.send({ id, result: { decision: command.decision === "once" ? "accept" : "decline" } });
    this.approvals.delete(command.id);
    this.permissions = this.permissions.filter(request => request.id !== command.id);
    this.emit({ type: "permissions", items: this.permissions });
  }
  async stop() {
    this.cancelled = true;
    if (this.turnID && this.busy) await this.rpc("turn/interrupt", { threadId: this.sessionID, turnId: this.turnID });
  }
  close() { this.closing = true; clearTimeout(this.flushTimer); this.proc?.kill("SIGTERM"); }
}
