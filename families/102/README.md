# Family 102: the Unique Games Conjecture

Upstream: [openai/math](https://github.com/openai/math) @
`adc7f1241b42e322a6451854ab7e4b4c146bf78a`
· statement `lean/ComparatorChallenges/UniqueGamesTheorem.lean`
· proof `lean/OAI/Computability/UniqueGames/` (478 files, 186,782 lines)
· family page `lean/docs/102.md`, which links five comparator files. This
configuration checks the headline one; the four hardness corollaries
(Max-Cut, Vertex Cover, Min-UnCut, directed feedback vertex set) are not
checked here.

## What it states

`OAI.UniqueGamesTheorem.theorem11`: for every fixed `0 < ε, δ < 1/2` there is
a reduction from binary 3SAT to Unique Games such that satisfiable formulas
give games of value at least `1 - ε` and unsatisfiable ones give games of
value at most `δ`. The games are unweighted, simple and bipartite, and every
constraint is a translation over `F₂ˢ`; the alphabet and the machine depend
only on `ε, δ`.

That is a special case of Unique Games (translation constraints over one
fixed group), so hardness for it implies the conjecture as usually stated. We
have not checked how this special case relates to the formulations in the
literature beyond that implication.

## The part a statement could get wrong

An NP-hardness claim says nothing unless the reduction is restricted. If the
"reduction" were any function at all, it could solve 3SAT itself and output a
fixed good or bad game, and the theorem would be true and empty. So the first
question about this statement is how "polynomial time" is encoded.

It is Mathlib's own `Turing.TM2ComputableInPolyTime`
(`Mathlib/Computability/TuringMachine/Computable.lean` at Mathlib `d13f23b`,
line 179), not a definition OpenAI wrote: a bundled multi-stack Turing machine
that must halt with the encoded game within `p(n)` steps, `n` the raw input
length, for a fixed polynomial `p`. The input is the raw bit string, malformed
inputs included, so soundness also covers garbage. Every number in the output
encoding is written in unary, which only makes the time bound stricter.

One detail Mathlib leaves open: `FinTM2` requires a finite alphabet only for
the input stack. The field's docstring (line 67) reads "Each internal stack is
finite.", but the field itself (line 68) is `Fintype (Γ k₀)`. The statement
closes this on its own with a `finiteAlphabet` field
(`UniqueGamesTheorem.lean` line 215). We did not check whether the gap is known
to Mathlib or whether it could be exploited; the statement does not rely on
either.

Gate C pins both facts: besides comparing the elaborated statement constant by
constant, it asserts that the constructor of `BinaryGapReduction` takes
`Turing.TM2ComputableInPolyTime` and the finite-alphabet condition.

## Gate results

GitHub Actions, `ubuntu-24.04` x86_64, run
[38141681690](https://github.com/Beltran12138/oai-math-recheck/actions/runs/38141681690).
Logs in [`logs/ci-ubuntu-x86_64/`](logs/ci-ubuntu-x86_64).

```
    PASS  478/478 modules compiled (478 built this run), exit 0, wall 21m27s
    PASS  1/1 theorems: [propext, Classical.choice, Quot.sound], no sorry
    PASS  74 constants identical after elaboration (types, universe params, definition bodies)
    PASS  assert: OAI.UniqueGamesTheorem.Explicit.MachineOutputContract.BinaryGapReduction.mk uses Turing.TM2ComputableInPolyTime
    PASS  assert: OAI.UniqueGamesTheorem.Explicit.MachineOutputContract.BinaryGapReduction.mk uses OAI.UniqueGamesTheorem.Foundations.Complexity.MachineFiniteAlphabet.FiniteAlphabet
    PASS  none of the above appear in OAI/Computability/UniqueGames 
    PASS  all Lake packages match their pinned revisions
```

Gate E loosens completeness from `1 - ε` to `1 - ε / 2` in a copy of the
challenge. Its verdict names `BinaryGapReduction.mk` as the constant that
differs. Gate D is skipped: the statement is checked by elaboration (gate C),
not by re-declaring definitions in a file of ours.

The family's first run,
[38139197748](https://github.com/Beltran12138/oai-math-recheck/actions/runs/38139197748)
at `1ac4826`, passed the same gates with a 15m09s build.

## What this does and does not show

It shows that OpenAI's 478 files compile against the Mathlib they pin, that
the theorem they prove is the comparator statement above, and that nothing in
it rests on an axiom beyond Lean's standard three.

It does not show that the proof is understood by anyone, that the
formalisation matches the accompanying papers, or that the special case
proved is the one the community will accept as "the Unique Games Conjecture".
A kernel-checked proof of a faithful statement settles truth; acceptance is a
separate process.

## Files

| file | what it is |
|---|---|
| [`family.conf`](family.conf) | configuration read by `../../recheck.sh` and `../../audit.sh` |
| [`logs/ci-ubuntu-x86_64/`](logs/ci-ubuntu-x86_64) | actual output of the run above, the challenge and negative-control dumps (gzipped) and their sha256 |
