# Family 325, third statement: CompleteCrouzeix, and a cross-check

Upstream: [openai/math](https://github.com/openai/math) @
`adc7f1241b42e322a6451854ab7e4b4c146bf78a`
· statement `lean/ComparatorChallenges/CompleteCrouzeix.lean`
· proof `lean/OAI/Analysis/NumericalRange/` (48 files, 14 195 lines)
· family page `lean/docs/325.md` ("Complete polynomial inequality and sharpness")

## The same inequality, proved twice

`CompleteCrouzeix.lean` states the same inequality as
[`DirectCrouzeix.lean`](../325): matrix `A`, matrix-coefficient polynomial,
Kronecker evaluation, L2 operator norm, constant 2, sharpness. The spelling
differs (the binder is `x` rather than `u`, `Matrix.kronecker` is written out
rather than as the `⊗ₖ` notation, `ComplexOrder` is opened) and so do the
names (`polynomialAt` for `tensorEvaluation`, one theorem `main` for two). The
proof is a separate development, 48 files in `NumericalRange/` against 42 in
`DirectCrouzeix/`.

So besides the usual gates there is a question we can put to Lean directly:
does this proof close the other challenge's statement?
[`Verify.lean`](Verify.lean) copies DirectCrouzeix's five definitions verbatim,
and gate D diffs them against `ComparatorChallenges/DirectCrouzeix.lean`. It
then asks:

```lean
example : UniversalBound 2 := OAI.CompleteCrouzeix.main.1
example (c : ℝ) (hc : UniversalBound c) : 2 ≤ c := OAI.CompleteCrouzeix.main.2 c hc
```

Both compile. Up to definitional unfolding, the two developments prove one
proposition.

## Gate results

GitHub Actions, `ubuntu-24.04` x86_64, run
[37755867541](https://github.com/Beltran12138/oai-math-recheck/actions/runs/37755867541).
Logs in [`logs/ci-ubuntu-x86_64/`](logs/ci-ubuntu-x86_64).

```
    PASS  48/48 modules compiled (48 built this run), exit 0, wall 5m36s
'OAI.CompleteCrouzeix.main' depends on axioms: [propext, Classical.choice, Quot.sound]
    PASS  10 constants identical after elaboration (types, universe params, definition bodies)
    PASS  Verify built; the defeq checks inside them went through
✔ [8972/8973] Built Verify (3.5s)
    PASS  5/5 verbatim identical
    PASS  none of the above appear in OAI/Analysis/NumericalRange
    PASS  all Lake packages match their pinned revisions
```

`Built Verify (3.5s)` is the line that shows the cross-check was compiled in
this run rather than taken from a cache. Gate E also passes, and its verdict
names `OAI.CompleteCrouzeix.UniversalBound` as the one constant that differs,
which is the definition the control perturbs.

Gate C runs two checks here. The dump compares this challenge with this
solution, the way [`../325-hilbert`](../325-hilbert) does. `Verify.lean` is the
cross-check against DirectCrouzeix.

## Limits

1. **Gate E covers only the dump.** It weakens this challenge's bound and
   requires the dump to notice. The cross-check `example`s have no negative
   control of their own in this configuration. The same method (copy the
   definitions, ask for definitional equality) is shown to reject a wrong
   constant in [`../325`](../325), gate E.
2. **Agreement between two OpenAI developments is not independence from
   OpenAI.** It shows that the two formalisations prove the same proposition.
   It says nothing about whether that proposition is the intended one; both
   challenge files come from the same source. See
   [`../325-hilbert`](../325-hilbert) for the form with rational functions.
3. Not run under `comparator`'s sandbox; neither preprint's proof checked.

## Files

| file | what it is |
|---|---|
| [`family.conf`](family.conf) | configuration read by `../../recheck.sh` and `../../audit.sh` |
| [`Verify.lean`](Verify.lean) | the cross-check: DirectCrouzeix's statement, closed by this proof |
| [`logs/ci-ubuntu-x86_64/`](logs/ci-ubuntu-x86_64) | actual output of the run above, the challenge dump (gzipped) and its sha256 |
