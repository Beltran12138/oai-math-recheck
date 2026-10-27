# Statement gate, my own reading (written before seeing the referee's reply)

Reader: the author of PLAN.md (Claude, Opus 5.5), 2026-10-27. Not blind: see PLAN §0.
File read: the challenge at blob `a8d5ff3a`, sha256 (LF) `4183b205…6685`. Line numbers refer to it.
Mathlib definitions read at `d13f23b`: `TM0.Stmt` (PostTuringMachine.lean 118–120: `move : Dir → Stmt`,
`write : Γ → Stmt`), `Tape` (Tape.lean 408–414), `Tape.move` (436–438), `Tape.mk'` (451–452),
`Tape.mk₁` (494–495), `Tape.write` (542–543, replaces the head cell only). Blank of `Option Bool` is `none`.

## Checklist

| item | verdict | lines | reading |
|---|---|---|---|
| S1 uniformity | PASS | 194–199 | `∃ machine, tapes, C A S d e` precede `∀ n F`; they depend on `k` only. |
| S2 O(1) work per step | PASS | 92–99, 107–119 | One tape (`scan q`) is read; `transition` has finite domain `Fin stateCount × Option Bool`, so it is a finite table whatever Lean term defines it; the action is one `move` (±1 cell) or one `write` (head cell). Tape count and state count are fixed numbers in the machine. |
| S3 halting and output | PASS | 107–110, 113, 200–207 | `Trace` advances only while `step` returns `some`; `step` of an `inl` state is `none`, so `final` (state `inl …`, line 207) is halted and `time` is the exact halting time. `Tape` equality uses `ListBlank` (equality up to trailing blanks), the word is `some`-mapped so contains no blank: the count tape holds exactly `countWord count` (0 ↦ [false], else `Nat.bits`, LSB first) with the head on its first cell and nothing to the left. Answer tape and final state both carry `decide (0 < count)`. If `countTape = answerTape` the conjunction is unsatisfiable for count ≥ 2, which can only make the theorem harder, not easier. |
| S4 SAT semantics | PASS | 29–36, 44–47 | Literal true iff `a v == positive`; clause = some literal true; CNF = all clauses true; `count` = number of `Fin n → Bool` assignments satisfying `F`. Standard. |
| S5 coverage | PASS | 19–25, 38 | k = 3 is allowed (`2 ≤ k`). A 3-CNF given as lists maps to `Finset`s with the same satisfying set (duplicates are irrelevant to ∃ / ∀). Empty clause = unsatisfiable, empty CNF = all 2ⁿ assignments: standard. |
| S6 encoding | PASS | 55–79 | Canonical (images sorted). `n` and literal codes `2v+b < 2n` are unary, so L = O(n + m·k·n) with m ≤ (2n+1)^k: L = poly(n) for fixed k. It is a function of F only; nothing about the answer. A standard encoding (binary indices, possibly duplicates) converts to it in time poly(L_std, n), and n-dependence of that cost is absorbed by 2^{δn}. |
| S7 bound | PASS | 132–139, 210–211 | `runtimeBound C A d L n = C·(L+1)^d·2^{A·runtimeScale n}`, argument order checked at 210–211. `runtimeScale n = n·(ln ln(n+16))²/√ln(n+16)` and `runtimeScale n / n → 0`. Exponent is in the declared variable count `n`; F is over `Fin n`, so it cannot use more. |
| S8 model ≤ multitape TM | PASS | 92–119 | Finite control, fixed number of two-way infinite tapes over a 3-letter alphabet, one head acts per step: simulable by a standard multitape TM with O(1) overhead per step. No random access, no unbounded arithmetic. |
| S9 space clause | PASS (record only) | 149–189, 212–218 | `visitedSpace` sums `upper − lower + 1` per tape, initial input-tape window `[0, |input|−1]`, bound `S·(L+1)^e` at every prefix. Well-defined, not vacuous. Not needed for ETH. |
| S10 match | PASS, no new FLAG | 132–134 | Matches `docs/378.md` Scope (n(log log n)²/√log n, poly(L) space). Weaker than the paper's n·log log n/√log n, as the family page says. The abstract's n/(log n)^{1/2+o(1)} is consistent with both because the o(1) there is negative. |

OPEN: none needed for the implication. Not checked by reading: which order `List (List ℕ)` uses
in `sort` (any total order keeps the encoding canonical, so it does not matter here); that the file
elaborates (that is gate C, out of scope).

## Bridge argument (theorem ⇒ ETH is false)

Fix δ > 0 and k = 3; take the machine M and constants C, A, d from the theorem. Given a 3-CNF in a
standard encoding of length L_std on n variables: (1) convert it to `encodeCNF F` (dedupe, sort,
unary) in time poly(L_std, n); its length L ≤ poly(n, L_std). (2) Simulate M on a multitape TM with
O(1) overhead per step; by the theorem it halts within C·(L+1)^d·2^{A·runtimeScale n} steps with
`decide (0 < count F)`, i.e. satisfiability, on its answer tape. (3) Since A·runtimeScale n ≤ (δ/2)·n
for n ≥ n₀(δ) and poly(n) ≤ 2^{(δ/2)n} eventually, total time ≤ 2^{δn}·poly(L_std) for n ≥ n₁(δ);
the finitely many smaller n are handled by a table. Hence for every δ > 0, 3-SAT is decidable in
time 2^{δn}·poly(L), which contradicts ETH.

## Verdict (mine)

PASS: no item in S1–S8 shows a loophole or a weakening; the bridge argument above is complete at the
level of standard machine-simulation facts. This is a reading, not a machine check, and it is not
blind. Final verdict waits on the referee (PLAN §4).
