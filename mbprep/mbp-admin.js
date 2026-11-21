// MBPrep admin bridge (17 Nov 2026): Evolution v2.3.7 exposes plain groups only, but Baileys 7.0.0-rc.9 can make
// communities, link groups into them and make channels. This loopback-only endpoint (127.0.0.1:8099 inside the
// container, never published) calls a fixed list of those Baileys functions on the live socket. It needs the same
// apikey as Evolution's own API and a `number` that must match the socket's own number, so it can never act as a
// different account. Nothing here sends a message.
import http from "node:http";

const OPS = new Set([
  "communityCreate",
  "communityCreateGroup",
  "communityLinkGroup",
  "communityInviteCode",
  "communityMetadata",
  "communityFetchAllParticipating",
  "communityUpdateDescription",
  "communitySettingUpdate",
  "communityJoinApprovalMode",
  "communityMemberAddMode",
  "communityFetchLinkedGroups",
  "communityUpdateSubject",
  "groupFetchAllParticipating",
  "groupMetadata",
  "groupInviteCode",
  "groupUpdateDescription",
  "groupJoinApprovalMode",
  "groupSettingUpdate",
  "groupMemberAddMode",
  "newsletterCreate",
  "newsletterMetadata",
  "newsletterUpdateDescription",
  "newsletterUpdatePicture",
  "updateProfilePicture",
]);

const socks = [];
let started = false;

const numberOf = (s) => String(s?.user?.id || "").split(/[:@]/)[0];

export function track(sock) {
  socks.push(sock);
  if (socks.length > 20) socks.shift();
  start();
  return sock;
}

function start() {
  if (started) return;
  started = true;
  const key = process.env.AUTHENTICATION_API_KEY;
  const server = http.createServer(async (req, res) => {
    const send = (code, body) => {
      res.writeHead(code, { "content-type": "application/json" });
      res.end(JSON.stringify(body));
    };
    if (!key || req.headers.apikey !== key) return send(401, { error: "apikey" });
    if (req.method !== "POST") return send(405, { error: "POST only" });
    let raw = "";
    for await (const chunk of req) {
      raw += chunk;
      if (raw.length > 100000) return send(413, { error: "too large" });
    }
    let body;
    try {
      body = JSON.parse(raw);
    } catch {
      return send(400, { error: "json" });
    }
    const { op, args = [], number } = body || {};
    if (!OPS.has(op)) return send(400, { error: `op not allowed: ${op}` });
    if (!Array.isArray(args)) return send(400, { error: "args must be an array" });
    const sock = [...socks].reverse().find((s) => number && numberOf(s) === String(number) && s.ws?.isOpen !== false);
    if (!sock) return send(503, { error: "no open socket for that number" });
    try {
      const out = await sock[op](...args);
      send(200, { ok: true, out: out ?? null });
    } catch (e) {
      send(500, { error: String(e?.message || e), data: e?.data ?? null });
    }
  });
  server.on("error", (e) => console.error("mbp-admin bridge:", e?.message || e));
  server.listen(8099, "127.0.0.1");
}
