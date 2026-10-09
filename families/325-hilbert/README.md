# Family 325, second statement: complete Crouzeix on arbitrary Hilbert spaces

Upstream: [openai/math](https://github.com/openai/math) @
`adc7f1241b42e322a6451854ab7e4b4c146bf78a` (unchanged at `fd4aeeb`, 2026-10-08)
· statement `lean/ComparatorChallenges/CrouzeixHilbert.lean`
· proof `lean/OAI/Analysis/Crouzeix/` (90 files, 15 655 lines)
· family page `lean/docs/325.md`, which links five comparator files for this
family. [`../325`](../325) covers `DirectCrouzeix`; this page covers
`CrouzeixHilbert`, and [`../325-complete`](../325-complete) covers
`CompleteCrouzeix`, and [`../325-structural`](../325-structural) covers
`StructuralCrouzeix`.

## Why this statement

`DirectCrouzeix` states the bound for matrix-valued *polynomials* evaluated at
a *matrix*. The operator-algebra definition in the literature, "W(A) is a
complete 2-spectral set for A", is tested on matrix-valued *rational*
functions, and [the top-level README](../../README.md) said the step from one
to the other was our own argument (polynomial approximation), checked by
nothing.

`CrouzeixHilbert` states it in that form directly. For a bounded operator `A`
on any complex Hilbert space `H` with `Nontrivial H`, part of
`NonzeroConclusion A` reads, verbatim:

```lean
  (∀ (m : ℕ), 0 < m → ∀ (R : RationalMatrix m),
    PolesOutside (numericalClosure A) R →
    (∀ i j, IsUnit (Polynomial.aeval A (R i j).denom)) ∧
    ‖matrixRationalEval A R‖ ≤
      2 * supNorm (numericalClosure A) (matrixRationalFunction R) ∧
```

where `matrixRationalEval A R` is `∑ i j, rᵢⱼ(A) ⊗ Eᵢⱼ`, the block operator
`[rᵢⱼ(A)]` on `H ⊗ ℂᵐ`. The same conclusion has the bound for matrix-valued
polynomials and for matrix functions holomorphic near the closure of the
numerical range. So for this statement the polynomial-approximation step is
not needed: rational functions are in the formal statement, and the proof of
it compiles.

## Gate results

GitHub Actions, `ubuntu-24.04` x86_64, run
[37751095037](https://github.com/Beltran12138/oai-math-recheck/actions/runs/37751095037).
Logs in [`logs/ci-ubuntu-x86_64/`](logs/ci-ubuntu-x86_64).

```
    PASS  90/90 modules compiled (90 built this run), exit 0, wall 7m10s
'OAI.CrouzeixHilbert.hilbert' depends on axioms: [propext, Classical.choice, Quot.sound]
    PASS  46 constants identical after elaboration (types, universe params, definition bodies)
    PASS  assert: OAI.CrouzeixHilbert.Amplification uses TensorProduct.instNormedAddCommGroup
    PASS  24/24 verbatim identical
    PASS  none of the above appear in OAI/Analysis/Crouzeix
    PASS  all Lake packages match their pinned revisions
```

Gate E (the negative control) also passes. Its verdict line names the
constants that differ, `NonzeroConclusion` and an auxiliary proof inside it,
which is exactly the definition the control perturbs. See `gates.log`.

### How gate C works here

[`../325`](../325) checks the statement by copying the challenge's definitions
into our own file and asking Lean whether the two statements are
definitionally equal. That cannot work here. The statement contains two
`structure`s (`SmoothContour`, `CalculusContour`), and a structure declared
again in our file is a new type, never equal to OpenAI's.

So gate C does what `comparator` does.
[`tools/StatementDump.lean`](../../tools/StatementDump.lean) imports the
challenge module in one process and the solution module in another. Starting
from the theorem's type, it walks to every `OAI.*` constant the statement
depends on and writes out each one's kind, universe parameters, type and, for
definitions, body. Theorem bodies are never followed. The two dumps must be
identical, non-empty, and contain the headline theorem. Here they are 46 lines
each and byte-identical (sha256 in `PROVENANCE`).

The dump also settles one point that reading the statement left open. The
amplified space is `UniformSpace.Completion (H ⊗[ℂ] EuclideanSpace ℂ (Fin m))`,
and the complete inequality needs the Hilbert tensor norm on `H ⊗ ℂᵐ`, not the
projective one. The pinned Mathlib has only one normed instance on algebraic
tensor products, the one induced by the inner product
(`Mathlib/Analysis/InnerProductSpace/TensorProduct.lean`). The `DUMP_ASSERT`
line above checks that the challenge's own elaborated `Amplification` uses
that instance. It checks the term as OpenAI's file elaborated it, not a
re-derivation of ours.

### What building this gate found

All three problems were in our harness. OpenAI's 90 files compiled on the
first run.

| found by | what was wrong |
|---|---|
| the first offline test, on a toy project | Both dumps were empty because the toy library had not been built, and the diff of two empty files read "IDENTICAL". Gate C now requires a non-empty dump that contains every headline theorem. |
| gate D, before the first CI run | A declaration was taken to end at the next blank line. The challenge writes `abbrev Operator` and `abbrev Coeff` on adjacent lines, so the two were captured as one and reported as a false DIFFERS. A declaration now ends at a blank line or at the next line starting in column 0. |
| the first CI run (37749936010) | Gate C reported 26 constants as different, among them the one-line `abbrev Operator`. An anonymous instance binder gets a generated name that embeds the module it was elaborated in (`inst._@.ComparatorChallenges.CrouzeixHilbert.…` against `inst._@.OAI.Analysis.Crouzeix.Definitions.…`), and the dump wrote binder names out. Lean's own `Expr` equality ignores binder names, and the dump now erases them. Gate E passed on that same run, but only because of the same noise, so that pass counts for nothing. |

### Second architecture

The same configuration also passes every gate on an Apple M4 (arm64,
macOS 26.5.2), from a fresh clone at `d9e35dc`. Logs are in
[`logs/apple-m4-arm64/`](logs/apple-m4-arm64). The statement dump there is
byte-identical to the x86_64 one, with the same sha256 in both `PROVENANCE`
files: two machines of different architectures elaborate the challenge to
exactly the same terms.

## What is still open

1. **Faithfulness is still a human judgement**, although this statement leaves
   less to judge. We read these points and found nothing wrong:
   - `supNorm` takes the `sSup` of `insert 0 (…)`. Norms are non-negative, so
     the inserted `0` only matters when the set is empty, which it is not for
     `Nontrivial H`.
   - `rationalEval` uses `Ring.inverse`, which returns `0` on a non-unit. The
     conclusion separately proves that every denominator is a unit
     (`IsUnit (Polynomial.aeval A (R i j).denom)`), so that branch never
     applies.
   - `holomorphicEval` picks a contour with `Classical.choice`. The conclusion
     proves that the value does not depend on which contour is picked.
   - The rational and holomorphic bounds take the supremum over the *closure*
     of the numerical range, with poles required to lie outside that closure.
     That is the standard condition.
   - `CompleteSpace H` is assumed, and nothing else (no separability).
2. **We did not run `comparator`.** Gate C reimplements its comparison, but
   without its sandbox and without its `permitted_axioms` enforcement (gate B
   covers axioms separately).
3. **We did not check either preprint's proof**, only the Lean.

## Files

| file | what it is |
|---|---|
| [`family.conf`](family.conf) | configuration read by `../../recheck.sh` and `../../audit.sh` |
| [`logs/ci-ubuntu-x86_64/`](logs/ci-ubuntu-x86_64) | actual output of the run above, the challenge dump (gzipped) and its sha256 |
