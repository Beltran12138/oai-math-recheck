#!/usr/bin/env bash
# Audit gates for a family prepared by recheck.sh.
#
#   ./audit.sh <family-number> [project-dir]
#
# Each gate prints PASS / FAIL / SKIP on its own line and the script exits
# non-zero if any gate fails.  The gates are deliberately independent: gate B
# does not go through any file we wrote, so a bug in our own audit code cannot
# masquerade as a problem in OpenAI's proof.  Gates D and E exist because
# gate C can pass vacuously, and gate G because the write-up can cite a log
# that cannot contain what it quotes.

set -uo pipefail

# Resolved from this script's own location, not $PWD: recheck.sh cd's into the
# build directory before exec'ing us, so $PWD is the project, not the repo.
REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
FAMILY_NUMBER="${1:-}"
[ -n "$FAMILY_NUMBER" ] || { sed -n '2,12p' "$0" >&2; exit 64; }
PROJ="${2:-$REPO_ROOT/.work/$FAMILY_NUMBER/proj}"
CONF="$REPO_ROOT/families/$FAMILY_NUMBER/family.conf"
[ -f "$CONF" ] || { echo "no config: $CONF" >&2; exit 64; }
# shellcheck source=/dev/null
. "$CONF"

cd "$PROJ" || exit 1
TOP="${FAMILY_DIR%%/*}"
FAILED=0
gate() { printf '\n--- gate %s: %s\n' "$1" "$2"; }
ok()   { printf '    PASS  %s\n' "$1"; }
no()   { printf '    FAIL  %s\n' "$1"; FAILED=1; }
skip() { printf '    SKIP  %s\n' "$1"; }

# ===================================================== A. does it compile
gate A "OpenAI's proof compiles"
BE=$(grep -o 'BUILD_EXIT=[0-9]*' build.log | tail -1 | cut -d= -f2)
EL=$(grep -o 'ELAPSED_SECONDS=[0-9]*' build.log | tail -1 | cut -d= -f2)
NSRC=$(find "$FAMILY_DIR" -name '*.lean' | wc -l | tr -d ' ')
# `lake build` also exits 0 when a lean_lib glob matches nothing, so exit 0 on
# its own would let this gate pass while measuring nothing.  The number that
# earns the gate is the count of .olean files actually on disk; the count of
# modules Lake reports building is informational, and is 0 on a cached re-run.
NOLEAN=$(find .lake/build -path "*/$FAMILY_DIR/*" -name '*.olean' 2>/dev/null | wc -l | tr -d ' ')
NBUILT=$(grep -cE "Built ${FAMILY_DIR//\//\.}\." build.log)
if [ "${BE:-1}" != "0" ]; then
  no "build exit $BE"; grep -E '^error' build.log | head -3
elif [ "${NOLEAN:-0}" != "$NSRC" ]; then
  no "exit 0 but $NOLEAN .olean for $NSRC sources -- the build did not cover the family"
else
  ok "$NOLEAN/$NSRC modules compiled ($NBUILT built this run), exit 0, wall $((EL/60))m$((EL%60))s"
fi

# ============================================ B. axioms, via nothing of ours
gate B "the headline theorems rest on no axiom beyond the standard three"
: "${MAIN_IMPORT:?family.conf must set MAIN_IMPORT}"
: "${THEOREMS:?family.conf must set THEOREMS}"
{ echo "import $MAIN_IMPORT"; for t in $THEOREMS; do echo "#print axioms $t"; done; } > .axcheck.lean
AX=$(lake env lean .axcheck.lean 2>&1)
echo "$AX" > axioms.log
echo "$AX" | sed 's/^/      /'
if echo "$AX" | grep -q 'sorryAx'; then
  no "sorryAx present -- the proof is incomplete"
elif echo "$AX" | grep -q 'depends on axioms'; then
  EXTRA=$(echo "$AX" | grep -o '\[.*\]' | tr -d '[]' | tr ',' '\n' | tr -d ' ' \
          | grep -vE '^(propext|Classical\.choice|Quot\.sound)$' | grep -v '^$' | sort -u | tr '\n' ' ')
  NTH=$(echo "$THEOREMS" | wc -w | tr -d ' ')
  NGOT=$(echo "$AX" | grep -c 'depends on axioms')
  if [ -n "$EXTRA" ]; then no "extra axioms: $EXTRA"
  elif [ "$NGOT" != "$NTH" ]; then no "asked about $NTH theorems, got $NGOT answers"
  else ok "$NGOT/$NTH theorems: [propext, Classical.choice, Quot.sound], no sorry"; fi
