# Family 378 (Exponential Time Hypothesis): pre-registration, statement gate only

Status: FROZEN 2026-10-27 on the user's word. Frozen means committed unchanged;
after that, any change is a new dated section below the original, never an edit.

## 0. What I already know (disclosed before freezing)

On 2026-10-27, before writing this plan, I read the full challenge file once and
told the user my first reading was "faithful, medium confidence". That opinion
is contamination: whoever reads the statement next is no longer blind. Section 4
exists because of it.

I have not read the proof (`lean/OAI/Algorithms/SubexponentialSAT/`, about 710k
lines). I only grepped it mechanically for `sorry`, `admit`, `axiom` and
`native_decide`, and found none used as tactics or declarations. That grep is not
part of this gate and is not a result.

## 1. Pinned inputs

| item | pin |
|---|---|
| upstream | `openai/math` @ `7ef5c0cc5ca4b0e072b7a050fca09ab24bc6fa3a` (2026-10-26 14:18 −0700) |
| challenge | `lean/ComparatorChallenges/SubexponentialSAT.lean`, git blob `a8d5ff3a3e80323675b1f2d1ea611560b783e9ca`, sha256 (LF) `4183b205…6685` |
| challenge config | `SubexponentialSAT.json`, sha256 `debbfdc9…5b19`; theorem `OAI.Algorithms.SubexponentialSAT.SqrtLogSpace.exact_count_and_sat`; permitted axioms the standard three |
| family page | `lean/docs/378.md`, sha256 `a2f7b390…1f79`; it lists exactly one comparator statement |
| paper | `preprints/The-Exponential-Time-Hypothesis-is-False-October-25-2026/paper.pdf`, sha256 `5b1612dc…8123` |
| Mathlib / toolchain | `d13f23b723b8…` / `leanprover/lean4:v4.34.1` (same as family 325) |

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

## 4. Blind control (because of section 0)

A freshly started agent (not a fork, and not shown my opinion) receives four
copies of the challenge under random labels A–D:
- the original;
- **M1**: `∃ machine` moved inside `∀ n F` (non-uniform, so trivial);
- **M2**: `runtimeScale n := n` (an exponential bound, so ETH is not refuted);
- **M3**: `Clause.eval` uses `∀` instead of `∃` (the wrong function is counted).

It also receives sections 2 and 3, the ETH definition, and the pinned Mathlib
definitions from S2. Its task: for each copy, say whether it implies ETH is false,
citing lines.

- **The control passes** only if all three mutants are rejected, each for its own
  reason.
- If the control fails, the gate result is **INCONCLUSIVE** and no PASS is
  reported. One retry is allowed after clarifying the brief; the original brief and
  the revised one are both kept.
- I do S1–S10 separately. A final verdict needs my reading and the referee's verdict
  on the original to agree. If they disagree, both are reported and there is no
  verdict.
- The mutant files and the label key are written and hashed before the referee
  starts.

## 5. Out of scope

Compilation and gates A–G, axioms, whether the proof is correct, whether the paper
is correct, practicality, and whether the paper's own claims beyond ETH hold (circuit
lower bounds, Max-k-SAT, and the rest).

## 6. Budget and stopping

- Three hours of wall time. No Lean build.
- If the S2 or S3 reading needs elaboration to settle (for example, an instance or
  coercion I cannot resolve by reading source), I record it as **open**. I do not
  guess, and I do not start a build to settle it inside this gate.
- Output: `families/378/STATEMENT.md`, plus the referee brief, its reply, the mutant
  files and their hashes under `families/378/statement-gate/`.
- Nothing is pushed or posted without the user's explicit word.
