# Evolution v2.3.7 with two Baileys fixes (2026-11-05). First: group-participant stub parameters are sometimes a bare JID
# ("123456789012345@lid"), not JSON. Baileys 7.0.0-rc.9 JSON.parses them unguarded, the throw aborts
# "processing offline nodes", the notification is never acked, and every message queued behind it is never
# saved (4 Nov 2026 14:55 UTC onwards). Upstream master still parses unguarded, so the patch stays until it doesn't.
FROM evoapicloud/evolution-api:v2.3.7
RUN node -e ' \
  const fs = require("fs"); \
  const p = "/evolution/node_modules/baileys/lib/Utils/process-message.js"; \
  const from = "messageStubParameters.map((a) => JSON.parse(a))"; \
  const to = "messageStubParameters.map((a) => { try { return JSON.parse(a); } catch { return { id: a, phoneNumber: String(a).endsWith(\"@s.whatsapp.net\") ? a : undefined, lid: String(a).endsWith(\"@lid\") ? a : undefined }; } })"; \
  const s = fs.readFileSync(p, "utf8"); const n = s.split(from).length - 1; \
  if (n !== 5) { console.error("stub patch: expected 5 sites, found " + n); process.exit(1); } \
  fs.writeFileSync(p, s.split(from).join(to)); console.log("stub patch: " + n + " sites"); \
'
# Second fix (2026-11-05): WhatsApp now delivers status@broadcast updates as <status> stanzas. Baileys 7.0.0-rc.9 (and
# upstream master) registers no handler for them, so they are never acked; the offline queue stalls behind them and
# the server drops the stream every ~50 min with stream:error <ack class="status">. Ack them (class "status", as
# sendMessageAck builds it). Not decrypted or read: no status is marked seen.
RUN node -e ' \
  const fs = require("fs"); \
  const p = "/evolution/node_modules/baileys/lib/Socket/messages-recv.js"; \
  const at = "    ws.on(\x27CB:ack,class:message\x27, (node) => {"; \
  const add = "    ws.on(\x27CB:status\x27, async (node) => {\n        await sendMessageAck(node).catch(error => onUnexpectedError(error, \x27acking status\x27));\n    });\n"; \
  const s = fs.readFileSync(p, "utf8"); const n = s.split(at).length - 1; \
  if (n !== 1) { console.error("status patch: expected 1 site, found " + n); process.exit(1); } \
  if (s.includes("CB:status")) { console.error("status patch: CB:status already handled upstream, drop this patch"); process.exit(1); } \
  fs.writeFileSync(p, s.replace(at, add + at)); console.log("status patch: applied"); \
'
# Third (2026-11-17, HAL-6084): communities and channels. Evolution v2.3.7 has no route for them; Baileys does. A
# loopback-only bridge (mbp-admin.js, 127.0.0.1:8099 inside the container, not published) calls a fixed list of
# Baileys community, group-invite and channel functions on the live socket, behind Evolution's apikey and the socket's
# own number. Call it with `docker compose exec evolution` (see servers/comms/README.md).
COPY mbp-admin.js /evolution/node_modules/baileys/lib/Socket/mbp-admin.js
RUN node -e ' \
  const fs = require("fs"); \
  const p = "/evolution/node_modules/baileys/lib/Socket/index.js"; \
  const at = "    return makeCommunitiesSocket(newConfig);"; \
  const s = fs.readFileSync(p, "utf8"); const n = s.split(at).length - 1; \
  if (n !== 1) { console.error("bridge patch: expected 1 site, found " + n); process.exit(1); } \
  fs.writeFileSync(p, "import { track as mbpTrack } from \x27./mbp-admin.js\x27;\n" + s.replace(at, "    return mbpTrack(makeCommunitiesSocket(newConfig));")); \
  console.log("bridge patch: applied"); \
'
