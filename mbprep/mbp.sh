#!/bin/bash
# usage: mbp.sh '<json body without number>'  — runs one bridge call inside the evolution container
cd /opt/evolution
K=$(sudo docker compose exec -T evolution printenv AUTHENTICATION_API_KEY </dev/null)
B=$(printf '%s' "$1" | python3 -c 'import sys,json; b=json.load(sys.stdin); b["number"]="2348026594604"; print(json.dumps(b))')
sudo docker compose exec -T -e K="$K" -e B="$B" evolution node -e 'fetch("http://127.0.0.1:8099",{method:"POST",headers:{apikey:process.env.K},body:process.env.B}).then(r=>r.text()).then(t=>console.log(t))' </dev/null
