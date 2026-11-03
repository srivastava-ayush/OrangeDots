// OpenCode V2 protocol adapter. No credentials, prompts or session content on disk.
export class SidebarBridge {
  constructor(client, emit) {
    this.client = client;
    this.emit = emit;
    this.sessionID = "";
    this.directory = "";
    this.pending = new Map();
    this.flushTimer = undefined;
  }

  flush() {
    clearTimeout(this.flushTimer);
    this.flushTimer = undefined;
    for (const [id, text] of this.pending) this.emit({ type: "delta", id, text });
    this.pending.clear();
  }

  async snapshot() {
    if (!this.sessionID) return;
    const sessionID = this.sessionID;
    const [messages, permissions, active, forms] = await Promise.all([
      this.client.message.list({ sessionID, limit: 40, order: "desc" }),
      this.client.permission.list({ sessionID }),
      this.client.session.active(),
      this.client.session.form.list({ sessionID }),
    ]);
    if (sessionID !== this.sessionID) return;
    this.flush();
    const rows = messages.data.filter(m => m.type === "user" || m.type === "assistant").reverse().map(m => ({
      id: m.id,
      role: m.type,
      text: (m.type === "user" ? m.text : m.content.filter(p => p.type === "text").map(p => p.text).join("\n\n")).slice(-60000),
    })).filter(m => m.text);
    this.emit({ type: "snapshot", rows, permissions, busy: !!active[sessionID], forms: forms.length });
  }

  async command(command) {
    switch (command.type) {
      case "approval-policy":
        this.autoApproveTools = command.autoApproveTools === true;
        if (this.sessionID) {
          await this.client.session.update({ sessionID: this.sessionID, permissions: [{ action: "*", resource: "*", effect: this.autoApproveTools ? "allow" : "ask" }] });
          if (this.autoApproveTools)
            for (const request of await this.client.permission.list({ sessionID: this.sessionID }))
              await this.client.permission.reply({ sessionID: this.sessionID, requestID: request.id, decision: "once" });
          await this.snapshot();
        }
        break;
      case "init": {
        if (typeof command.directory !== "string" || !command.directory.startsWith("/")) throw new Error("Choose an absolute working directory.");
        this.directory = command.directory;
        this.effort = command.effort || "";
        this.autoApproveTools = command.autoApproveTools === true;
        this.model = undefined;
        if (command.model) {
          const match = command.model.match(/^([^/]+)\/(.+?)(?:#([^#]+))?$/);
          if (!match) throw new Error("OpenCode model must use provider/model#variant, or be blank for the default.");
          this.model = { providerID: match[1], id: match[2], ...(match[3] ? { variant: match[3] } : {}) };
        }
        if (command.sessionID) {
          const session = await this.client.session.get({ sessionID: command.sessionID });
          if (!session.metadata?.orangeshellSidebar) throw new Error("This is not an AI-sidebar session. Start a new chat.");
          this.sessionID = session.id;
          this.directory = session.location.directory;
          this.emit({ type: "session", id: session.id, directory: this.directory });
          await this.client.session.update({ sessionID: session.id, permissions: [{ action: "*", resource: "*", effect: this.autoApproveTools ? "allow" : "ask" }] });
          await this.snapshot();
        }
        this.emit({ type: "ready" });
        break;
      }
      case "send": {
        if (typeof command.text !== "string" || !command.text.trim()) return;
        if (!this.directory) throw new Error("Connect before sending a message.");
        const effort = typeof command.effort === "string" ? command.effort : this.effort;
        if (!this.sessionID) {
          const session = await this.client.session.create({
            title: "OrangeShell AI chat",
            location: { directory: this.directory },
            metadata: { orangeshellSidebar: true },
            ...(this.model ? { model: this.model } : {}),
            // Explicit sidebar preference; never modify global/project rules.
            permissions: [{ action: "*", resource: "*", effect: this.autoApproveTools ? "allow" : "ask" }],
          });
          this.sessionID = session.id;
          this.emit({ type: "session", id: session.id, directory: this.directory });
        }
        if (effort || this.appliedEffort || typeof command.effort === "string") {
          const session = await this.client.session.get({ sessionID: this.sessionID });
          const base = this.model || session.model || (await this.client.model.default({ location: { directory: this.directory } })).data;
          if (!base) throw new Error("Choose an OpenCode model before selecting reasoning effort.");
          const model = { providerID: base.providerID, id: base.id };
          if (effort || this.model?.variant) model.variant = effort || this.model.variant;
          await this.client.session.switchModel({ sessionID: this.sessionID, model });
          this.appliedEffort = effort;
        }
        this.emit({ type: "busy", value: true });
        await this.client.session.prompt({ sessionID: this.sessionID, text: command.text });
        await this.snapshot();
        break;
      }
      case "permission": {
        if (!this.sessionID || !["once", "reject"].includes(command.decision)) throw new Error("Invalid permission reply.");
        await this.client.permission.reply({ sessionID: this.sessionID, requestID: command.id, decision: command.decision });
        this.emit({ type: "permissions", items: await this.client.permission.list({ sessionID: this.sessionID }) });
        break;
      }
      case "reset":
      case "stop":
        if (this.sessionID) {
          await this.client.session.interrupt({ sessionID: this.sessionID });
          // Reset must not depend on reading history from a broken old location.
          if (command.type !== "reset") await this.snapshot();
        }
        if (command.type === "reset") this.emit({ type: "reset-ready" });
        break;
      default:
        throw new Error("Unknown sidebar command.");
    }
  }

  async event(event) {
    if (!this.sessionID || event.data?.sessionID !== this.sessionID) return;
    if (event.type === "session.text.delta") {
      const id = event.data.assistantMessageID;
      this.pending.set(id, ((this.pending.get(id) || "") + event.data.delta).slice(-60000));
      // Batch token bursts, not whole-history polling or per-token QML layouts.
      this.flushTimer ??= setTimeout(() => this.flush(), 50);
    } else if (event.type === "permission.asked") {
      if (this.autoApproveTools)
        for (const request of await this.client.permission.list({ sessionID: this.sessionID }))
          await this.client.permission.reply({ sessionID: this.sessionID, requestID: request.id, decision: "once" });
      this.emit({ type: "permissions", items: await this.client.permission.list({ sessionID: this.sessionID }) });
    } else if (["session.execution.succeeded", "session.execution.interrupted", "session.execution.failed", "session.idle", "form.created", "form.replied", "form.cancelled"].includes(event.type)) {
      await this.snapshot();
      if (["session.execution.succeeded", "session.execution.interrupted", "session.execution.failed", "session.idle"].includes(event.type)) this.emit({ type: "busy", value: false });
      if (event.type === "session.execution.failed") this.emit({ type: "error", message: event.data.error?.message || "OpenCode could not complete the response." });
    }
  }
}
