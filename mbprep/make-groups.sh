#!/bin/bash
# Make one MBPrep school group per school inside the community, paced, idempotent. Log: /tmp/mbp-schools.jsonl
C=120363431832773954@g.us
LOG=/tmp/mbp-schools.jsonl
FIRST=${FIRST:-0}; LAST=${LAST:-999}; GAP=${GAP:-45}
have=$(/tmp/mbp.sh "{\"op\":\"communityFetchLinkedGroups\",\"args\":[\"$C\"]}")
i=0
python3 -c 'import json;[print(n) for n in json.load(open("/tmp/schools.json"))]' | while IFS= read -r school; do
  i=$((i+1)); [ $i -lt $FIRST ] && continue; [ $i -gt $LAST ] && break
  subj="MBPrep · $school"
  if printf '%s' "$have" | python3 -c 'import sys,json; s=sys.argv[1]; d=json.load(sys.stdin)["out"]["linkedGroups"]; sys.exit(0 if any(g["subject"]==s for g in d) else 1)' "$subj"; then echo "{\"school\":\"$school\",\"skip\":\"exists\"}" >> $LOG; continue; fi
  body=$(python3 -c 'import json,sys; print(json.dumps({"op":"communityCreateGroup","args":[sys.argv[1],[],sys.argv[2]]}))' "$subj" "$C")
  r=$(/tmp/mbp.sh "$body")
  jid=$(printf '%s' "$r" | python3 -c 'import sys,json; print((json.load(sys.stdin).get("out") or {}).get("id",""))' 2>/dev/null)
  if [ -z "$jid" ]; then echo "{\"school\":\"$school\",\"error\":$(printf '%s' "$r" | python3 -c 'import sys,json; print(json.dumps(sys.stdin.read()[:300]))')}" >> $LOG; sleep $GAP; continue; fi
  sleep 3
  desc="For $school students on MBPrep: ask your classmates, share what is coming up in your postings and exams, and hear when your school's questions and notes land. News for everyone comes in Announcements. mbprep.app"
  /tmp/mbp.sh "$(python3 -c 'import json,sys; print(json.dumps({"op":"groupUpdateDescription","args":[sys.argv[1],sys.argv[2]]}))' "$jid" "$desc")" >/dev/null; sleep 2
  /tmp/mbp.sh "{\"op\":\"groupJoinApprovalMode\",\"args\":[\"$jid\",\"off\"]}" >/dev/null; sleep 2
  /tmp/mbp.sh "{\"op\":\"groupSettingUpdate\",\"args\":[\"$jid\",\"locked\"]}" >/dev/null; sleep 2
  code=$(/tmp/mbp.sh "{\"op\":\"groupInviteCode\",\"args\":[\"$jid\"]}" | python3 -c 'import sys,json; print(json.load(sys.stdin).get("out") or "")')
  python3 -c 'import json,sys; print(json.dumps({"school":sys.argv[1],"jid":sys.argv[2],"invite":("https://chat.whatsapp.com/"+sys.argv[3]) if sys.argv[3] else None}))' "$school" "$jid" "$code" >> $LOG
  sleep $GAP
done
echo '{"done":true}' >> $LOG