else
  no "no axiom output at all -- see axioms.log"
fi

# ======================================= C. is it the challenge's statement?
gate C "what is proved is the statement in the comparator challenge"
# Two ways to answer this.  With CHALLENGE_MODULE set, do what comparator does:
# elaborate the challenge and the solution in separate processes and compare
# every OAI constant the statement reaches (tools/StatementDump.lean).  That
# works when the statement contains a `structure`, which the copy-and-defeq
# method below cannot handle.  An empty dump on both sides also "matches", so
# the gate demands a non-empty dump that contains every headline theorem.
DUMP_TOOL="$REPO_ROOT/tools/StatementDump.lean"
dump() { lake env lean --run "$DUMP_TOOL" "$1" $THEOREMS > "$2" 2> "$2.err"; }
DUMPED=0
if [ -n "${CHALLENGE_MODULE:-}" ]; then
  DUMPED=1
  if ! lake build "$CHALLENGE_MODULE" > challenge-build.log 2>&1; then
    no "the challenge module itself does not build -- see challenge-build.log"
  else
    dump "$CHALLENGE_MODULE" dump-challenge.txt; DC=$?
    dump "$MAIN_IMPORT" dump-solution.txt; DS=$?
    NC=$(wc -l < dump-challenge.txt | tr -d ' ')
    HAVE=0
    for t in $THEOREMS; do
      grep -q "^$t	theorem	" dump-challenge.txt && grep -q "^$t	theorem	" dump-solution.txt && HAVE=$((HAVE+1))
    done
    NTH=$(echo "$THEOREMS" | wc -w | tr -d ' ')
    if [ "$DC" != "0" ] || [ "$DS" != "0" ]; then
      no "a dump failed (challenge exit $DC, solution exit $DS) -- see dump-*.txt.err"
    elif [ "$NC" = "0" ] || [ "$HAVE" != "$NTH" ]; then
      no "dump is empty or lacks a headline theorem ($HAVE/$NTH found) -- nothing was compared"
    elif ! cmp -s dump-challenge.txt dump-solution.txt; then
      no "solution and challenge elaborate differently:"
      diff dump-challenge.txt dump-solution.txt | grep '^[<>]' | cut -f1,2 | sort -u | head -10 | sed 's/^/      /'
    else
      ok "$NC constants identical after elaboration (types, universe params, definition bodies)"
    fi
    # Pinned facts about how the statement elaborated, e.g. which norm instance
    # a definition picked up.  Each line is "constant|substring", checked
    # against the challenge dump; a missing constant counts as a failure.
    if [ -n "${DUMP_ASSERT:-}" ]; then
      while IFS='|' read -r c needle; do
        [ -z "$c" ] && continue
        L=$(grep "^$c	" dump-challenge.txt)
        if [ -z "$L" ]; then no "assert: $c is not in the dump"
        elif printf '%s' "$L" | grep -qF "$needle"; then ok "assert: $c uses $needle"
        else no "assert: $c does not use $needle"; fi
      done <<< "$DUMP_ASSERT"
    fi
  fi
fi
if compgen -G "*.lean" > /dev/null && [ -n "${AUDIT_TARGETS:-}" ]; then
  VOUT=$(for t in $AUDIT_TARGETS; do lake build "$t" 2>&1; done)
  echo "$VOUT" > verify.log
  if echo "$VOUT" | grep -qE '^error|error:'; then
    no "our audit files do not compile -- most likely OUR bug, not theirs"
    echo "$VOUT" | grep -E 'error' | head -5 | sed 's/^/      /'
  else
    ok "$AUDIT_TARGETS built; the defeq checks inside them went through"
  fi
elif [ "$DUMPED" = "0" ]; then
  skip "no audit files and no CHALLENGE_MODULE for this family"
fi

