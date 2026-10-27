# Referee reply: four copies of `exact_count_and_sat`

Sources used: only `BRIEF.md`, `checklist.md`, `mathlib_excerpts.md`, `copy_A.lean`–`copy_D.lean` in this directory. Differences were found by a byte-level `diff` of C against A, B and D (no hashing). Nothing was compiled; anything that would need Lean is marked OPEN.

A caveat that applies to every YES: "implies ETH is false" is a claim about the statement, not about whether the statement is true. If a statement is false, it implies everything vacuously. My YES only means: *if* this statement is proved, a short argument gives a refutation of ETH.

## Summary

| Copy | Verdict | Reason |
|---|---|---|
| A | **NO** | Line 195: `∀ (n : ℕ), ∃ (machine …)`. The machine and the constants C, A, d are chosen after n, so for each n a hard-wired machine (or one whose constant C absorbs brute force) works. The statement is trivially true and says nothing about uniform algorithms. |
| B | **NO** | Line 33: `Clause.eval` uses `∀ l ∈ C`, so a "clause" becomes a conjunction. The formula is then one big conjunction of literals, whose count is computable in polynomial time. The statement is about the wrong function. |
| C | **YES** (conditional on the statement compiling as read; see S2/S6 OPEN notes) | The machine is uniform, the SAT semantics are standard, the bound is 2^{o(n)}·poly(L), and the model is a restricted multitape TM. |
| D | **NO** | Lines 132–133: `runtimeScale n = n`. The bound becomes C·(L+1)^d·2^{A·n} with A existential, so brute force with A = 1 satisfies it. The statement is true but too weak to say anything subexponential. |

## Copy A: NO

- **Line 195** `∀ (n : ℕ), ∃ (machine : Computation.PrimitiveMachine) …` and **line 199** `∀ (F : SAT.CNF (Fin n))` (n is now bound outside). The machine, the tapes and `C A S d e` (lines 195–197) all depend on n.
- **Why this breaks the implication (S1 FAIL).** Fix n. There are only finitely many width-k CNFs over `Fin n`, so finitely many inputs `encodeCNF F`. Two ways to prove the statement trivially:
  - a machine with a lookup table indexed by these finitely many inputs (a finite trie over the input bits, then write the hard-wired count). It runs in O(L + n) steps and visits polynomial space;
  - any correct brute-force machine, with `C` chosen per n larger than its maximum running time over that finite set. The same goes for `S`.
- The statement therefore has no uniform-algorithm content and cannot refute ETH, which is about a single machine for all n.
- The docstring (lines 191–193, "One fixed primitive machine…") contradicts the statement as written.

## Copy B: NO

- **Line 33** `decide (∀ l ∈ C, l.eval a = true)`. Here `Clause.eval` is a conjunction, not the standard disjunction (`∃`).
- **Why this breaks the implication (S4 FAIL).** With line 36 (`CNF.eval` = ∀ clauses), `F.eval a` holds iff every literal occurring anywhere in F is true under `a`. That gives a polynomial-time rule:
  - `count F = 0` if F contains both `x` and `¬x` for some variable;
  - otherwise `count F = 2^{n − |vars(F)|}`. Its binary word has length ≤ n + 1, so it can be written in poly(L) time and space.
- A polynomial-time machine therefore satisfies everything in lines 194–217. The statement is (plausibly) provable without any SAT algorithm and says nothing about 3-SAT.
- Side effect: an empty clause now evaluates to `true` (vacuous ∀), which also departs from standard semantics.

## Copy D: NO

- **Lines 132–133** `noncomputable def runtimeScale (n : ℕ) : ℝ := (n : ℝ)`. The `(log log)²/√log` factor is gone.
- **Why this breaks the implication (S7 FAIL).** With line 209, the time bound is `C·(L+1)^d·2^{A·n}`, and `A > 0` is chosen existentially (lines 196–197). Brute force (enumerate all 2^n assignments, evaluate F, keep a binary counter) runs in 2^n·poly(L) time and poly(L) space. It satisfies the bound with A = 1. The statement is true but gives no 2^{o(n)} algorithm, and is fully consistent with ETH.
- The docstring (lines 190–192, "square-root-logarithmic time bound") no longer matches the definition.

## Copy C: YES (conditional)

