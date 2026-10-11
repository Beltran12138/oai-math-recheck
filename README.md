# oai-math-recheck

[![recheck](https://github.com/Beltran12138/oai-math-recheck/actions/workflows/recheck.yml/badge.svg)](https://github.com/Beltran12138/oai-math-recheck/actions/workflows/recheck.yml)

Re-check individual result families from [openai/math](https://github.com/openai/math)
yourself, without building every other manuscript.

On 2026-10-06 OpenAI published 722 mathematical manuscripts, many with Lean
formalisations (719 after three withdrawals on 2026-10-07; see upstream
`history.md`). The repository ships **no CI** — its only GitHub workflow is
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

Run twice, on two architectures, with every gate passing both times: once on an
Apple M4 (arm64, macOS 26.5.2) and once on a GitHub-hosted `ubuntu-24.04`
runner (x86_64, 7 GB RAM) — the badge above is that second run, and its log is
public.

| gate | what it establishes | result |
|---|---|---|
| A | OpenAI's 42 files compile against the Mathlib they pin | **42/42 `.olean` on disk, exit 0**, 36m48s / 5m29s wall |
| B | the two headline theorems use no axiom beyond the standard three | **`[propext, Classical.choice, Quot.sound]`**, no `sorryAx` |
| C | what is proved is the statement in the comparator challenge file | **pass** (definitional equality) |
| D | the definitions we re-declared to make gate C possible are verbatim the challenge's | **5/5 identical** |
| E | gate C is not vacuous — a wrong constant is rejected | **pass** (type mismatch at `c = 1`) |
| F | nothing skips the kernel; dependencies are untouched | **pass** (0 `set_option`, 0 custom axioms, all packages clean) |
| G | every log line the write-up quotes is really in the archived logs | **pass** (4/4 verbatim) |

Plus one thing beyond reproducing their build. Their theorem is stated for
*matrix*-coefficient polynomials, which is not a statement you can check by
eye, so [`families/325/Scalar.lean`](families/325/Scalar.lean) derives the
textbook scalar statement from it — machine-checked, axiom-clean:

```lean
theorem scalar_crouzeix {n : ℕ} (hn : 0 < n) (A : Matrix (Fin n) (Fin n) ℂ)
    (p : Polynomial ℂ) :
    ‖(Polynomial.aeval A) p‖ ≤ 2 * sSup ((fun z => ‖p.eval z‖) '' numericalRange A)
```

### Second statement in the same family: `CrouzeixHilbert`

[→ write-up](families/325-hilbert/README.md)

`lean/docs/325.md` links five comparator files for family 325, and only one of
them is labelled support. The table above is about `DirectCrouzeix`.
[`families/325-hilbert`](families/325-hilbert) rebuilds a second one,
`CrouzeixHilbert`: 90 files, every gate passing on GitHub Actions run
[37751095037](https://github.com/Beltran12138/oai-math-recheck/actions/runs/37751095037).
Its statement is for bounded operators on any complex Hilbert space and covers
matrix-valued rational and holomorphic functions, the form the literature
uses. The statement contains `structure`s, so gate C there compares the
elaborated challenge and solution the way `comparator` does
([`tools/StatementDump.lean`](tools/StatementDump.lean)) instead of by copy and
defeq.

### Third statement: `CompleteCrouzeix`, cross-checked

[→ write-up](families/325-complete/README.md)

`CompleteCrouzeix` states the same inequality as `DirectCrouzeix`, spelled
differently, and OpenAI proves it in a separate 48-file development.
[`families/325-complete`](families/325-complete) rebuilds it (every gate
passing, run
[37755867541](https://github.com/Beltran12138/oai-math-recheck/actions/runs/37755867541))
and also asks Lean whether that proof closes `DirectCrouzeix`'s challenge
statement, copied verbatim. It does: the two developments prove one
proposition up to definitional unfolding. That is agreement between two OpenAI
formalisations, not independence from OpenAI.

### Fourth statement: `StructuralCrouzeix`

[→ write-up](families/325-structural/README.md)

The structural result: optimal similarity with condition number at most 2 and
one positive boundary density representing the calculus, for matrices whose
numerical range lies in a convex domain with real-analytic boundary. Its
12-file proof is built on the `NumericalRange` development, which the
dependency check refused until `family.conf` declared it in `EXTRA_DIRS`.
Every gate passes (run
[37759685861](https://github.com/Beltran12138/oai-math-recheck/actions/runs/37759685861)).

That covers all four substantive comparator statements of family 325. The
fifth comparator file, `HilbertCrouzeix`, is the one the family page labels as
support: four lemmas, one of them the zero-space case. It is rebuilt too, in
[`families/325-support`](families/325-support/README.md) (run
[37774827283](https://github.com/Beltran12138/oai-math-recheck/actions/runs/37774827283)),
so every comparator file of family 325 now has a passing re-check.

## More families: Unique Games (102), ω ≤ 9/4 (107), L = BPL (103)

Both pass every gate that applies, in run
[38141681690](https://github.com/Beltran12138/oai-math-recheck/actions/runs/38141681690).
Each write-up says what the statement is, where it could have gone wrong, and
what a pass does not show.

- [**102**](families/102/README.md), the headline Unique Games statement:
  478 files, 187k lines. NP-hardness is only meaningful if the reduction is
  restricted, so gate C additionally asserts that it is Mathlib's
  `TM2ComputableInPolyTime`, plus a finite-alphabet condition Mathlib's
  `FinTM2` leaves out and the statement adds itself.
- [**107**](families/107/README.md), `ω(ℂ) ≤ 9/4` and two rectangular bounds:
  509 files. The first family here that is not Mathlib-only, and the
  dependency is not as its author published it. The 9/4 path uses Brouwer's
  theorem from harfe/fixed-point-theorems-lean4, which upstream builds only
  after applying its own compatibility patch. `recheck.sh` applies the same
  patch and gate F checks it is the only change. That is a provenance point,
  not a soundness one: the patched library is kernel-checked like the rest.
- [**103**](families/103/README.md), `L = RL = BPL`: 39 files, checked at
  upstream `fd4aeeb` because the formalization arrived in the 2026-10-07
  update. Passes every gate that applies on an Apple M4; no CI run yet when
  written. Its 118 `set_option`s are all resource limits or `autoImplicit`,
  which is why gate F now separates those from options that could matter.

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

## Why the gates are built the way they are

A gate that cannot fail is worse than no gate, because it converts "we did not
look" into "we looked and it was fine". Three features above exist only to
guard against that: gate A counts compiled modules rather than trusting an exit
code, gate E perturbs the statement to prove gate C can reject something, and
gate G checks this page's quotations against the logs it cites.

None of those were foresight. Each one is here because the thing it guards
against had already happened, in a run whose number you can read off the commit
history:

| the question | what went wrong before the gate answered it |
|---|---|
| Did the build cover the family, or merely exit 0? | Gate A passed on `exit 0` and printed `N/N` with `N` counted from the **source** files. It would have reported "42/42" for a build that compiled nothing. |
| Can gate C reject anything at all? | Nothing checked, until gate E weakened the constant and required the file to stop compiling. |
| Is a quoted log line in a log we have? | This page quoted a `#print axioms` that no file contained, and then quoted two lines off an archived log produced *before* those lines existed. Both readings looked right. |
| Did the harness run at all? | `audit.sh` took its repo root from `$PWD`, which `recheck.sh` had already changed, and exited 64 before reaching a single gate. |
| Is the evidence still there afterwards? | `upload-artifact` skips dot-directories, so every log under `.work/` was dropped in silence. |

Five findings across six runs, and four of the five were in *this* harness, not
in OpenAI's proof — their 42 files compiled on the first attempt on both
machines. The checker needed four corrections before it was entitled to say so.

Adding the second statement found three more problems, again all in this
harness and none in OpenAI's 90 files: an empty dump on both sides that read as
"identical", a parser that glued two adjacent declarations together, and
binder names carrying the module they were elaborated in. They are listed in
[`families/325-hilbert/README.md`](families/325-hilbert/README.md). Teaching
gate G to check `audit.sh`'s own verdict lines then turned up one more in the
write-up: 325's page quoted gate G's verdict, which no archived log contained.

Families 102 and 107 added two more, both ours: `recheck.sh` wrote
`require mathlib` first, so a third-party library's own pins won and the
Mathlib cache refused to load; and it built that library unpatched, which
upstream never does. OpenAI's 509 files compiled on the first run that built
them as upstream does
([107's write-up](families/107/README.md#two-runs-that-failed-first-both-on-our-side)).

Which is the argument for this repository, and it is not that formalisations
fail to compile. It is that a formalisation with no CI leaves nothing to tell
you when your *checker* is lying — and a checker will. Trusting one that has
never been made to fail is the part worth worrying about.

## What these gates do and do not show

For the four statements covered, `DirectCrouzeix`, `CrouzeixHilbert`,
`CompleteCrouzeix` and `StructuralCrouzeix`, they
show that the Lean development compiles, contains no `sorry`, introduces no
axiom, does not disable the kernel, and proves the proposition in the
comparator challenge file.

They are **not** a verdict on the mathematics. Three gaps remain:

1. **Whether the formal statement faithfully renders the informal conjecture is
   a human judgement.** We checked what could be checked mechanically: the norm
   is Mathlib's L2 operator norm (`Matrix.instL2OpNormedRing`, pinned down by
   `‖I₂‖ = 1`, which the Frobenius norm fails), `numericalRange` is the textbook
   `{⟪u, Au⟫ : ‖u‖ = 1}`, and its 1×1 case is exactly `{A 0 0}` — the direction
   that matters, since a numerical range that were *too large* would raise the
   supremum and make the theorem *weaker*.

   We also read the challenge against Theorem 1.1 of the preprint
   (`preprints/A-direct-proof-of-the-complete-Crouzeix-inequality-September-26-2026/paper.pdf`,
   sha256 `d9aa4ef2…199bb6`), clause by clause. This is reading, not a gate:

   | Preprint, §1 | Challenge file |
   |---|---|
   | `P[A] = Σₖ Aᵏ ⊗ Bₖ`, "the base space ℂⁿ is the first tensor factor" | `tensorEvaluation`: `∑ k, (A ^ k) ⊗ₖ (B k)` on `Fin n × Fin m` |
   | operator norms from the Euclidean inner products and their Hilbert tensor product | L2 operator norm, scoped over every index type, so it applies on `Fin n × Fin m` too |
   | `max_{z ∈ W(A)} ‖P(z)‖` | `rangeMaximum`: `sSup` of the same set; equal to the max because `W(A)` is compact and non-empty when `0 < n` |
   | every `n, m ≥ 1`, every `d ≥ 0`, `Bₖ ∈ Mₘ(ℂ)` | `UniversalBound`: `∀ n m d, 0 < n → 0 < m → ∀ A B` |
   | "cannot be decreased uniformly over n, m, and d" | `uniform_sharpness : UniversalBound c → 2 ≤ c` |

   We found no mismatch. What is left is the step from the preprint's "matrix
   formulation" to the operator-algebra one in the literature (W(A) as a
   complete 2-spectral set, tested on matrix-valued rational functions). For
   compact convex `W(A)`, polynomial approximation (Runge/Mergelyan, entrywise)
   makes the two equivalent. That is our own argument, and nothing in this
   repository checks it for `DirectCrouzeix`. `CrouzeixHilbert` does not need
   it: its formal statement includes the bound for matrix-valued rational
   functions with poles outside the closure of the numerical range, and its
   proof compiles ([write-up](families/325-hilbert/README.md)).
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

Timing, for calibration. The two runs differ by 7×, and the difference is
almost entirely paging, not proof-checking:

| | Apple M4, 16 GB, macOS 26.5.2 | `ubuntu-24.04` runner, 7 GB, x86_64 |
|---|---|---|
| `lake exe cache get` | — | 2m59s |
| `lake build` | **36m48s** (`user` 2m11s, `sys` 3m48s) | **5m29s** |
| first file (`Model`) | 67 s | 43 s |
| every later file | 47–67 s, flat | **3.7–11 s** |

Six minutes of CPU inside thirty-seven of wall clock, and a per-file cost that
never drops after the first file, is the signature of re-reading Mathlib's
`.olean` files once per Lean process. On the runner only the first file pays
that, and the rest are 5–10× cheaper. So this number measures the machine's
page cache, not the difficulty of the proof — do not read it as a proxy for
either.

## Adding a family

Create `families/<n>/family.conf` (copy
[325's](families/325/family.conf), it is commented) and run `./recheck.sh <n>`.

If the family imports anything outside Mathlib (and `Init`/`Lean`/`Std`,
which ship with the toolchain), `recheck.sh` stops and says what. That is a
result, not an obstacle, and worth reporting. To go further, declare the
library in `EXTRA_REQUIRES` as `<manifest package>:<import root>`, as
[107](families/107/family.conf) does: its rev is read from upstream's
manifest, upstream's `lean/patches/<package>-lean4341.patch` is applied if
there is one, and gate F checks that patch is the only change. A family whose
formalization only exists in a later upstream commit sets
`FAMILY_UPSTREAM_SHA` ([103](families/103/family.conf)).

Gates C to E need either a hand-written `Verify.lean` (as in 325) or
`CHALLENGE_MODULE` and `NEG_KIND=dump` in `family.conf` (as in 325-hilbert,
which needs no Lean of ours). Gate G needs a `README.md` and archived `logs/`.
Without any of those you get gates A, B and F, which is already more than the
repository currently demonstrates about itself.

## Licence

Apache-2.0, matching upstream. This repository contains no OpenAI code; see
[NOTICE](NOTICE).