# ============================== D. are the copied definitions really theirs?
# Gate C is vacuous if we copied the definitions out of the *solution* instead
# of the *challenge*: then it proves a thing by itself.  So diff them.
gate D "definitions compared against the challenge are verbatim the challenge's"
if [ -n "${COPIED_DEFS:-}" ] && [ -n "${COPIED_INTO:-}" ] && [ -n "${CHALLENGE:-}" ]; then
  python3 - "$CHALLENGE" "$COPIED_INTO" $COPIED_DEFS <<'PY'
import re, sys
chal, mine, *names = sys.argv[1:]
def grab(path):
    s = open(path, encoding='utf-8').read()
    out = {}
    # A declaration ends at a blank line or at the next line that starts in
    # column 0.  Ending only at blank lines once glued two adjacent abbrevs
    # together and reported a false DIFFERS.
    for n in names:
        m = re.search(r'^(?:noncomputable\s+)?(?:def|abbrev|structure)\s+' + re.escape(n)
                      + r'(?=[\s:({\[]).*?(?=\n(?:[ \t]*\n|\S)|\Z)', s, re.S | re.M)
        out[n] = re.sub(r'\s+', ' ', m.group(0)).strip() if m else None
    return out
a, b = grab(chal), grab(mine)
bad = [n for n in names if a[n] is None or a[n] != b[n]]
for n in names:
    print(f"      {'same' if n not in bad else 'DIFFERS'}  {n}")
print(("    PASS  %d/%d verbatim identical" % (len(names), len(names))) if not bad
      else "    FAIL  %d of %d differ or missing" % (len(bad), len(names)))
sys.exit(1 if bad else 0)
PY
  [ $? -eq 0 ] || FAILED=1
else
  skip "family.conf does not declare COPIED_DEFS / COPIED_INTO / CHALLENGE"
fi

# ======================================== E. does gate C actually have teeth?
# Perturb the constant in our own audit file.  If the perturbed file still
# compiles, gate C was not testing anything.
gate E "negative control: a wrong constant must be rejected"
if [ "${NEG_KIND:-}" = "dump" ] && [ -n "${NEG_SED:-}" ] && [ -n "${CHALLENGE:-}" ]; then
  # Perturb a copy of the challenge, elaborate it, and require its dump to
  # disagree with the solution's.  If it agrees, gate C compares nothing.
  NEGMOD=ComparatorChallenges.NegControl
  sed "$NEG_SED" "$CHALLENGE" > ComparatorChallenges/NegControl.lean
  if cmp -s "$CHALLENGE" ComparatorChallenges/NegControl.lean; then
    no "NEG_SED changed nothing -- the control is not testing anything"
  elif ! lake build "$NEGMOD" > neg-build.log 2>&1; then
    no "the perturbed challenge does not build -- see neg-build.log"
  else
    dump "$NEGMOD" dump-negcontrol.txt; DN=$?
    NN=$(wc -l < dump-negcontrol.txt | tr -d ' ')
    if [ "$DN" != "0" ] || [ "$NN" = "0" ]; then
      no "the negative-control dump failed or is empty"
    elif cmp -s dump-negcontrol.txt dump-solution.txt; then
      no "the perturbed statement dumps identically -- gate C is vacuous"
    else
      ok "rejected: differs in $(diff dump-negcontrol.txt dump-solution.txt | grep '^<' | cut -f1 | cut -c3- | sort -u | tr '\n' ' ')"
    fi
  fi
  rm -f ComparatorChallenges/NegControl.lean
elif [ -n "${NEG_FILE:-}" ] && [ -n "${NEG_SED:-}" ] && [ -f "$NEG_FILE" ]; then
  sed "$NEG_SED" "$NEG_FILE" > .NegControl.lean
  if cmp -s "$NEG_FILE" .NegControl.lean; then
    no "NEG_SED changed nothing -- the control is not testing anything"
  else
    NOUT=$(lake env lean .NegControl.lean 2>&1)
    if echo "$NOUT" | grep -qE 'error'; then
      ok "rejected: $(echo "$NOUT" | grep -E 'error' | head -1 | cut -c1-70)"
    else
      no "the perturbed statement still compiles -- gate C is vacuous"
    fi
  fi
  rm -f .NegControl.lean
