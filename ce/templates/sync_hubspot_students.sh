#!/usr/bin/env bash
set -euo pipefail

COURSE=""
PIPELINE_ID=""
STAGE_ID=""
COURSE_PROP=""
DEALNAME_CONTAINS=""

while [[ $# -gt 0 ]]; do
  case "$1" in
    --course) COURSE="$2"; shift 2 ;;
    --pipeline) PIPELINE_ID="$2"; shift 2 ;;
    --stage) STAGE_ID="$2"; shift 2 ;;
    --course-prop) COURSE_PROP="$2"; shift 2 ;;
    --dealname-contains) DEALNAME_CONTAINS="$2"; shift 2 ;;
    *) echo "Unknown arg: $1" >&2; exit 1 ;;
  esac
done

if [[ -z "${HUBSPOT_PRIVATE_APP_TOKEN:-}" ]]; then
  echo "Missing HUBSPOT_PRIVATE_APP_TOKEN" >&2
  exit 1
fi
if [[ -z "$COURSE" || -z "$PIPELINE_ID" || -z "$STAGE_ID" ]]; then
  echo "Required: --course, --pipeline, --stage" >&2
  exit 1
fi

COURSE_DIR="$HOME/.openclaw/workspace/ce/courses/$COURSE"
STUDENTS_DIR="$COURSE_DIR/students"
mkdir -p "$STUDENTS_DIR"

# Build filters JSON with python (no heredocs, no unicode issues)
FILTERS_JSON=$(python3 - <<PY
import json
payload = {
  "filterGroups": [{
    "filters": [
      {"propertyName":"pipeline","operator":"EQ","value":"$PIPELINE_ID"},
      {"propertyName":"dealstage","operator":"EQ","value":"$STAGE_ID"},
    ]
  }],
  "properties": ["dealname","dealstage","pipeline","createdate","hs_lastmodifieddate"],
  "limit": 100
}

if "$COURSE_PROP":
  payload["filterGroups"][0]["filters"].append(
    {"propertyName":"$COURSE_PROP","operator":"EQ","value":"$COURSE"}
  )

if "$DEALNAME_CONTAINS":
  payload["filterGroups"][0]["filters"].append(
    {"propertyName":"dealname","operator":"CONTAINS_TOKEN","value":"$DEALNAME_CONTAINS"}
  )

print(json.dumps(payload))
PY
)

echo "Searching deals: pipeline=$PIPELINE_ID stage=$STAGE_ID course=$COURSE" >&2

TMP_BODY="$(mktemp)"
HTTP_CODE=$(curl -sS -o "$TMP_BODY" -w "%{http_code}" \
  "https://api.hubapi.com/crm/v3/objects/deals/search" \
  -H "Authorization: Bearer $HUBSPOT_PRIVATE_APP_TOKEN" \
  -H "Content-Type: application/json" \
  -d "$FILTERS_JSON")

DEALS_JSON="$(cat "$TMP_BODY")"
rm -f "$TMP_BODY"

if [[ "$HTTP_CODE" != "200" ]]; then
  echo "HubSpot search failed (HTTP $HTTP_CODE): $DEALS_JSON" >&2
  exit 1
fi

# Extract deal IDs from env var (no stdin parsing)
DEAL_IDS=$(DEALS_JSON="$DEALS_JSON" python3 - <<'PY'
import os, json
data = json.loads(os.environ["DEALS_JSON"])
for r in data.get("results", []):
    if r.get("id"):
        print(r["id"])
PY
)

if [[ -z "$DEAL_IDS" ]]; then
  echo "No deals found for current filters." >&2
  exit 0
fi

CREATED=0
SKIPPED=0

for DEAL_ID in $DEAL_IDS; do
  TMP_ASSOC="$(mktemp)"
  ASSOC_CODE=$(curl -sS -o "$TMP_ASSOC" -w "%{http_code}" \
    "https://api.hubapi.com/crm/v4/objects/deals/$DEAL_ID/associations/contacts?limit=100" \
    -H "Authorization: Bearer $HUBSPOT_PRIVATE_APP_TOKEN")

  ASSOC_JSON="$(cat "$TMP_ASSOC")"
  rm -f "$TMP_ASSOC"

  if [[ "$ASSOC_CODE" != "200" ]]; then
    echo "Association lookup failed for deal $DEAL_ID (HTTP $ASSOC_CODE)." >&2
    FOLDER="$STUDENTS_DIR/HS_DEAL_$DEAL_ID"
    if [[ -d "$FOLDER" ]]; then
      ((SKIPPED++)); continue
    fi
    mkdir -p "$FOLDER"
    cat > "$FOLDER/hubspot.json" <<EOF2
{
  "course_session": "$COURSE",
  "deal_id": "$DEAL_ID",
  "contact_id": null,
  "note": "Association lookup failed (HTTP $ASSOC_CODE)",
  "created_by": "sync_hubspot_students.sh"
}
EOF2
    ((CREATED++))
    continue
  fi

  CONTACT_IDS=$(ASSOC_JSON="$ASSOC_JSON" python3 - <<'PY'
import os, json
data = json.loads(os.environ["ASSOC_JSON"])
for r in data.get("results", []):
    cid = r.get("toObjectId")
    if cid is not None:
        print(cid)
PY
)

  if [[ -z "$CONTACT_IDS" ]]; then
    FOLDER="$STUDENTS_DIR/HS_DEAL_$DEAL_ID"
    if [[ -d "$FOLDER" ]]; then
      ((SKIPPED++)); continue
    fi
    mkdir -p "$FOLDER"
    cat > "$FOLDER/hubspot.json" <<EOF2
{
  "course_session": "$COURSE",
  "deal_id": "$DEAL_ID",
  "contact_id": null,
  "note": "No associated contact found in HubSpot",
  "created_by": "sync_hubspot_students.sh"
}
EOF2
    ((CREATED++))
    continue
  fi

  for CONTACT_ID in $CONTACT_IDS; do
    FOLDER="$STUDENTS_DIR/HS_$CONTACT_ID"
    if [[ -d "$FOLDER" ]]; then
      ((SKIPPED++)); continue
    fi
    mkdir -p "$FOLDER"
    cat > "$FOLDER/hubspot.json" <<EOF2
{
  "course_session": "$COURSE",
  "deal_id": "$DEAL_ID",
  "contact_id": "$CONTACT_ID",
  "created_by": "sync_hubspot_students.sh"
}
EOF2
    ((CREATED++))
  done
done

echo "Done. Created: $CREATED | Skipped(existing): $SKIPPED" >&2
echo "Students folder: $STUDENTS_DIR" >&2
