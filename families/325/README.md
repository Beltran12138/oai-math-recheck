# Family 325 — the complete Crouzeix inequality

Upstream: [openai/math](https://github.com/openai/math) @
`adc7f1241b42e322a6451854ab7e4b4c146bf78a`
· statement `lean/ComparatorChallenges/DirectCrouzeix.lean` (44 lines)
· proof `lean/OAI/Analysis/DirectCrouzeix/` (42 files, 7 389 lines)
· family page `lean/docs/325.md`
· preprint *A direct proof of the complete Crouzeix inequality*, 2026-09-26

## The claim

For a square complex matrix `A`, write `W(A) = {u*Au : ‖u‖ = 1}` for its
numerical range. OpenAI's two theorems are, verbatim from the challenge file:

```lean
def UniversalBound (c : ℝ) : Prop :=
  ∀ (n m d : ℕ), 0 < n → 0 < m →
    ∀ (A : Matrix (Fin n) (Fin n) ℂ)
      (B : Fin (d + 1) → Matrix (Fin m) (Fin m) ℂ),
      ‖tensorEvaluation A B‖ ≤ c * rangeMaximum A B

theorem complete_crouzeix : UniversalBound 2
theorem uniform_sharpness (c : ℝ) (hc : UniversalBound c) : 2 ≤ c
```

with `tensorEvaluation A B = ∑ₖ Aᵏ ⊗ Bₖ` and
`rangeMaximum A B = sup { ‖∑ₖ zᵏ Bₖ‖ : z ∈ W(A) }`. The coefficients `Bₖ` are
`m × m` matrices and `m` is universally quantified: this is the *completely
bounded* Crouzeix inequality with constant 2, plus the statement that 2 cannot
be lowered.

### Where this sits in the literature

Worth getting right, because the obvious headline is wrong, and OpenAI's own
bibliography is what shows it is wrong.

| | result | who | when |
|---|---|---|---|
| scalar, constant `1+√2` | `‖p(A)‖ ≤ (1+√2)·sup\|p\|` | Crouzeix–Palencia | 2017 |
| **scalar, constant 2** | the classical conjecture, settled | **Lorist–Schwenninger** [arXiv:2608.03841](https://arxiv.org/abs/2608.03841) (also Jin, Luo) | **2026-08** |
| complete, `n = 2` | matrix coefficients, base dimension exactly 2 | Badea–Crouzeix–Delyon | 2006 |
| complete, `n ≤ 3` | matrix coefficients, base dimension ≤ 3 | Åhag–Czyż–Virtanen [arXiv:2608.27346](https://arxiv.org/abs/2608.27346) | 2026-08 (v4 09-21) |
| **complete, all `n`, all `m`** | **this family** | OpenAI | 2026-09-26 |

Three things follow.

1. **Crouzeix's conjecture was not open when OpenAI published.** Its scalar
   form was resolved by Lorist and Schwenninger in August 2026, in seven pages.
   Crouzeix and Greenbaum's own [2026-09-18 update](https://arxiv.org/abs/2609.22460)
   to their survey is built on that paper, which is uptake by the people
   closest to the problem. OpenAI cites it as reference **[14]**.
2. **What is claimed here is the amplification to matrix coefficients**, with
   base and coefficient dimension independent. OpenAI's novelty sentence is
   exactly one sentence long and exactly this narrow: *"The scalar results fix
   m = 1, while the latter complete result restricts the base dimension;
   Theorem 1.1 leaves these dimensions independent."*
3. **That amplification is not a corollary of the scalar case.** OpenAI points
   at Lorist–Schwenninger's own §3(iv) for why the commutation their proof
   relies on does not automatically survive it. So the claim is not empty — it
   just is not the claim the headlines made.

## Gate results

All six gates pass on both of two machines of different architecture, on Lean
`v4.34.1` against Mathlib `d13f23b723b8a846827a245b89c10fc7d3f11612` — the
revision upstream's own `lake-manifest.json` pins, read out of that file by
`recheck.sh` rather than hard-coded here:

| | Apple M4, 10 cores, 16 GB, macOS 26.5.2 | `ubuntu-24.04`, x86_64, 7 GB |
|---|---|---|
| run | local, 2026-10-07 | [Actions run 37723287735](https://github.com/Beltran12138/oai-math-recheck/actions/runs/37723287735) |
| `lake build` | 36m48s | 5m29s |
| gates A–F | all pass | all pass |
| raw output | [`logs/`](logs) | [`logs/ci-ubuntu-x86_64/`](logs/ci-ubuntu-x86_64) |

The second run is the one worth pointing at, because its log is public and it
ran on a machine neither of us controls. It is also the run that found three
bugs in this harness, including a gate A that would have reported "42/42" on a
build that compiled nothing — see that gate below.

### A — it compiles

42/42 files, `exit 0`, **36m48.120s** wall; see [`logs/build.log`](logs/build.log),
which carries one `Built OAI.Analysis.DirectCrouzeix.…` line per file (Lake jobs
8924–8965) and `Build completed successfully (8966 jobs)`.

The number that closes this gate is the count of `.olean` files on disk, not the
build's exit status: `lake build` also exits 0 when a `lean_lib` glob matches
nothing, and an earlier version of `audit.sh` would have reported "42/42" in
that case because it counted the *source* files. It now fails unless the
compiled modules account for every source file.

Note the CPU split in that log — `user 2m10s`, `sys 3m47s`, against 36m48s of
wall clock. Seven minutes of work and half an hour of waiting: the cost here is
re-reading Mathlib's `.olean` files once per Lean process, so this number says
much more about the machine's memory and disk than about the proof.

### B — axioms

Run from a throwaway file importing only OpenAI's `Main`, so that no code of
ours is on this path:

```
'OAI.DirectCrouzeix.complete_crouzeix' depends on axioms: [propext, Classical.choice, Quot.sound]
'OAI.DirectCrouzeix.uniform_sharpness' depends on axioms: [propext, Classical.choice, Quot.sound]
```

No `sorryAx`, so no `sorry` anywhere in the 7 389 lines or in anything they
call. No `Lean.ofReduceBool`, so no `native_decide`. Nothing beyond the three
axioms Mathlib itself assumes.

### C — it is the challenge's statement

[`Verify.lean`](Verify.lean) re-declares the challenge's five definitions in a
fresh namespace and closes the re-declared statement with OpenAI's theorem:

```lean
example : UniversalBound 2 := complete_crouzeix
example (c : ℝ) (hc : UniversalBound c) : 2 ≤ c := uniform_sharpness c hc
```

Both elaborate, so the proposition proved is definitionally the proposition
posed.

Since run
[37755867541](https://github.com/Beltran12138/oai-math-recheck/actions/runs/37755867541)
gate C also runs a second check that goes through no file of ours: the
comparator-style dump described in [`../325-hilbert`](../325-hilbert), which
finds the challenge and the solution identical over 11 constants. The logs
archived on this page predate it.

### D — the re-declared definitions are really theirs

Gate C would prove nothing if we had copied the definitions out of the
*solution* rather than the *challenge*: the `example` would then be closing a
statement by itself. `audit.sh` extracts all five from both files and compares
them token-for-token after whitespace normalisation:

```
      same  numericalRange
      same  polynomialValue
      same  tensorEvaluation
      same  rangeMaximum
      same  UniversalBound
```

### E — gate C has teeth

Weaken the constant from 2 to 1 in `Scalar.lean` and the file must stop
compiling. It does: `Application type mismatch`. (Perturbing *upward*, to 3,
would be a bad control — `UniversalBound 2` implies the weaker bound, so it
should still go through, and it does.)

### F — nothing skips the kernel

Across OpenAI's 42 files: **zero** occurrences of `set_option` — in particular
no `debug.skipKernelTC`, which would switch off kernel type-checking and which
`#print axioms` would not reveal — and zero of `axiom`, `native_decide`,
`unsafe`, `implemented_by`, `@[extern]`, `#exit`, `macro`/`elab`/`syntax`.
Mathlib and all eight transitive Lake packages match their pinned revisions
with no local modifications.

### G — the write-up quotes logs it actually has

Every line this page shows inside a code fence that looks like Lean or Lake
output, or like one of `audit.sh`'s own PASS / FAIL / SKIP lines, is checked
verbatim against the files under [`logs/`](logs). All four pass.

Gate G's own verdict line is deliberately not quoted here. An earlier version
did quote it, and once the gate learned to check verdict lines it flagged that
quote: the archived `gates.log` predates gate G, and a quote of the gate's
count changes the count it reports.

This gate exists because an earlier version of this page quoted two
`#print axioms` lines off an archived log that was produced *before*
`Scalar.lean` had any `#print axioms` in it. The quote was correct and the
citation was impossible, and no amount of re-reading either file would have
shown it.

What it covers: quoted tool output. What it does **not** cover: prose, and in
particular the timing tables — those are still only as good as the author.

The two `sorry`s in `ComparatorChallenges/DirectCrouzeix.lean` are by design:
the challenge file is the *statement*, and `comparator` pairs it with a
solution that supplies the proof.

## `Scalar.lean` — specialising to scalar coefficients

`UniversalBound` is five nested definitions deep, which is more than a reader
should have to take on trust. So [`Scalar.lean`](Scalar.lean) derives from
`complete_crouzeix` the statement you can check by eye:

```lean
theorem scalar_crouzeix {n : ℕ} (hn : 0 < n) (A : Matrix (Fin n) (Fin n) ℂ)
    (p : Polynomial ℂ) :
    ‖(Polynomial.aeval A) p‖ ≤ 2 * sSup ((fun z => ‖p.eval z‖) '' numericalRange A)
```

`Scalar.lean` ends with `#print axioms` on both of its own results, so the
derivation cannot smuggle in anything the gates do not see. Verbatim from
[`logs/ci-ubuntu-x86_64/verify.log`](logs/ci-ubuntu-x86_64/verify.log):

```
info: Scalar.lean:156:0: 'Recheck.scalar_crouzeix' depends on axioms: [propext, Classical.choice, Quot.sound]
info: Scalar.lean:157:0: 'Recheck.numericalRange_fin_one' depends on axioms: [propext, Classical.choice, Quot.sound]
```

**What this is worth, precisely.** As of August 2026 this statement is a
theorem independently proved by humans, so deriving it is a *consistency
check*, not a verification of anything new: a short, plainly-worded, known-hard
result falls out of their machinery, which is good evidence that
`UniversalBound` is not a mis-formalisation that states something vacuous or
unrelated. It says **nothing** about the part OpenAI actually claims, the
uniformity in `m` — by construction, since it fixes `m = 1`. For that, read
`UniversalBound` above.

The specialisation takes `m = 1` and `Bₖ = p.coeff k • 1`. Two small facts are
needed that neither Mathlib nor OpenAI's files contain:

- `l2_opNorm_le_kronecker_one` — the L2 operator norm does not grow when you
  tensor with the 1×1 identity. Mathlib has no Kronecker-product norm lemma at
  all, so this is proved from `Matrix.l2_opNorm_mulVec` by padding vectors
  along the singleton index. Only `≤` is needed; equality also holds.
- `numericalRange_fin_one` — for a 1×1 matrix, `W(A) = {A 0 0}` exactly. The
  `⊆` half is the one that matters: a `numericalRange` that were too *large*
  would raise the supremum and make the theorem *weaker*, so that is the
  direction an error would hide in.

## What is still open

1. **Faithfulness of the formalisation is a human judgement**, and
   `scalar_crouzeix` narrows it without removing it. Pinned down mechanically:
   the norm instance is `Matrix.instL2OpNormedRing` (Mathlib's L2 operator
   norm — `‖I₂‖ = 1` holds, which rules out the Frobenius norm's `√2`);
   `numericalRange` unfolds to the textbook set; the constant is not fudged.
   Not pinned down: whether `tensorEvaluation`/`rangeMaximum` with `m` free is
   the complete Crouzeix inequality as the literature means it. That is the one
   sentence of the claim that is new, and it is the one sentence a machine
   cannot settle for you. The top-level README now reads it clause by clause
   against the preprint's Theorem 1.1; that is still reading, not a gate.
2. **We did not run `comparator`.** It wants Linux Landlock (`landrun`) plus
   `systemd-run`. So what is here is a reproduction plus an axiom and statement
   audit, not OpenAI's own adversarial check, and the provenance claim is just
   the upstream commit SHA.
3. **We did not check the preprint's proof.** Gate B says the Lean development
   is a complete, axiom-clean proof of the formal statement. Whether the
   twelve-page preprint is a correct human-readable proof of the same thing is
   a separate question, and a referee's rather than ours.
4. **This is one of the family's four substantive comparator statements.**
   `lean/docs/325.md` links five comparator files and labels only
   `HilbertCrouzeix` as support. Everything above is about `DirectCrouzeix`.
   `CrouzeixHilbert` (the arbitrary-Hilbert-space version) is in
   [`../325-hilbert`](../325-hilbert) and `CompleteCrouzeix` in
   [`../325-complete`](../325-complete); `StructuralCrouzeix` is not covered.
   An earlier comment in this family's config file called those three
   "support lemmas"; it was wrong.

## Files

| file | what it is |
|---|---|
| [`family.conf`](family.conf) | configuration read by `../../recheck.sh` |
| [`Verify.lean`](Verify.lean) | gates C and D: `#print axioms` and the defeq check |
| [`Scalar.lean`](Scalar.lean) | the scalar specialisation, derived and axiom-clean |
| [`logs/`](logs) | actual output from the run described above |