else
  skip "family.conf declares neither NEG_KIND=dump nor NEG_FILE / NEG_SED"
fi

# ========================================= F. anything that skips the kernel
gate F "no kernel bypass, no custom axioms, dependencies untouched"
SCOPE="$FAMILY_DIR"
declare -a HITS=()
for pat in 'set_option' '^axiom ' 'native_decide' '\bunsafe\b' 'implemented_by' \
           '@\[extern' 'Lean\.ofReduceBool' '#exit' '^(macro|elab|syntax)'; do
  n=$(grep -rnE "$pat" "$SCOPE" 2>/dev/null | wc -l | tr -d ' ')
  printf '      %-22s %s\n' "$pat" "$n"
  [ "$n" != "0" ] && HITS+=("$pat($n)")
done
if [ ${#HITS[@]} -eq 0 ]; then
  ok "none of the above appear in $SCOPE"
else
  no "present, needs a human look: ${HITS[*]}"
fi
DIRTY=0
for d in .lake/packages/*/; do
  c=$(git -C "$d" status --porcelain 2>/dev/null | wc -l | tr -d ' ')
  [ "$c" != "0" ] && { printf '      dirty: %s (%s files)\n' "$(basename "$d")" "$c"; DIRTY=1; }
done
[ "$DIRTY" = "0" ] && ok "all Lake packages match their pinned revisions" \
                   || no "a dependency has local modifications"
printf '      toolchain: %s\n' "$(cat lean-toolchain)"

# ============================ G. does the write-up quote the logs it has?
# Found the hard way: the archived logs were once from a run older than the
# line the README quoted off them, so the quote could not have come from the
# file it cited.  Nothing catches that by reading.  This only covers lines
# that look like Lean or Lake output -- prose, and the timing tables in
# particular, are still on the author.
gate G "log lines the write-up quotes are really in the archived logs"
FAM_README="$REPO_ROOT/families/$FAMILY_NUMBER/README.md"
FAM_LOGS="$REPO_ROOT/families/$FAMILY_NUMBER/logs"
if [ -f "$FAM_README" ] && [ -d "$FAM_LOGS" ]; then
  python3 - "$FAM_README" "$FAM_LOGS" <<'PY'
import os, re, sys
readme, logdir = sys.argv[1], sys.argv[2]
blob = []
for root, _, files in os.walk(logdir):
    for f in files:
        try:
            blob.append(open(os.path.join(root, f), encoding='utf-8').read())
        except (OSError, UnicodeDecodeError):
            pass
blob = '\n'.join(blob)

# Only lines that are recognisably tool output, inside a fenced block.
LOOKS_LIKE_OUTPUT = re.compile(
    r'depends on axioms|^\s*(info|warning|error):|^\s*[✔✖ℹ⚠]\s*\[|^\s*Build completed')
quoted, fenced = [], False
for line in open(readme, encoding='utf-8').read().splitlines():
    if line.lstrip().startswith('```'):
        fenced = not fenced
        continue
    if fenced and LOOKS_LIKE_OUTPUT.search(line) and line.strip():
        quoted.append(line.strip())

missing = [q for q in quoted if q not in blob]
for q in quoted:
    print(f"      {'found  ' if q not in missing else 'MISSING'}  {q[:78]}")
if not quoted:
    print("    SKIP  the write-up quotes no tool output")
elif missing:
    print("    FAIL  %d of %d quoted lines are in no archived log" % (len(missing), len(quoted)))
else:
    print("    PASS  %d/%d quoted lines verbatim in %s/" % (
        len(quoted), len(quoted), os.path.basename(logdir)))
sys.exit(1 if missing else 0)
PY
  [ $? -eq 0 ] || FAILED=1
else
  skip "no family README or no archived logs"
fi

# ================================================================== verdict
printf '\n'
if [ "$FAILED" = "0" ]; then
  printf '===> family %s: ALL GATES PASSED\n' "$FAMILY_NUMBER"
else
  printf '===> family %s: SOME GATES FAILED\n' "$FAMILY_NUMBER"
fi
printf '     logs: %s/{build,axioms,verify}.log\n' "$PROJ"
exit "$FAILED"