### Bridge argument (k = 3)

1. Apply the theorem with k = 3 (`hk : 2 ≤ 3`). This gives one machine M, tapes, and constants C, A, d that depend only on k (lines 194–197).
2. Given a 3-CNF φ in any standard encoding, convert it in poly time to `F : CNF (Fin n)`: drop duplicates and compute the sorted unary `encodeCNF F` (lines 55–77). F has width ≤ 3 and `count F > 0` iff φ is satisfiable (S4).
3. Run M on `encodeCNF F`. By lines 199–200, 206 and 209–210, M halts after `time` steps in state `Sum.inl (decide (0 < count F))`, with `time ≤ C·(L+1)^d·2^{A·r(n)}`, where r(n) = n·(log log(n+16))²/√log(n+16) and L = |encodeCNF F|.
4. Each step of M reads one cell of one of its fixed number of tapes and moves or writes there (lines 107–119). A standard multitape TM simulates it with O(1) overhead per step.
5. r(n)/n → 0, so for every δ > 0 there is n₀ with A·r(n) ≤ δn for n ≥ n₀. Inputs with n < n₀ are covered by a constant.
6. L ≤ poly(n, L_std), and poly(n) ≤ 2^{δn}·O(1). So the total time is 2^{2δn}·poly(L_std) for every δ > 0, which means ETH is false.

### Checklist

- **S1 Uniformity: PASS.**
  - Lines 194–199: `∃ machine … C A S d e` comes before `∀ (n : ℕ) (F …)`, and only k is bound earlier.
  - Determinism: `step` is a function (line 107), so the trace of length `time` (line 200) is the unique run.
  - Halting time: `final` is in a halted state (line 206), and `step` returns `none` there (line 109). So `time` is exactly the halting time, not an arbitrary point after it.
- **S2 One step does O(1) work: PASS** on reading; compilation is OPEN.
  - `transition : Fin stateCount → Option Bool → …` (lines 98–99) is a finite table.
  - `scan q` picks exactly one tape (line 111). The action is `Turing.TM0.Stmt` = `move | write` only (excerpt PostTuringMachine.lean 115–123).
  - `Tape.move` and `Tape.write` (excerpt Tape.lean lines 49–51 and 82–83 of the excerpt file) each change O(1) cells.
  - `.inl answer` halts without touching the tapes (line 113). No step does unbounded work.
- **S3 Halting and output: PASS.**
  - Line 206: `final.config.state = Sum.inl (decide (0 < count F))`, and line 109 makes it halting.
  - Lines 202–203: the count tape equals `Tape.mk₁ (countWord (count F)).map some`. All its symbols are `some _` and the blank is `none` (excerpt line 84), so the tape holds exactly the word with the head at its start, and blanks elsewhere.
  - Line 207 pins `toNat ∘ countWord = id` on this value, so the bits are correct little-endian binary.
  - Lines 204–205 give the answer bit `0 < count`.
  - Minor note: if `countTape = answerTape`, the two equations together force count ≤ 1. That makes the statement harder to prove, not weaker. Not a defect for the implication.
- **S4 SAT semantics: PASS.**
  - Literals (line 30): `a v == positive`, i.e. true iff the assignment agrees with the polarity.
  - Clauses (line 33): ∃ a true literal, so the empty clause is false.
  - CNFs (line 36): ∀ clauses, so the empty CNF is true.
  - `count` (lines 44–47) counts `Fin n → Bool` assignments over `Finset.univ`. All standard.
- **S5 Coverage of 3-SAT: PASS.**
  - Clauses and CNFs are `Finset`s (lines 24–25). Collapsing duplicates gives an equivalent formula, and tautological clauses (x ∨ ¬x) are representable because `(v, true)` and `(v, false)` are distinct literals.
  - `WidthAtMost 3` (line 38) allows clauses of size ≤ 3, including the empty clause and the empty CNF. k = 3 satisfies `hk`.
