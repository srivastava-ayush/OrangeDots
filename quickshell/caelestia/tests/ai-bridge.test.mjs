import test from "node:test";
import assert from "node:assert/strict";
import { createServer } from "node:http";
import { mkdtemp, writeFile, rm } from "node:fs/promises";
import { tmpdir } from "node:os";
import path from "node:path";
import { SidebarBridge } from "../utils/opencode/bridge-core.mjs";
import { ChatAdapter, OllamaAdapter, ClaudeAdapter, localOllamaUrl } from "../utils/opencode/providers.mjs";
import { CodexAdapter } from "../utils/opencode/codex.mjs";

test("OpenCode creates only a dedicated, approval-protected session on Send", async () => {
  const events = [], calls = [];
  const client = {
    session: {
      create: async input => { calls.push(input); return { id: "ses_fixture" }; },
      prompt: async input => calls.push(input),
      active: async () => ({}),
      get: async () => ({ id: "ses_other", metadata: {} }),
      form: { list: async () => [] },
    },
    message: { list: async () => ({ data: [{ id: "assistant", type: "assistant", content: [{ type: "text", text: "Answer" }] }, { id: "user", type: "user", text: "Question" }] }) },
    permission: { list: async () => [], reply: async input => calls.push(input) },
  };
  const bridge = new SidebarBridge(client, event => events.push(event));
  await bridge.command({ type: "init", directory: "/tmp", model: "test/model#fast" });
  assert.equal(calls.length, 0);
  await bridge.command({ type: "send", text: "Question" });
  assert.deepEqual(calls[0].permissions, [{ action: "*", resource: "*", effect: "ask" }]);
  assert.deepEqual(calls[0].model, { providerID: "test", id: "model", variant: "fast" });
  assert.equal(events.find(event => event.type === "snapshot").rows[0].role, "user");
  await bridge.event({ type: "session.text.delta", data: { sessionID: "ses_unrelated", assistantMessageID: "x", delta: "private" } });
  await bridge.event({ type: "session.text.delta", data: { sessionID: "ses_fixture", assistantMessageID: "a", delta: "hello " } });
  await bridge.event({ type: "session.text.delta", data: { sessionID: "ses_fixture", assistantMessageID: "a", delta: "world" } });
  bridge.flush();
  assert.deepEqual(events.filter(event => event.type === "delta"), [{ type: "delta", id: "a", text: "hello world" }]);
  await assert.rejects(bridge.command({ type: "permission", id: "p", decision: "always" }));
  await bridge.command({ type: "permission", id: "p", decision: "once" });
  assert.equal(calls.at(-1).decision, "once");
  await assert.rejects(bridge.command({ type: "init", directory: "/tmp", sessionID: "ses_other" }), /not an AI-sidebar session/);
});

test("OpenCode auto-approval is session-local and can be disabled", async () => {
  const policies = [], replies = [];
  const client = {
    session: {
      create: async input => { policies.push(input.permissions); return { id: "sidebar" }; },
      update: async input => { assert.equal(input.sessionID, "sidebar"); policies.push(input.permissions); },
      prompt: async () => {}, active: async () => ({}), form: { list: async () => [] },
    },
    message: { list: async () => ({ data: [] }) },
    permission: { list: async () => [{ id: "approval" }], reply: async input => replies.push(input) },
  };
  const bridge = new SidebarBridge(client, () => {});
  await bridge.command({ type: "init", directory: "/tmp", autoApproveTools: true });
  await bridge.command({ type: "send", text: "Fixture" });
  assert.equal(policies[0][0].effect, "allow");
  await bridge.event({ type: "permission.asked", data: { sessionID: "sidebar" } });
  assert.equal(replies[0].decision, "once");
  await bridge.command({ type: "approval-policy", autoApproveTools: false });
  assert.equal(policies.at(-1)[0].effect, "ask");
});

test("New chat waits for cancellation before acknowledging reset", async () => {
  const events = [];
  class Fixture extends ChatAdapter {
    run() { return new Promise(resolve => { this.finish = resolve; }); }
    stop() { this.stopped = true; this.finish(); }
  }
  const adapter = new Fixture(event => events.push(event));
  await adapter.command({ type: "init", directory: "/tmp" });
  await adapter.command({ type: "send", text: "Fixture" });
  assert.equal(adapter.busy, true);
  await adapter.command({ type: "reset" });
  assert.equal(adapter.stopped, true);
  assert.equal(adapter.busy, false);
  assert.equal(events.at(-1).type, "reset-ready");
});

test("OpenCode effort switches only the sidebar model variant and can reset to default", async () => {
  const switches = [];
  const client = {
    session: {
      get: async () => ({ id: "sidebar", metadata: { orangeshellSidebar: true }, location: { directory: "/tmp" }, model: { providerID: "fixture", id: "model" } }),
      switchModel: async input => switches.push(input),
      update: async () => {},
      prompt: async () => {}, active: async () => ({}), form: { list: async () => [] },
      interrupt: async input => switches.push({ interrupted: input.sessionID }),
    },
    message: { list: async () => ({ data: [] }) },
    permission: { list: async () => [] },
  };
  const bridge = new SidebarBridge(client, () => {});
  await bridge.command({ type: "init", directory: "/tmp", sessionID: "sidebar" });
  await bridge.command({ type: "send", text: "Fixture", effort: "high" });
  await bridge.command({ type: "send", text: "Fixture", effort: "" });
  assert.deepEqual(switches.map(input => input.model), [
    { providerID: "fixture", id: "model", variant: "high" },
    { providerID: "fixture", id: "model" },
  ]);
  client.message.list = async () => { throw new Error("Old project is unavailable"); };
  await bridge.command({ type: "reset" });
  assert.deepEqual(switches.at(-1), { interrupted: "sidebar" });
});

