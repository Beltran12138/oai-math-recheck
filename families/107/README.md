# Family 107: matrix multiplication with exponent at most 9/4

Upstream: [openai/math](https://github.com/openai/math) @
`adc7f1241b42e322a6451854ab7e4b4c146bf78a`
· statement `lean/ComparatorChallenges/MatrixMultiplication.lean`
· proof `lean/OAI/LinearAlgebra/MatrixMultiplication/` (509 files, 83,302 lines)
· family page `lean/docs/107.md`, which links two comparator files. This
configuration checks the complex one. `MatrixFields.lean`, the bound
`ω(F) < 2.371054886006746` over every field, is not checked here.

## What it states

Three theorems about the arithmetic complexity of matrix multiplication over
`ℂ`:

- `complex_omega_le_nine_quarters`: `ω(ℂ) ≤ 9/4`.
- `complex_alpha_gt_93_div_200`: the dual exponent `α` exceeds `0.465`.
- `complex_rectangular_omega_lt_523_div_250`: `n × n^0.709` by
  `n^0.709 × n` multiplication has exponent below `2.092`.

The model is finite division-free straight-line programs; additions,
subtractions and multiplications cost 1, constants and inputs cost 0. `ω` is
the infimum of exponents `τ` such that for every `ε > 0` some constant `C`
bounds the cost of a correct `n × n` program by `C · n^(τ+ε)` at every size.
This is arithmetic complexity, not bit complexity, and says nothing about
practical crossover sizes; the family page says the same.

## The part a statement could get wrong

`ω` is defined with `sInf` over the reals
(`MatrixMultiplication.lean` line 95). In Lean, `sInf` of an empty set or of a
set unbounded below is `0`, so a careless definition would make `ω ≤ 9/4` true
for free. Here the set is non-empty (the schoolbook algorithm gives `3`) and
bounded below by `0` (every program at every size costs at least 1), so the
junk value is never reached and the theorem means what it says.

## A dependency that is not the one its authors published

This is the first family here whose proof is not Mathlib-only. The 9/4 path
(`AuxiliarySeparation/Convex/FixedPoint.lean`) imports Brouwer's fixed point
theorem from
[harfe/fixed-point-theorems-lean4](https://github.com/harfe/fixed-point-theorems-lean4)
at `770940ddf9878cf61952ed53d910b92bca841838`, the rev upstream's manifest
pins. `family.conf` declares it in `EXTRA_REQUIRES`.

At that rev the library targets Lean and Mathlib v4.32.0 and does not compile
against the Mathlib OpenAI uses. Upstream never builds it as its author left
it: upstream's lakefile applies `lean/patches/fixed-point-theorems-lean4341.patch`
first (7 files, 78 insertions, 111 deletions). We read the patch. It re-pins
the library to Mathlib `d13f23b` and Lean v4.34.1 and repairs proofs;
the statements in `brouwer.lean` are unchanged. `recheck.sh` applies the same
patch from the same pinned commit, and gate F checks that undoing exactly that
patch leaves the library's tree clean.

This is a question of provenance, not of soundness. The patched library is
compiled and kernel-checked like everything else, and gate B follows axioms
through it. But "depends on harfe's library" is not accurate. "Depends on
OpenAI's patched copy of harfe's library" is. Upstream's `lean/patches/`
holds 24 such patches.

## Gate results

GitHub Actions, `ubuntu-24.04` x86_64, run
[38141681690](https://github.com/Beltran12138/oai-math-recheck/actions/runs/38141681690).
Logs in [`logs/ci-ubuntu-x86_64/`](logs/ci-ubuntu-x86_64).

```
    PASS  509/509 modules compiled (509 built this run), exit 0, wall 8m24s
    PASS  3/3 theorems: [propext, Classical.choice, Quot.sound], no sorry
    PASS  46 constants identical after elaboration (types, universe params, definition bodies)
    PASS  none of the above appear in OAI/LinearAlgebra/MatrixMultiplication 
    PASS  all Lake packages match their pinned revisions
```

The last line is inaccurate for this family, and the log above it says so
(`patched: fixed-point-theorems, exactly upstream's patch and nothing else`).
The wording predates patch support; `audit.sh` now reports patched packages by
name in the verdict itself.

Gate E changes `9/4` to `8/4` in a copy of the challenge. Its verdict names
`complex_omega_le_nine_quarters` as the constant that differs. Gate D is
skipped: the statement is checked by elaboration (gate C).

## Two runs that failed first, both on our side

| run | what stopped it | fixed in |
|---|---|---|
| [38139197748](https://github.com/Beltran12138/oai-math-recheck/actions/runs/38139197748) | `lake exe cache get` refused: the library pulled `batteries`, `aesop`, `Qq` … at its own revs. Lake lets the *last* `require` win shared packages, and `recheck.sh` wrote Mathlib first. | `17874b5` |
| [38140410158](https://github.com/Beltran12138/oai-math-recheck/actions/runs/38140410158) | The library itself failed to compile, because it was built unpatched. | `c4ac1c9` |

Neither was a problem in OpenAI's proof, which compiled on the first run that
built it as upstream does.

## What this does and does not show

It shows that OpenAI's 509 files and the patched library compile against the
Mathlib they pin, that the three theorems proved are the comparator
statements, and that they rest on no axiom beyond Lean's standard three.

It does not show that the construction is understood, that it matches the
accompanying papers, or anything about running time in practice.

## Files

| file | what it is |
|---|---|
| [`family.conf`](family.conf) | configuration read by `../../recheck.sh` and `../../audit.sh` |
| [`logs/ci-ubuntu-x86_64/`](logs/ci-ubuntu-x86_64) | actual output of the run above, the challenge and negative-control dumps (gzipped) and their sha256 |
