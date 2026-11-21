#!/bin/bash
# Set the MBPrep mark on the community and every group linked to it. Paced; log /tmp/mbp-logos.log
C=120363431832773954@g.us
cd /opt/evolution && sudo docker compose cp /tmp/mbp-logo.jpg evolution:/tmp/mbp-logo.jpg >/dev/null
jids=$( (echo $C; /tmp/mbp.sh "{\"op\":\"communityFetchLinkedGroups\",\"args\":[\"$C\"]}" | python3 -c 'import sys,json; [print(g["id"]) for g in json.load(sys.stdin)["out"]["linkedGroups"]]') )
for j in $jids; do
  grep -q "^ok $j$" /tmp/mbp-logos.log 2>/dev/null && continue
  r=$(/tmp/mbp.sh "{\"op\":\"updateProfilePicture\",\"args\":[\"$j\",{\"url\":\"/tmp/mbp-logo.jpg\"}]}")
  case "$r" in *'"ok":true'*) echo "ok $j" >> /tmp/mbp-logos.log;; *) echo "err $j $r" >> /tmp/mbp-logos.log;; esac
  sleep ${GAP:-8}
done
