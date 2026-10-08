# oai-math-recheck

Re-check individual result families from [openai/math](https://github.com/openai/math)
yourself, without building the other 721 manuscripts.

On 2026-10-06 OpenAI published 722 mathematical manuscripts, many with Lean
formalisations. The repository ships **no CI** — its only GitHub workflow is
dependabot — and its own `formalization.yaml` records `review: unchecked`.
The formalisations are there; nothing in the repository demonstrates that any
of them compiles, let alone that it proves the stated theorem.

Checking one yourself is harder than it should be, for a mundane reason:
`lean/lakefile.toml` upstream `require`s around thirty external repositories
(`carleson`, `SphereEversion`, `ClassFieldTheory`, `lana-agents/iut`, …) behind
a patch mechanism. Most families need none of them. This repository strips the
build down to the family you actually want.

```bash
./recheck.sh 325     # fetch, build, and audit result family 325
```

## Worked example: family 325

[→ full write-up, including what the claim is and is not](families/325/README.md)

| gate | what it establishes | result |
|---|---|---|
| A | OpenAI's 42 files compile against the Mathlib they pin | **42/42, exit 0**, 36m48s wall |
| B | the two headline theorems use no axiom beyond the standard three | **`[propext, Classical.choice, Quot.sound]`**, no `sorryAx` |
| C | what is proved is the statement in the comparator challenge file | **pass** (definitional equality) |
| D | the definitions we re-declared to make gate C possible are verbatim the challenge's | **5/5 identical** |
| E | gate C is not vacuous — a wrong constant is rejected | **pass** (type mismatch at `c = 1`) |
| F | nothing skips the kernel; dependencies are untouched | **pass** (0 `set_option`, 0 custom axioms, all packages clean) |

Plus one thing beyond reproducing their build. Their theorem is stated for
*matrix*-coefficient polynomials, which is not a statement you can check by
eye, so [`families/325/Scalar.lean`](families/325/Scalar.lean) derives the
textbook scalar statement from it — machine-checked, axiom-clean:

```lean
theorem scalar_crouzeix {n : ℕ} (hn : 0 < n) (A : Matrix (Fin n) (Fin n) ℂ)
    (p : Polynomial ℂ) :
    ‖(Polynomial.aeval A) p‖ ≤ 2 * sSup ((fun z => ‖p.eval z‖) '' numericalRange A)
```

## What family 325 actually claims — read this before quoting any of it

The headline going around is that OpenAI resolved Crouzeix's conjecture. That
is not what family 325 says, and OpenAI does not say it either. From their own
bibliography:

- **The scalar Crouzeix conjecture was settled by humans two months earlier.**
  Lorist and Schwenninger, *A solution to Crouzeix's conjecture*,
  [arXiv:2608.03841v2](https://arxiv.org/abs/2608.03841), 2026-08-17 (7 pages),
  with Jin (2026-08-07) and Luo (2026-08-28) also claiming proofs. Crouzeix and
  Greenbaum's own [2026-09-18 update](https://arxiv.org/abs/2609.22460) to
  their survey builds on Lorist–Schwenninger, which is uptake by the people
  closest to the problem. OpenAI cites all of this — Lorist–Schwenninger is
  reference **[14]** in their preprint.
- **What OpenAI claims is the *complete* version**: the same constant 2,
  uniformly in the coefficient dimension `m`, with the base dimension `n`
  unrestricted. Their one novelty sentence is precise about it: *"The scalar
  results fix m = 1, while the latter complete result restricts the base
  dimension; Theorem 1.1 leaves these dimensions independent."* The previous
  complete results stopped at `n = 2` (Badea–Crouzeix–Delyon, 2006) and
  `n ≤ 3` (Åhag–Czyż–Virtanen, [arXiv:2608.27346](https://arxiv.org/abs/2608.27346),
  2026-08).
- **The complete version does not follow from the scalar one.** OpenAI points
  at Lorist–Schwenninger's own §3(iv) for why the commutation their proof uses
  does not survive amplification to matrix coefficients.

So the honest one-liner is: *a claimed proof of the matrix-coefficient
strengthening of a conjecture whose scalar case humans had just settled, and
its Lean formalisation compiles and is axiom-clean.* Narrower than the
headline, and real.

This also fixes the standing of `Scalar.lean`. It is a **consistency check
against an independently known theorem**: a short, plainly-stated, hard result
falls out of their machinery, which is good evidence that `UniversalBound` is
not a mis-formalisation stating something vacuous. It is **not** evidence about
the novel part — uniformity in `m` — and nothing here is. For that you have to
read `UniversalBound` and decide for yourself.

## What these gates do and do not show

They show that the Lean development in family 325 compiles, contains no `sorry`,
introduces no axiom, does not disable the kernel, and proves a proposition
definitionally equal to the one in the comparator challenge file.

They are **not** a verdict on the mathematics. Three gaps remain:

1. **Whether the formal statement faithfully renders the informal conjecture is
   a human judgement.** We checked what could be checked mechanically: the norm
   is Mathlib's L2 operator norm (`Matrix.instL2OpNormedRing`, pinned down by
   `‖I₂‖ = 1`, which the Frobenius norm fails), `numericalRange` is the textbook
   `{⟪u, Au⟫ : ‖u‖ = 1}`, and its 1×1 case is exactly `{A 0 0}` — the direction
   that matters, since a numerical range that were *too large* would raise the
   supremum and make the theorem *weaker*.
2. **This is not `comparator`.** OpenAI's own checker runs a solution against a
   challenge inside a `landrun` sandbox with an explicit `permitted_axioms`
   list; it needs Linux Landlock and `systemd-run`, and we did not run it. Our
   provenance claim is the weaker, more boring one: the files come from
   upstream at a pinned commit SHA.
3. **A machine-checked proof is a proof of the formal statement**, and the
   interesting question for family 325 is whether the formal statement is the
   mathematical one. Gate B is close to decisive about the first. Nothing is
   decisive about the second.

We have not searched for other independent reproductions and claim no priority.

Two facts that run in OpenAI's favour and belong next to the caveats: across
all 405 comparator statements in the repository, not one relaxes
`permitted_axioms` beyond the standard three; and the preprint's literature
review is scrupulous about what was already known and by whom.

## Running it

Needs `git`, `python3`, `bash`, and [`elan`](https://github.com/leanprover/elan).
Expect to download roughly 5 GB of Mathlib `.olean` files on first use, and to
want appreciably more than 8 GB of RAM: a single `import Mathlib` maps about
5.5 GB. The upstream fetch is a partial clone, so it pulls about 26 MB rather
than the repository's 780 MB.

```bash
./recheck.sh 325                       # fetch + build + audit
./audit.sh 325                         # re-run just the gates
UPSTREAM_SHA=<sha> ./recheck.sh 325    # pin a different upstream commit
```

Timing, for calibration (Apple M4, 10 cores, 16 GB, macOS 26.5.2): 42 files,
about 50 s each, built serially — 36m48s wall. The wall clock is dominated by
re-loading Mathlib's `.olean` files once per file, not by checking the proof,
so a machine with more memory should do noticeably better.

## Adding a family

Create `families/<n>/family.env` (copy
[325's](families/325/family.env), it is commented) and run `./recheck.sh <n>`.

If the family imports anything outside Mathlib, `recheck.sh` stops and says
what. That is a result, not an obstacle: it means that family cannot be checked
without the upstream dependency tangle, and it is worth reporting.

Gates D and E only apply to families where someone has hand-written a
`Verify.lean`. Without one you get gates A, B and F, which is already more than
the repository currently demonstrates about itself.

## Licence

Apache-2.0, matching upstream. This repository contains no OpenAI code; see
[NOTICE](NOTICE).