- **S6 Encoding: PASS** on reading; one OPEN about compilation.
  - Canonical and injective:
    - `literalCode` = 2v + b (lines 64–65) is injective.
    - Clauses become sorted lists of codes (line 68), and the CNF becomes a sorted list of those lists (line 71). Sorting the image of an injective map determines the set.
    - n is prepended in unary (line 77).
    - The encoding is a function of F alone and leaks nothing about the answer.
  - Length:
    - A literal code is ≤ 2n+1, so its unary frame is O(n) bits. A clause is O(kn) bits.
    - The number of distinct width-≤3 clauses is m ≤ O((2n)³), so L = O(n⁴).
    - Also L ≥ n+1, from the unary n.
    - Standard → this format: unary expansion plus sorting, poly time. The unary n costs at most poly(n), which is absorbed into 2^{δn} (step 6 of the bridge).
  - OPEN: `Finset.sort (· ≤ ·)` on `List ℕ` (line 71) needs a total, antisymmetric, transitive, decidable order instance on `List ℕ` (presumably the lexicographic order). Whether it resolves at the pinned Mathlib can only be settled by compiling. If it does not compile, the question is moot.
- **S7 The bound is 2^{o(n)} in the right variable: PASS.**
  - Lines 132–134: r(n) = n·(log log(n+16))²/√log(n+16). r(n)/n = (log log)²/√log → 0. log(n+16) ≥ log 16 > 1, so every term is well-defined and positive.
  - Lines 136–139: C and A multiply/scale and are fixed per k. `(L+1)^d` has d fixed.
  - Line 210 passes the declared `n`, and F lives over `Fin n` (line 198), so F cannot use more variables than declared.
- **S8 The model is no stronger than a multitape TM: PASS.**
  - Fixed `tapeCount` with two-way infinite tapes over {none, some false, some true}, initialized as input on `inputTape` and blanks elsewhere (lines 121–124).
  - One tape is read and acted on per step. This is weaker than a standard multitape TM step (which reads all heads), so the simulation overhead is O(1).
  - No oracles: `transition` is an arbitrary function, but on a finite domain it is just a table.
- **S9 The space clause: PASS** (well-defined, not vacuous; not needed for ETH).
  - Lines 148–188 track per-tape head position and min/max visited cells. In `monitor`, the halting branch (line 171) leaves the counters unchanged.
  - The initial input extent is `input.length − 1` (line 158; ℕ subtraction is harmless since `encodeCNF` is nonempty).
  - Lines 211–216 bound `visitedSpace` by S·(L+1)^e at every prefix of the run. It is a real constraint, but it is irrelevant to the ETH implication.
- **S10 Match to `docs/378.md` and the paper: FLAG / OPEN.**
  - FLAG: the Lean bound n(log log n)²/√log n (lines 132–134) is weaker than the paper's n·log log n/√log n, as the checklist already records. It is still 2^{o(n)}, so the implication is unaffected.
  - The theorem also asks for exact #SAT counting and a space bound, which goes beyond what ETH needs.
  - OPEN: `docs/378.md` and the paper are not in this directory, so I cannot check any further mismatch.

Overall for C: no FAIL in S1–S8. Two items depend on compilation (S2, S6) and are OPEN only in that sense. The YES is about the implication, not about whether the theorem is true. If proved, it would refute ETH, and also give a subexponential #3-SAT algorithm.

## Textual differences between the copies

Copy C is the reference point for this list only. That is not a claim about which copy is published. A byte-level `diff` found these, and nothing else:

1. **C vs A** (2 hunks):
   - line 195: `∃ (machine …` → `∀ (n : ℕ), ∃ (machine …`
   - line 199: `∀ (n : ℕ) (F : SAT.CNF (Fin n)), …` → `∀ (F : SAT.CNF (Fin n)), …`
2. **C vs B** (1 hunk), line 33: `decide (∃ l ∈ C, l.eval a = true)` → `decide (∀ l ∈ C, l.eval a = true)`
3. **C vs D** (1 hunk), lines 133–134: the body `(n : ℝ) * (Real.log (Real.log ((n : ℝ) + 16))) ^ 2 / Real.sqrt (Real.log ((n : ℝ) + 16))` → `(n : ℝ)`.
   - D is therefore one line shorter, and every later line number in D is shifted by −1. For example, the theorem is at D line 193 versus 194 elsewhere.

Each of A, B and D differs from C in exactly one semantic change. A, B and D also differ pairwise by the union of their respective changes. The docstrings are identical in all four copies, so in A and D the docstring no longer describes the statement.
