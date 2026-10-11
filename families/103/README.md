# Family 103: L = RL = BPL

Upstream: [openai/math](https://github.com/openai/math) @
`fd4aeeb2ee4fc729c18d98444fed42fd0529eeeb`
· statement `lean/ComparatorChallenges/LogspaceEquality.lean`
· proof `lean/OAI/Computability/Logspace/` (39 files, 43,045 lines)
· family page `lean/docs/103.md`

This is the first family here checked at a later upstream commit than
`adc7f12`: its formalization arrived in upstream's 2026-10-07 update.
`family.conf` sets `FAMILY_UPSTREAM_SHA`; an `UPSTREAM_SHA` in the environment
still takes precedence.

## What it states

`OAI.ExactDerandomization.exact_logarithmic_space_derandomization : L = RL ∧ RL = BPL`,
for binary languages, in a machine model the statement defines itself:
finite-state machines with read-only input heads over an end-marked input,
`w` binary work tapes, and one coin bit supplied per step.

The family page notes that the paper's explicit compiler and its running-time
bounds are not part of this comparator target; only the equality of classes is.

## The parts a statement could get wrong

Derandomizing space is sensitive to the model, so these are the points we read
the definitions for (line numbers in `LogspaceEquality.lean`):

- **Randomness is read once.** `run` feeds `coins t` to the transition at step
  `t` only (lines 79–82); a machine that wants a bit again must store it in its
  logarithmic workspace. Allowing re-reads would be a different, much stronger
  model.
- **Space counts what is used.** `spaceThrough` counts the distinct cells each
  work head has visited, summed over tapes, and `LogSpace` bounds it by
  `c · ⌈log₂(n+2)⌉` for every input, every coin sequence and every step
  (lines 84–90).
- **Randomized classes run in polynomial time.** `RL` and `BPL` require every
  coin sequence to halt by `c · (n+2)^k` steps, with error bounds 1/2 and 0
  for `RL`, 2/3 and 1/3 for `BPL`, measured over exactly that many coins
  (lines 119–133).
- **`L` really is deterministic.** `Deterministic` asks the transition to
  ignore the coin (lines 92–93).

We found nothing that makes `BPL ⊆ L` easy in this model. That is a reading,
not a proof that the model is the standard one; multiple input heads, for
instance, are allowed, which is known not to change `L`.

## Gate results

Apple M4 Mac mini (arm64, macOS 26.5.2). Logs in
[`logs/apple-m4-arm64/`](logs/apple-m4-arm64). No CI run yet.

```
    PASS  39/39 modules compiled (39 built this run), exit 0, wall 4m56s
    PASS  1/1 theorems: [propext, Classical.choice, Quot.sound], no sorry
    PASS  55 constants identical after elaboration (types, universe params, definition bodies)
    PASS  rejected: differs in OAI.ExactDerandomization.BPL 
    PASS  none of the above appear in OAI/Computability/Logspace 
    PASS  all Lake packages match their pinned revisions
```

Gate E relaxes `BPL`'s error on no-instances from 1/3 to 1/2 in a copy of the
challenge. Gate D is skipped: the statement is checked by elaboration (gate C).

The proof uses `set_option` 118 times, all of them resource limits
(`maxHeartbeats`, `maxRecDepth`, `synthInstance.maxSize`) or `autoImplicit`.
Gate F used to fail on any `set_option`; it now counts those as benign and
still fails on anything else (`debug.skipKernelTC` is the one that matters).
The change was negative-controlled before this run: a file containing
`debug.skipKernelTC` and a near-miss name was still flagged.

## What this does and does not show

It shows that the 39 files compile against the Mathlib upstream pins, that
the theorem proved is the comparator statement, and that it rests on no axiom
beyond Lean's standard three.

It does not show that the model is the one complexity theorists mean by
`L`, `RL` and `BPL` in every respect, that the proof is understood, or that it
matches the paper.

## Files

| file | what it is |
|---|---|
| [`family.conf`](family.conf) | configuration read by `../../recheck.sh` and `../../audit.sh` |
| [`logs/apple-m4-arm64/`](logs/apple-m4-arm64) | actual output of the run above, the challenge and negative-control dumps (gzipped) and their sha256 |
