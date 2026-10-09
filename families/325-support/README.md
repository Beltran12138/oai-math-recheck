# Family 325, fifth comparator file: HilbertCrouzeix (support)

Upstream: [openai/math](https://github.com/openai/math) @
`adc7f1241b42e322a6451854ab7e4b4c146bf78a`
· statement `lean/ComparatorChallenges/HilbertCrouzeix.lean`
· proof `lean/OAI/Analysis/HilbertCrouzeix/` (7 files, 844 lines)
· family page `lean/docs/325.md`, which labels this file "Numerical-range
geometry and finite-compression support"

## What it states

Four supporting theorems about a bounded operator `A` on a complex Hilbert
space:

- `numericalClosure_geometry`: the closure of the numerical range is compact
  and convex and contains the spectrum.
- `exists_finite_compression`: for a matrix polynomial and any vector of the
  algebraic tensor product, there is a finite-dimensional subspace on which the
  compressed operator reproduces the action. This is the step that lets a
  Hilbert-space statement be reduced to matrices.
- `rational_denominator_isUnit`: if the poles of a rational matrix lie outside
  the closure of the numerical range, every denominator evaluated at `A` is
  invertible.
- `zeroConclusion`: the trivial case `[Subsingleton H]`, where every operator
  is zero.

None of these is the Crouzeix inequality. Read alone, `zeroConclusion` could
suggest that only a trivial case was proved, which is why the family page's
"support" label matters. The headline statements are in
[`../325`](../325), [`../325-hilbert`](../325-hilbert),
[`../325-complete`](../325-complete) and
[`../325-structural`](../325-structural). This one is rebuilt so that every
comparator file of the family is.

## Gate results

GitHub Actions, `ubuntu-24.04` x86_64, run
[37774827283](https://github.com/Beltran12138/oai-math-recheck/actions/runs/37774827283).
Logs in [`logs/ci-ubuntu-x86_64/`](logs/ci-ubuntu-x86_64).

```
    PASS  7/7 modules compiled (7 built this run), exit 0, wall 0m40s
    PASS  4/4 theorems: [propext, Classical.choice, Quot.sound], no sorry
    PASS  54 constants identical after elaboration (types, universe params, definition bodies)
    PASS  23/23 verbatim identical
    PASS  none of the above appear in OAI/Analysis/HilbertCrouzeix
    PASS  all Lake packages match their pinned revisions
```

Gate E weakens "the spectrum lies in the closure of the numerical range" to
"lies in the numerical range" in the first theorem. Its verdict names
`numericalClosure_geometry` as the only constant that differs.

### Second architecture

The same configuration also passes every gate on an Apple M4 (arm64,
macOS 26.5.2), from a fresh clone at `d9e35dc`. Logs are in
[`logs/apple-m4-arm64/`](logs/apple-m4-arm64). The statement dump there is
byte-identical to the x86_64 one, with the same sha256 in both `PROVENANCE`
files: two machines of different architectures elaborate the challenge to
exactly the same terms.

## Files

| file | what it is |
|---|---|
| [`family.conf`](family.conf) | configuration read by `../../recheck.sh` and `../../audit.sh` |
| [`logs/ci-ubuntu-x86_64/`](logs/ci-ubuntu-x86_64) | actual output of the run above, the challenge dump (gzipped) and its sha256 |
