# MBPrep bridge: communities and channels through Evolution

Added 17 Nov 2026 (HAL-6084). Evolution v2.3.7 has REST routes for plain groups only. Baileys 7.0.0-rc.9 under it can
also make communities, make groups inside a community, link existing groups, read invite codes and make channels.
`mbp-admin.js` is copied into the image, and the third `RUN` in the `Dockerfile` makes Baileys' `makeWASocket` hand
every socket to it.

- It listens on `127.0.0.1:8099` **inside the container only**. The port is not published; reach it with
  `docker compose exec evolution`.
- It needs Evolution's own `AUTHENTICATION_API_KEY` as the `apikey` header. It also needs a `number` equal to the
  socket's own number, so it can never act as another account.
- It calls only the Baileys functions listed in `OPS`. Nothing in that list sends a message.

## Calling it

`/tmp/mbp.sh` on the box (copy kept in this folder's history) takes a JSON body without the number:

    /tmp/mbp.sh '{"op":"communityFetchLinkedGroups","args":["120363431832773954@g.us"]}'

## What was made with it (17 Nov 2026, the founder's yes)

- Community **MBPrep** `120363431832773954@g.us`: join approval off, members cannot make groups. Its own groups are
  Announcements (`120363414798197813@g.us`, shown as "MBPrep") and General (`120363430594942752@g.us`).
- The existing **MBPrep** group (`120363431357073701@g.us`, 58 people) linked into it.
- One group per school, `MBPrep · <school>` (76 schools from production's `exam_ops`, boards left out). Each has no
  join approval, only admins can edit its info, and its own invite link. The log is `/tmp/mbp-schools.jsonl` on the box.

## Channels

`newsletterCreate` came back empty on 17 Nov. The account has to accept WhatsApp's channel terms in the app first,
and Baileys cannot accept them. Make the channel in the app; after that, `newsletterUpdateDescription` and
`newsletterUpdatePicture` work through the bridge.

## Ban safety

The number is the founder's own. Pace any batch of creates at least 45 s apart, and never send messages through it.
