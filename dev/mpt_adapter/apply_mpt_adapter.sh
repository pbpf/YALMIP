#!/bin/bash
# Apply the YALMIP-session adapter to an MPT3 installation tree.
#
# Usage: apply_mpt_adapter.sh [MPT_ROOT]     (default /opt/mpt3)
#
# What it does:
#   1. Copies mpt_yalmip_sdpvar.m into the MPT3 root (next to mpt_init.m).
#   2. Rewrites every live bare `sdpvar(` call in the MPT3 UI classes and
#      solver helpers to `mpt_yalmip_sdpvar(`. Comment lines are skipped,
#      already-patched lines are skipped (the script is idempotent).
#
# The patch list covers every sdpvar call site under modules/ui and
# modules/solvers - the only MPT3 code paths that touch YALMIP variables.
# Verify after applying:
#   grep -rn "mpt_yalmip_sdpvar(" <MPT_ROOT>/modules | wc -l   # expected: 22
set -euo pipefail

MPT_ROOT="${1:-/opt/mpt3}"
HERE="$(cd "$(dirname "$0")" && pwd)"

if [ ! -f "$MPT_ROOT/mpt_init.m" ]; then
    echo "ERROR: $MPT_ROOT does not look like an MPT3 tree (no mpt_init.m)" >&2
    exit 1
fi

cp "$HERE/mpt_yalmip_sdpvar.m" "$MPT_ROOT/mpt_yalmip_sdpvar.m"
echo "installed $MPT_ROOT/mpt_yalmip_sdpvar.m"

total=0
for f in \
    "$MPT_ROOT"/modules/ui/@SystemSignal/SystemSignal.m \
    "$MPT_ROOT"/modules/ui/@SystemSignal/filter_reference.m \
    "$MPT_ROOT"/modules/ui/@SystemSignal/filter_softMax.m \
    "$MPT_ROOT"/modules/ui/@SystemSignal/filter_softMin.m \
    "$MPT_ROOT"/modules/ui/@SystemSignal/filter_previous.m \
    "$MPT_ROOT"/modules/ui/@SystemSignal/filter_PWApenalty.m \
    "$MPT_ROOT"/modules/ui/@PWASystem/PWASystem.m \
    "$MPT_ROOT"/modules/ui/@ULTISystem/ULTISystem.m \
    "$MPT_ROOT"/modules/solvers/mpt_solve.m \
    "$MPT_ROOT"/modules/solvers/mpt_enum_plcp.m
do
    n=$(grep -c "mpt_yalmip_sdpvar(" "$f" || true)
    sed -i '/^[[:space:]]*%/!{/mpt_yalmip_sdpvar/!s/\bsdpvar(/mpt_yalmip_sdpvar(/g}' "$f"
    after=$(grep -c "mpt_yalmip_sdpvar(" "$f" || true)
    total=$((total + after))
    printf '%-70s patched lines: %d (was %d)\n' "${f#$MPT_ROOT/}" "$after" "$n"
done

echo "total patched call sites: $total (expected 22)"
echo "remaining bare sdpvar( in live code:"
grep -rn "sdpvar(" "$MPT_ROOT"/modules/ui "$MPT_ROOT"/modules/solvers 2>/dev/null \
    | grep -v "mpt_yalmip_sdpvar(" | grep -v "^[^:]*:[0-9]*:[[:space:]]*%" || echo "  none"
