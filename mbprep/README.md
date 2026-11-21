# MBPrep's Evolution API

This fork of `evolution-foundation/evolution-api` is where we change Evolution and the Baileys library under it for
our own use. Branch `mbprep/v2.3.7` starts at upstream tag `2.3.7` (Baileys `7.0.0-rc.9`), the version live on the
`comms` VM (GCP `mbprep-selfhosted`, `/opt/evolution`). Moved here from `~/dev/infra/servers/comms/evolution` on
21 Nov 2026.

## What is in this folder

| File | What it does |
|---|---|
| `Dockerfile` | Builds `evolution-api:v2.3.7-stubpatch` from the upstream image with three patches (below). Each patch fails the build loudly if the code it targets has moved. |
| `mbp-admin.js` | The communities and channels bridge: a loopback-only server inside the container (`127.0.0.1:8099`) that calls a fixed list of Baileys functions. See `BRIDGE.md`. |
| `BRIDGE.md` | How to call the bridge, what was made with it, ban-safety rules. |
| `mbp.sh` | Calls the bridge from the box with the API key and the socket's own number. |
| `make-groups.sh` | The paced maker for the `MBPrep · <school>` groups (≥45 s between creates). |
| `avatar.sh`, `set-logos.sh`, `set-school-logos.sh`, `short.json` | Group pictures, and school short names. |

## The patches

1. **Group-stub guard (5 Nov 2026).** Baileys `JSON.parse`d group-participant stub parameters unguarded. A bare
   `…@lid` threw, stopped offline processing, and no message was saved after 4 Nov 14:55 UTC.
2. **Ack `<status>` stanzas (5 Nov 2026).** Baileys had no handler for them, so the offline queue stalled and the
   server dropped the stream every ~50 min. They are acked, never read; no status is marked seen.
3. **Communities and channels bridge (17 Nov 2026, HAL-6084).** Hands every socket to `mbp-admin.js`. Nothing on its
   list sends a message.

## Rules

- Evolution only listens and files MBPrep messages. It never sends; updates to the founder go by Telegram.
- Only the founder's own number. Pace any batch of creates at least 45 s apart.

## Deploying

On the box: copy `Dockerfile` and `mbp-admin.js` to `/opt/evolution`, then `docker compose build evolution &&
docker compose up -d evolution` (reconnects without a QR). The install script is
`~/dev/infra/servers/comms/scripts/05-evolution.sh`.

## Next

The patches edit `node_modules/baileys` inside the image, which is quick but fragile. As we add our own features,
move them into the TypeScript source of this fork (Evolution routes for communities and channels instead of the
loopback bridge) and pin Baileys with `patch-package` or our own Baileys fork. Build the image from this repo.
