## 2. The question

Does `exact_count_and_sat`, exactly as stated, imply that ETH is false? The
implication must go through a short human argument, and that argument has to be
written out in full in the result.

The reference definition of ETH is fixed now (Impagliazzo–Paturi 2001), so that it
cannot drift toward whatever the statement turns out to say. ETH says: there is a
δ > 0 such that no deterministic multitape Turing machine decides 3-SAT on n
variables in time 2^{δn}·poly(L), where L is the input length. Refuting it requires,
for every δ > 0, such a machine running in time 2^{δn}·poly(L).

A secondary question: does the statement match the scope on `docs/378.md` and the
paper's Theorem 1.1? A mismatch here only produces a FLAG.

## 3. Checklist (what could make the statement too weak, or trivially true)

Each item records the challenge line numbers it rests on.

- **S1 Uniformity.** One machine must serve every n and F: `∃ machine` has to come
  before `∀ n F`, and may depend only on k. If the quantifiers are swapped, a lookup
  table indexed by n proves the statement trivially.
- **S2 One step does O(1) work.**
  - Read `Turing.TM0.Stmt`, `Turing.Tape.move`/`write`/`mk₁` at the pinned Mathlib
    and record their source lines.
  - `transition` must be a finite table: its domain is `Fin stateCount × Option Bool`.
  - Each step reads and acts on exactly one tape.
  - Defect: any step that can do unbounded work.
- **S3 Halting and output.** `final` must actually halt: its state is `Sum.inl` and
  `step` returns `none` there. The count tape must hold exactly the binary count
  and nothing else; the answer bit must equal `0 < count`.
- **S4 SAT semantics.** `Literal.eval`, `Clause.eval` (∃ a true literal), `CNF.eval`
  (∀ clauses) and `count` (assignments `Fin n → Bool`) must be the standard ones.
- **S5 Coverage of 3-SAT.** Every 3-CNF instance must be representable with k = 3.
  Collapsing duplicate literals and clauses through `Finset` only produces an
  equivalent formula. The case of no clauses and of empty clauses has to be
  checked as well.
- **S6 Encoding.**
  - Is `encodeCNF` canonical?
  - Is L polynomial in n for width-k formulas? Bound m and the unary literal codes.
  - Does it leak nothing about the answer?
  - Can a standard input format be converted into it in polynomial time? If so, the
    poly(L) factor stays poly in the standard input length.
- **S7 The bound is 2^{o(n)} in the right variable.** `runtimeScale n / n → 0`.
  `C, A, d` are fixed per k. The exponent depends on the declared n; check whether a
  formula can declare fewer variables than it uses (it cannot, since F is over `Fin n`).
- **S8 The model is no stronger than a multitape TM.** Simulating this model on a
  standard TM must cost at most polynomial overhead, so 2^{o(n)} survives. The
  converse direction is not needed.
- **S9 The space clause.** It is not needed for ETH. Record only whether it is
  well-defined and not vacuous.
- **S10 Match to `docs/378.md` and the paper.** The Lean bound
  n(log log n)²/√log n is weaker than the paper's n·log log n/√log n. The family page
  already says so; any further mismatch is recorded as a FLAG.

**Verdict.**
- **FAIL**: some item from S1–S8 shows that the statement as written would hold for
  a model or bound under which it does not imply ETH is false, or that it is
  trivially provable.
- **FLAG**: a discrepancy that does not break the implication.
- **PASS**: no FAIL, and the bridge argument is written out.

