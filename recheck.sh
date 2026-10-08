#!/usr/bin/env bash
# Re-check one result family from openai/math from scratch.
#
#   ./recheck.sh <family-number>        # e.g. ./recheck.sh 325
#
# Reads families/<n>/family.env, then:
#   1. sparse-checkouts just that family from openai/math at UPSTREAM_SHA
#   2. refuses to continue if the family imports anything outside Mathlib
#   3. generates a minimal lakefile  (upstream's requires ~30 external repos)
#   4. builds OpenAI's proof, then hands off to ./audit.sh
#
# This repository keeps no copy of OpenAI's files.  They are fetched from
# upstream at a pinned commit, so "are these really their files" is answered
# by a commit SHA rather than by trusting a vendored snapshot.

set -euo pipefail

UPSTREAM_REPO="${UPSTREAM_REPO:-https://github.com/openai/math.git}"
UPSTREAM_SHA="${UPSTREAM_SHA:-adc7f1241b42e322a6451854ab7e4b4c146bf78a}"

REPO_ROOT="$PWD"
FAMILY_NUMBER="${1:-}"
if [ -z "$FAMILY_NUMBER" ]; then sed -n '2,15p' "$0" >&2; exit 64; fi

CONF="$REPO_ROOT/families/$FAMILY_NUMBER/family.env"
[ -f "$CONF" ] || { echo "no config: $CONF" >&2; exit 64; }
# shellcheck source=/dev/null
. "$CONF"
: "${FAMILY_DIR:?family.env must set FAMILY_DIR}"

WORK="${WORK:-$REPO_ROOT/.work/$FAMILY_NUMBER}"
say() { printf '\n==> %s\n' "$*"; }

# ---------------------------------------------------------------- 1. fetch
say "fetching $FAMILY_DIR from openai/math @ ${UPSTREAM_SHA:0:12}"
UP="$WORK/upstream"
if [ ! -d "$UP/.git" ]; then
  mkdir -p "$UP"
  git -C "$UP" init -q
  git -C "$UP" remote add origin "$UPSTREAM_REPO"
  # Windows checkouts otherwise rewrite every line ending and every later
  # hash comparison becomes meaningless.
  git -C "$UP" config core.autocrlf false
  git -C "$UP" config core.eol lf
  git -C "$UP" config core.sparseCheckout true
  # Partial clone. Without this, sparse-checkout still downloads every blob in
  # the commit -- 780 MB to look at 392 KB of Lean. `blob:none` defers blobs
  # until checkout asks for them, and sparse-checkout means it asks for few.
  git -C "$UP" config remote.origin.promisor true
  git -C "$UP" config remote.origin.partialclonefilter blob:none
fi

# lean/docs/<n>.md is fetched on purpose: a family can carry several comparator
# files, and that page is the only place saying which holds the headline
# theorem.  Picking the first file you open is how you misread a family.
cat > "$UP/.git/info/sparse-checkout" <<EOF
/lean/$FAMILY_DIR/
/lean/ComparatorChallenges/
/lean/lean-toolchain
/lean/lake-manifest.json
/lean/docs/
EOF

git -C "$UP" fetch -q --filter=blob:none --no-tags origin "$UPSTREAM_SHA"
git -C "$UP" checkout -q --detach FETCH_HEAD
GOT=$(git -C "$UP" rev-parse HEAD)
[ "$GOT" = "$UPSTREAM_SHA" ] || { echo "SHA mismatch: got $GOT" >&2; exit 1; }

SRC="$UP/lean"
[ -d "$SRC/$FAMILY_DIR" ] || { echo "no such family dir: $FAMILY_DIR" >&2; exit 1; }
NF=$(find "$SRC/$FAMILY_DIR" -name '*.lean' | wc -l | tr -d ' ')
NL=$(find "$SRC/$FAMILY_DIR" -name '*.lean' -exec cat {} + | wc -l | tr -d ' ')
echo "    $NF files, $NL lines"

