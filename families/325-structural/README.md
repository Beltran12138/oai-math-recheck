# Family 325, fourth statement: StructuralCrouzeix

Upstream: [openai/math](https://github.com/openai/math) @
`adc7f1241b42e322a6451854ab7e4b4c146bf78a`
· statement `lean/ComparatorChallenges/StructuralCrouzeix.lean` (210 lines)
· proof `lean/OAI/Analysis/StructuralCrouzeix/` (12 files, 1 050 lines), built
on `lean/OAI/Analysis/NumericalRange/` (48 files, the development behind
[`../325-complete`](../325-complete))
· family page `lean/docs/325.md` ("Optimal similarity and boundary representation")
· preprint *The complete Crouzeix theorem: optimal similarity and a common
positive boundary representation*, 2026-09-23

## The claim

This is the structural result, not a bare inequality. For every bounded convex
domain `U` with a regular real-analytic Jordan boundary (`IsAdmissible U`),
every matrix `A` with numerical range inside `U`, and every conformal map `f`
of `U` onto the unit disk sending some chosen `a ∈ U` to `0` (a
`DiskCoordinate U a`), `FullEndpoint` asserts:

- there is a positive definite `H` minimising `τ` subject to
  `1 ≤ H ≤ τ` and `f(A)ᴴ H f(A) ≤ H`, attained at `τ = κ²` with `1 ≤ κ ≤ 2`;
- with `S = √H`, the similarity `S f(A) S⁻¹` is a contraction with spectral
  radius below 1, `‖S‖‖S⁻¹‖ = κ`, and no invertible `R` making `R f(A) R⁻¹` a
  contraction has a smaller condition number;
- one continuous positive-semidefinite matrix density `Λ` on the circle, of
  total mass the identity, represents `v(SAS⁻¹)` for every matrix-valued `v`
  analytic near the closure of `U`, in every coefficient dimension `m`;
- and `‖v(A)‖ ≤ κ · sup over closure U of ‖v‖`, so the complete bound with
  constant at most 2 on such domains.

The theorem also proves that the unit disk is admissible, and the conclusion
proves that the disk and exterior coordinates it quantifies over exist. So
none of the "for all" clauses is vacuous.

## Gate results

GitHub Actions, `ubuntu-24.04` x86_64, run
[37759685861](https://github.com/Beltran12138/oai-math-recheck/actions/runs/37759685861).
Logs in [`logs/ci-ubuntu-x86_64/`](logs/ci-ubuntu-x86_64).

```
    PASS  12/12 modules compiled (12 built this run), exit 0, wall 6m55s
'OAI.StructuralCrouzeixReference.challenge' depends on axioms: [propext, Classical.choice, Quot.sound]
    PASS  53 constants identical after elaboration (types, universe params, definition bodies)
    PASS  7/7 verbatim identical
    PASS  none of the above appear in OAI/Analysis/StructuralCrouzeix OAI/Analysis/NumericalRange
    PASS  all Lake packages match their pinned revisions
```

Gate E passes too. It loosens `κ ≤ 2` to `κ ≤ 3`, and its verdict names
`FullEndpoint` and an auxiliary proof inside it as the only constants that
differ. See `gates.log`.

Gate A counts the 12 modules of this family's own directory. The 48 modules
of `NumericalRange/` are compiled in the same build (`build.log` has a
`Built` line for each), and gate A checks them separately in
[`../325-complete`](../325-complete). Gate F scans both directories.

### What it took

The proof imports seven `NumericalRange` modules, and the dependency check
refused the family, as it should for anything outside its own directory and
Mathlib. `family.conf` now declares that directory in `EXTRA_DIRS`. A declared
directory is fetched, copied, added to the Lake globs, held to the same import
rule, and scanned by gate F. Without the declaration the family is still
refused; we checked that offline (seven imports reported).

### Second architecture

The same configuration also passes every gate on an Apple M4 (arm64,
macOS 26.5.2), from a fresh clone at `d9e35dc`. Logs are in
[`logs/apple-m4-arm64/`](logs/apple-m4-arm64). The statement dump there is
byte-identical to the x86_64 one, with the same sha256 in both `PROVENANCE`
files: two machines of different architectures elaborate the challenge to
exactly the same terms.

## Reading the statement

What we read, and what we found:

- `IsAdmissible`: open, bounded, convex, nonempty, a homeomorphism from the
  circle onto the frontier, and at every frontier point a local analytic
  chart with non-zero derivative straightening the frontier to the real axis.
  That is the hypothesis the family page states.
- `matrixAnalyticEval` is the holomorphic functional calculus written out:
  split `ℂⁿ` into generalised eigenspaces and, on each, take the Taylor jet
  of `f` at the eigenvalue against the nilpotent part, to order `finrank`,
  which is enough for any nilpotent on that space.
- `completeAnalyticEval D F` has entry `((i,a),(j,b)) = F_ab(D)_ij`, the base
  index first, the same order as `Λ t ⊗ₖ v(…)` in the representation.
- `≤` on matrices is the Loewner order (the dump shows
  `Matrix.instPreOrder`), and `‖·‖` is the L2 operator norm.
- `MetricFeasible` is declared in a section with a `[Nonempty n]` variable,
  while `IsMinimizing` uses it at `Fin n` for every `n`, including `0`. The
  dump settles this: the elaborated `MetricFeasible` takes only `Fintype` and
  `DecidableEq` instances. The unused `Nonempty` variable never entered its
  signature, so nothing is wrong, but it took the dump, not the source, to
  show it.

## Limits

1. **Faithfulness is a human judgement**, ours, over a 210-line statement.
   The reading above found nothing wrong. A reader who knows the structural
   preprint is better placed to judge it than this harness.
2. Not run under `comparator`'s sandbox; the preprint's proof not checked.

## Files

| file | what it is |
|---|---|
| [`family.conf`](family.conf) | configuration, including `EXTRA_DIRS=OAI/Analysis/NumericalRange` |
| [`logs/ci-ubuntu-x86_64/`](logs/ci-ubuntu-x86_64) | actual output of the run above, the challenge dump (gzipped) and its sha256 |