test("Ollama stays on loopback, streams UTF-8, retains context and unloads the model", async () => {
  for (const url of ["https://example.com", "http://example.com", "http://user:secret@localhost", "http://localhost/path"])
    assert.throws(() => localOllamaUrl(url));
  const events = [];
  let request;
  const server = createServer(async (req, res) => {
    let body = "";
    for await (const chunk of req) body += chunk;
    request = JSON.parse(body);
    res.writeHead(200, { "Content-Type": "application/x-ndjson" });
    res.write(JSON.stringify({ message: { content: "Hello " } }) + "\n");
    res.end(JSON.stringify({ message: { content: "🌙" }, done: true }));
  });
  await new Promise(resolve => server.listen(0, "127.0.0.1", resolve));
  try {
    const adapter = new OllamaAdapter(event => events.push(event));
    await adapter.command({ type: "init", directory: "/tmp", model: "fixture", ollamaUrl: `http://127.0.0.1:${server.address().port}`, history: [{ id: "old", role: "assistant", text: "Prior context" }] });
    await adapter.command({ type: "send", text: "Hi", effort: "low" });
    await adapter.job;
    assert.equal(request.keep_alive, 0);
    assert.equal(request.think, "low");
    assert.equal(request.tools, undefined);
    assert.equal(request.messages[0].content, "Prior context");
    assert.equal(adapter.rows.at(-1).text, "Hello 🌙");
    assert.equal(events.at(-1).busy, false);
  } finally { server.closeAllConnections(); await new Promise(resolve => server.close(resolve)); }
});

// Fake CLIs: no installed account, real model, command execution or billing.
const claudeFixture = `#!/usr/bin/env node
const args=process.argv.slice(2);
if(args[args.indexOf('--tools')+1]!=='' || !args.includes('--strict-mcp-config') || args.includes('--dangerously-skip-permissions')) process.exit(4);
if(args[args.indexOf('--effort')+1]!=='high') process.exit(6);
process.stdin.resume(); process.stdin.on('end',()=>{
 console.log(JSON.stringify({type:'system',session_id:'claude-fixture'}));
 console.log(JSON.stringify({type:'stream_event',event:{delta:{type:'text_delta',text:'Hello Claude'}}}));
 console.log(JSON.stringify({type:'result',result:'Hello Claude',is_error:false}));
});`;
const codexFixture = `#!/usr/bin/env node
const readline=require('node:readline');
const send=m=>console.log(JSON.stringify(m));
readline.createInterface({input:process.stdin}).on('line',line=>{
 const m=JSON.parse(line);
 if(m.method==='initialize')send({id:m.id,result:{}});
 if(m.method==='thread/start'){
  if(m.params.sandbox!=='read-only'||m.params.approvalPolicy!=='untrusted') process.exit(5);
  send({id:m.id,result:{thread:{id:'codex-fixture'}}});
 }
 if(m.method==='turn/start'){
  if(m.params.effort!=='high') process.exit(6);
  send({id:m.id,result:{turn:{id:'turn-fixture'}}});
  send({id:88,method:'item/commandExecution/requestApproval',params:{threadId:'codex-fixture',command:'fixture-only'}});
 }
 if(m.id===88 && m.result?.decision==='accept'){
  send({method:'item/agentMessage/delta',params:{threadId:'codex-fixture',delta:'Hello Codex'}});
  send({method:'turn/completed',params:{threadId:'codex-fixture',turn:{status:'completed'}}});
 }
});`;

test("Claude and Codex adapters use safe CLI policies and explicit approvals", async () => {
  const directory = await mkdtemp(path.join(process.env.TMPDIR || "/tmp/opencode", "ai-cli-fixture-"));
  const previousPath = process.env.PATH;
  try {
    await writeFile(path.join(directory, "claude"), claudeFixture, { mode: 0o700 });
    await writeFile(path.join(directory, "codex"), codexFixture, { mode: 0o700 });
    process.env.PATH = `${directory}:${previousPath}`;
    const claude = new ClaudeAdapter(() => {});
    await claude.command({ type: "init", directory });
    await claude.command({ type: "send", text: "Fixture", effort: "high" });
    await claude.job;
    assert.equal(claude.sessionID, "claude-fixture");
    assert.equal(claude.rows.at(-1).text, "Hello Claude");
    const errors = [];
    const codex = new CodexAdapter(event => {
      if (event.type === "error") errors.push(event.message);
      if (event.type === "permissions" && event.items.length) codex.command({ type: "permission", id: event.items[0].id, decision: "once" });
    });
    try {
      await codex.command({ type: "init", directory });
      await codex.command({ type: "send", text: "Fixture", effort: "high" });
      await codex.job;
      assert.equal(codex.sessionID, "codex-fixture");
      assert.equal(codex.rows.at(-1).text, "Hello Codex");
      assert.deepEqual(errors, []);
    } finally { codex.close(); }
  } finally {
    process.env.PATH = previousPath;
    await rm(directory, { recursive: true, force: true });
  }
});