# --------------------------------------------- 2. dependency admissibility
say "checking the family imports nothing beyond Mathlib"
SELF_PREFIX="${FAMILY_DIR//\//.}"
BAD=$(find "$SRC/$FAMILY_DIR" -name '*.lean' -exec grep -h '^import ' {} + \
      | awk '{print $2}' | sort -u \
      | grep -vE '^(Mathlib|Batteries|Aesop|Qq|Plausible|ImportGraph|LeanSearchClient|ProofWidgets)(\.|$)' \
      | grep -v "^$SELF_PREFIX" || true)
if [ -n "$BAD" ]; then
  echo "    needs imports this harness does not provide:" >&2
  echo "$BAD" | sed 's/^/      /' >&2
  echo "    That is itself a finding -- report it, do not work around it." >&2
  exit 2
fi
echo "    ok: Mathlib only"

# ------------------------------------------------------- 3. project layout
say "assembling a minimal Lake project"
PROJ="$WORK/proj"
TOP="${FAMILY_DIR%%/*}"
rm -rf "$PROJ/$TOP" "$PROJ/ComparatorChallenges"
mkdir -p "$PROJ/$(dirname "$FAMILY_DIR")"
cp -R "$SRC/$FAMILY_DIR" "$PROJ/$(dirname "$FAMILY_DIR")/"
if [ -n "${CHALLENGE:-}" ]; then
  mkdir -p "$PROJ/$(dirname "$CHALLENGE")"
  cp "$SRC/$CHALLENGE" "$PROJ/$CHALLENGE"
fi
cp "$SRC/lean-toolchain" "$PROJ/lean-toolchain"
[ -f "$SRC/docs/$FAMILY_NUMBER.md" ] && cp "$SRC/docs/$FAMILY_NUMBER.md" "$PROJ/family-docs.md"

# Pin Mathlib to what upstream's own manifest pins, never to a guess of ours.
MATHLIB_REV=$(python3 -c "
import json,sys
for p in json.load(open('$SRC/lake-manifest.json'))['packages']:
    if p.get('name')=='mathlib':
        print(p['rev']); break
else: sys.exit('mathlib missing from upstream lake-manifest.json')")
echo "    mathlib -> ${MATHLIB_REV:0:12}  (read from upstream manifest)"

cat > "$PROJ/lakefile.toml" <<EOF
name = "recheck"

[[require]]
name = "mathlib"
git = "https://github.com/leanprover-community/mathlib4.git"
rev = "$MATHLIB_REV"

[leanOptions]
autoImplicit = false

[[lean_lib]]
name = "$TOP"
globs = ["${FAMILY_DIR//\//.}.+"]

[[lean_lib]]
name = "ComparatorChallenges"
globs = ["ComparatorChallenges.+"]
EOF

# Our own audit files for this family, if we wrote any.
AUDIT_DIR="$REPO_ROOT/families/$FAMILY_NUMBER"
if compgen -G "$AUDIT_DIR/*.lean" > /dev/null; then
  cp "$AUDIT_DIR"/*.lean "$PROJ/"
  for f in "$AUDIT_DIR"/*.lean; do
    printf '\n[[lean_lib]]\nname = "%s"\n' "$(basename "$f" .lean)" >> "$PROJ/lakefile.toml"
  done
  echo "    copied $(ls "$AUDIT_DIR"/*.lean | wc -l | tr -d ' ') audit file(s)"
else
  echo "    no audit files for this family -- build-only re-check"
fi

# ------------------------------------------------------------- 4. build
cd "$PROJ"
say "lake exe cache get"
lake exe cache get > cache.log 2>&1 || { tail -20 cache.log; exit 1; }

say "lake build $TOP   (this is OpenAI's proof; none of our code is in it)"
START=$(date +%s)
set +e
lake build "$TOP" > build.log 2>&1
BUILD_EXIT=$?
set -e
ELAPSED=$(( $(date +%s) - START ))
{ echo "BUILD_EXIT=$BUILD_EXIT"; echo "ELAPSED_SECONDS=$ELAPSED"; } >> build.log
printf '    exit=%s  wall=%dm%02ds\n' "$BUILD_EXIT" $((ELAPSED/60)) $((ELAPSED%60))
if [ "$BUILD_EXIT" -ne 0 ]; then
  say "BUILD FAILED"; grep -E '^error' build.log | head -5; exit 1
fi

say "handing off to audit.sh"
exec "$REPO_ROOT/audit.sh" "$FAMILY_NUMBER" "$PROJ"
