#!/bin/bash
# Give each school group its own picture: the MBPrep mark with the school as a badge. Paced; idempotent via /tmp/mbp-school-logos.log
cd /opt/evolution
sudo docker compose exec -T evolution mkdir -p /tmp/avatars </dev/null
for f in /tmp/avatars/out/*.jpg; do sudo docker compose cp "$f" evolution:/tmp/avatars/ >/dev/null; done
python3 - <<'PY' > /tmp/school-jids.tsv
import json, re
slug = {l.split("|")[0]: l.split("|")[1] for l in open("/tmp/avatars/plan.psv")}
for l in open("/tmp/mbp-schools.jsonl"):
    d = json.loads(l)
    if d.get("jid"): print(d["jid"] + "|" + slug[d["school"]])
PY
while IFS='|' read -r jid slug; do
  grep -q "^ok $jid$" /tmp/mbp-school-logos.log 2>/dev/null && continue
  r=$(/tmp/mbp.sh "{\"op\":\"updateProfilePicture\",\"args\":[\"$jid\",{\"url\":\"/tmp/avatars/$slug.jpg\"}]}")
  case "$r" in *'"ok":true'*) echo "ok $jid" >> /tmp/mbp-school-logos.log;; *) echo "err $jid $slug $r" >> /tmp/mbp-school-logos.log;; esac
  sleep ${GAP:-8}
done < /tmp/school-jids.tsv
