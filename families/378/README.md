# Family 378: subexponential #k-SAT (Exponential Time Hypothesis)

Upstream: [openai/math](https://github.com/openai/math) @
`7ef5c0cc5ca4b0e072b7a050fca09ab24bc6fa3a`
· statement `lean/ComparatorChallenges/SubexponentialSAT.lean`
· proof `lean/OAI/Algorithms/SubexponentialSAT/` (3,977 files, 710,320 lines)
· family page `lean/docs/378.md`

This family was checked in two stages. The statement was read first, under a
pre-registration frozen before the reading ([`PLAN.md`](PLAN.md)); the result
is in [`STATEMENT.md`](STATEMENT.md). The build gates below ran afterwards, on
`family.conf` as committed in `ee5c1ef`.

## What it states

`OAI.Algorithms.SubexponentialSAT.SqrtLogSpace.exact_count_and_sat`: for each
`k ≥ 2` there is one machine, with constants `C, A, S, d, e` fixed before `n`,
that on every CNF of width at most `k` over `n` variables writes the number of
satisfying assignments and whether it is positive, within time
`C · (b+1)^d · 2^{A · runtimeScale n}` and space `S · (b+1)^e`, where `b` is
the input's bit length and
`runtimeScale n = n · (log log (n+16))² / √(log (n+16))`
(challenge lines 132–139, 194–217), in the statement's machine model. The statement gate's reading is that this, taken as stated,
refutes the Exponential Time Hypothesis, with one human step (simulating the
model on a standard Turing machine and converting the input encoding). See
[`STATEMENT.md`](STATEMENT.md) for the checklist, the blind control and the
limits of that reading.

## Gate results

Apple M4 Mac mini (arm64, 16 GB, macOS 26.5.2). Logs in
[`logs/apple-m4-arm64/`](logs/apple-m4-arm64).

```
    PASS  3977/3977 modules compiled (0 built this run), exit 0, wall 0m3s
    PASS  1/1 theorems: [propext, Classical.choice, Quot.sound], no sorry
    PASS  69 constants identical after elaboration (types, universe params, definition bodies)
    SKIP  family.conf does not declare COPIED_DEFS / COPIED_INTO / CHALLENGE
    PASS  rejected: differs in OAI.Algorithms.SubexponentialSAT.SqrtLog.Statement.runtimeScale 
    FAIL  present, needs a human look: set_option(7) ^(macro|elab|syntax)(4)
    PASS  all Lake packages match their pinned revisions
    SKIP  no family README or no archived logs
```

"0 built this run" is expected: the modules were built before this run (next
section), and Lake rebuilds nothing whose inputs are unchanged.

Gate E changes the exponent of `log log n` in `runtimeScale` from 2 to 3 in a
copy of the challenge, the substitution fixed in `family.conf`. The two dumps
differ in exactly that literal (two bytes) and the copy is rejected. Gate D is
skipped: the statement is checked by elaboration (gate C). Gate G was skipped
because this README did not exist yet; its check, run afterwards on this file
and `logs/`, finds all 8 quoted lines, and fails on a copy with "69 constants"
changed to "68 constants".

### Gate F, read by hand

Gate F flags 11 lines. None of them is a kernel bypass; both counts come from
gaps in the gate, not from the proof.

- **7 × `set_option quotPrecheck false`**, one per file, in seven files that
  each declare `local notation` over section variables (for example
  `SqrtLog/LeafProgramPreparedRecoveryQuery.lean:15`, followed by
  `local notation "num" => …` at line 21). The option only switches off a
  check on notation definitions; it does not reach the kernel. It is missing
  from gate F's benign list.
- **4 × `^(macro|elab|syntax)`**, all inside doc comments, where a wrapped
  sentence starts a line with the word: `ParserProgram.lean:270` ("syntax
  equality …"), `SqrtLogSpace/HighQuerySetup.lean:704` ("syntax, …"),
  `SqrtLogSpace/NativeQueryPreparation.lean:357` ("elaboration …", matched by
  the missing word boundary after `elab`), `StructuredCalls.lean:152`
  ("syntax and …"). The pattern does not skip comments.

`^axiom`, `native_decide`, `unsafe`, `implemented_by`, `@[extern`,
`Lean.ofReduceBool` and `#exit` occur 0 times. The two gate defects are
recorded for a fix with its own negative control; until then gate F reads FAIL
for this family and the reading above is what replaces it.

## How the build was run

The build did not run in one go, and two of the problems were ours.

1. **Network.** The first attempt (2026-10-27) failed cloning Mathlib
   (`curl 56 … Operation timed out`). Lake packages were then copied from an
   existing checkout at the same pinned revisions; gate F's package check
   compares every package to its pin and passed.
2. **Two runs at once (our error).** A run started by a command we believed
   had been cancelled was still running when a second run was started. The two
   competed for memory; both were stopped and the build directory discarded.
3. **Parallel build exhausted memory.** The next run built most modules with
   Lake's default parallelism, then stalled: single modules of this family need
   up to about 9 GB, and several at once exceeded the 16 GB machine
   (`mem-378.log` reaches 7% free memory with 18 GB of swap and 9 `lean`
   processes). The machine was restarted; that run's build output was lost,
   but the `.olean` files it finished were kept.
4. **Serial completion.** The remaining 65 modules were built one at a time
   (`lake build +Module` in import order), 2026-10-28 20:55–21:11, all exit 0;
   peak resident memory 9.2 GB (`HighQueryLoop`, `HighQueryTraversal`). Log:
   `serial-378.log`.
5. **Final run.** `recheck.sh 378` then ran the gates above, with nothing left
   to build.

So there is no single log showing all 3,977 modules being compiled. What
gate A shows is that the final `lake build` of the whole family exited 0
without rebuilding anything, which Lake only does when every module's recorded
inputs match.

## What this does and does not show

It shows that the 3,977 files compile against the Mathlib upstream pins, that
the theorem proved is the comparator statement (69 constants, definition
bodies included), and that it rests on no axiom beyond Lean's standard three.

It does not show that the machine model and input encoding are the standard
ones (that is the human step in [`STATEMENT.md`](STATEMENT.md)), that the proof
is understood, or that it matches the paper. Only one architecture has been
run so far.

## Files

| file | what it is |
|---|---|
| [`PLAN.md`](PLAN.md) | pre-registration of the statement gate, frozen at `ccdeadd` |
| [`STATEMENT.md`](STATEMENT.md) | statement gate result, blind control, limits |
| [`statement-gate/`](statement-gate) | the copies, label key, readings and referee material |
| [`family.conf`](family.conf) | configuration read by `../../recheck.sh` and `../../audit.sh` |
| [`logs/apple-m4-arm64/`](logs/apple-m4-arm64) | output of the final run, the serial build and memory logs, the challenge and negative-control dumps (gzipped) and their sha256 |
