# Family 378 (ETH): statement gate result

Plan: [`PLAN.md`](PLAN.md), frozen at `ccdeadd`. Run 2026-10-27, about 1h of wall time, no Lean build.
Everything below concerns the statement only: compilation, axioms and the proof are not examined here.

## Verdict

**PASS.** The control was valid, and both readings agree on the original.

`exact_count_and_sat`, exactly as stated at upstream `7ef5c0c` (challenge blob `a8d5ff3a`), implies
that the Exponential Time Hypothesis is false. The implication needs one human step: simulating the
statement's machine model on a standard multitape Turing machine, and converting a standard 3-CNF
encoding into the statement's encoding. Both bridge write-ups lay that step out. No item in S1–S8
shows a loophole or a weakening.

## Blind control (PLAN §4)

Four copies were written and hashed before the referee started: label key
[`statement-gate/labelkey.json`](statement-gate/labelkey.json), sha256 `f1af9269…69d5`. The referee
was a newly spawned agent restricted to [`statement-gate/referee/`](statement-gate/referee); it was
not shown my reading.

| label | version | referee | reason given | right reason? |
|---|---|---|---|---|
| A | M1, `∃ machine` moved inside `∀ n` | NO | a separate machine and constants for each n, so a lookup table proves it (S1) | yes |
| B | M3, `Clause.eval` uses `∀` | NO | each clause becomes a conjunction, so the statement counts the wrong function (S4) | yes |
| C | original | YES | S1–S9 pass, bridge argument written out | — |
| D | M2, `runtimeScale n := n` | NO | the bound becomes 2^{A·n}, which brute force meets, so ETH is untouched (S7) | yes |

The control passes: all three mutants were rejected, each for its own reason.

## Agreement

My reading ([`statement-gate/my_reading.md`](statement-gate/my_reading.md), sha256 `7c09e52f…a07e`,
hashed at 15:17:35Z, before the reply existed) and the referee's ([`reply.md`](statement-gate/referee/reply.md),
`1f0bb11c…cb1`) agree on every item S1–S9 for the original. They differ only in wording on S10:

- The referee marks S10 FLAG for the weaker Lean bound. That weakening is the one `docs/378.md` already
  states, which PLAN §3 does not count as a new FLAG.
- The referee also marks S10 OPEN, because the family page and the paper were not in its directory.

Points both readings reached independently:
- `time` is the exact halting time.
- If `countTape = answerTape`, the statement only becomes harder to prove, not weaker.
- Encoding length is polynomial in n for fixed k, and the unary n is absorbed by 2^{δn}.

## Open, handed to later gates

- Whether the file elaborates at the pinned Mathlib. One example the referee named is the order
  instance used by `Finset.sort` on `List ℕ` (line 71). If the file did not elaborate, the question
  would be moot; that is gate C's job. Any total order keeps the encoding canonical, so the choice of
  instance does not affect the implication.
- That the proof checks, and which axioms it rests on (gates A and B).

## Limits of this gate (read before quoting the PASS)

- **The blinding was partial.** The four copies share one ancestor, so a `diff` among them shows which
  copy is at the center. The referee used `diff` and said it used C as the reference "for this list
  only". It could therefore have guessed that C was unaltered; it was told not to try.
- **The control measures application, not discovery.** The checklist the referee received names the
  failure modes. S1 even describes the quantifier swap. So the control shows the referee applies the
  checklist correctly. It does not show that either reader would find a loophole the checklist does not
  name.
- **Model and encoding facts are argued, not proved.** "This machine model is no stronger than a
  multitape TM" and "standard encodings convert in poly time" are standard simulation arguments. No
  machine check covers them.
- **The referee is the same model family as the author.** Agreement between two Claude readings is
  weaker evidence than a human complexity theorist's reading.
- **A PASS here does not mean the theorem is true.** It means that if the proof checks against this
  statement, ETH is false.

## Hash note (added after commit `22c1074`)

`labelkey.json` and `referee/checklist.md` were written with CRLF line endings on Windows, and the
hashes above (`f1af9269…` and, in `referee/inputs.sha256`, `fd5a792f…`) were taken over those bytes,
which are the bytes the referee actually read. Git stores both files with LF, so a fresh checkout
hashes to `81fe8897…` and `b9a11f50…`. To reproduce the recorded hashes, convert back with
`unix2dos` first. Every other hash in this family was taken over LF files.

## Files

| file | what it is |
|---|---|
| `statement-gate/copies/copy_{A..D}.lean` | the four copies shown to the referee (C equals upstream; sha256 in `referee/inputs.sha256`) |
| `statement-gate/labelkey.json` | label → version, written before the referee started |
| `statement-gate/referee/BRIEF.md`, `checklist.md`, `mathlib_excerpts.md` | everything the referee was given |
| `statement-gate/referee/reply.md` | the referee's full answer |
| `statement-gate/my_reading.md` | my reading, hashed before the reply |
