#!/usr/bin/env bash
# availability_check.sh
# Non-destructive demo script to show fault-isolation/availability difference
# between monolith (main) and microservices (tfu5).
# It will NOT edit existing project files. It will:
#  - git checkout the requested branch (ensure working tree is clean)
#  - bring up docker compose
#  - run a set of curl checks before/after stopping a target service
#  - save a short report in demos/results/

set -euo pipefail
ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
RESULTS_DIR="$ROOT_DIR/demos/results"
mkdir -p "$RESULTS_DIR"

usage(){
  cat <<EOF
Usage: $0 <branch> <target_service>

Examples:
  # Monolith: stop the api to see global outage
  $0 main api

  # Microservices: stop the productos service and observe partial availability
  $0 tfu5 productos

Notes:
- Make sure you have Docker and docker compose installed.
- The script will run `git checkout` so ensure your working tree is clean or stash changes.
- The script will NOT modify project source files.
EOF
}

if [ "${1:-}" = "" ] || [ "${2:-}" = "" ]; then
  usage
  exit 1
fi

BRANCH="$1"
TARGET="$2"
TS=$(date -u +%Y%m%dT%H%M%SZ)
OUT="$RESULTS_DIR/availability-${BRANCH}-${TARGET}-$TS.txt"

echo "Running availability check for branch '$BRANCH' by stopping service '$TARGET'"

echo "Ensure working tree is clean before continuing. If not, press Ctrl+C now."
sleep 2

# checkout branch
git checkout "$BRANCH"

# start compose
echo "Bringing up docker compose for branch $BRANCH..."
docker compose up --build -d

# wait for gateway (or api) to be reachable
wait_for() {
  local url="$1"
  local tries=0
  until curl -sS "$url" >/dev/null 2>&1; do
    tries=$((tries+1))
    if [ $tries -ge 30 ]; then
      echo "Timeout waiting for $url" >&2
      return 1
    fi
    sleep 2
  done
  return 0
}

# determine gateway url based on branch
GATEWAY_URL="http://localhost:8000"
PRODUCTOS_URL="http://localhost:8001"
RECETAS_URL="http://localhost:8002"
LISTAS_URL="http://localhost:8003"

# Wait for gateway (or api root) to be ready
echo "Waiting for gateway/api to be ready at $GATEWAY_URL..."
if ! wait_for "$GATEWAY_URL/"; then
  echo "Gateway did not become ready in time. Check containers with 'docker compose ps'" | tee "$OUT"
  exit 1
fi

# helper to probe endpoints and record simple status
probe() {
  local label="$1"
  local url="$2"
  local tmp
  tmp=$(mktemp)
  # try up to 3 times (in case of cold starts)
  local i=0
  local code=0
  while [ $i -lt 3 ]; do
    code=$(curl -s -o /dev/null -w "%{http_code}" --max-time 5 "$url" || echo 000)
    if [ "$code" != "000" ]; then
      break
    fi
    i=$((i+1))
    sleep 1
  done
  printf "%s %s %s\n" "$(date -u +%Y-%m-%dT%H:%M:%SZ)" "$label" "$code"
}

# endpoints to check
ENDPOINTS=(
  "gateway_root:$GATEWAY_URL/"
  "productos:$PRODUCTOS_URL/productos/"
  "recetas:$RECETAS_URL/recetas/"
  "listas:$LISTAS_URL/listas/"
)

# Function to run round of probes and append header
run_round() {
  local phase="$1"
  echo "=== $phase ===" | tee -a "$OUT"
  for e in "${ENDPOINTS[@]}"; do
    IFS=":" read -r label url <<< "$e"
    probe "$label" "$url" | tee -a "$OUT"
  done
  echo "" | tee -a "$OUT"
}

# 1) initial probes
echo "Running initial probes..." | tee "$OUT"
run_round "initial"

# 2) stop target service
echo "Stopping service: $TARGET" | tee -a "$OUT"
docker compose stop "$TARGET" || echo "Warning: service $TARGET not found or already stopped" | tee -a "$OUT"

# small wait to let things settle
sleep 3

# 3) probes after stopping target
run_round "after_stop"

# 4) start target back up
echo "Starting service: $TARGET" | tee -a "$OUT"
docker compose start "$TARGET" || echo "Warning: failed to start $TARGET" | tee -a "$OUT"

# wait a bit and final probe
sleep 5
run_round "after_restart"

# 5) summary
cat >> "$OUT" <<EOF
Summary:
- Branch: $BRANCH
- Target stopped: $TARGET
- Timestamp: $TS
EOF

echo "Results saved to $OUT"

echo "Done. You can inspect $OUT for the HTTP status codes observed." 
