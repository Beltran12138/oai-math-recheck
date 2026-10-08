/-
Independent check of OpenAI's "complete Crouzeix inequality" (result family 325).

Source: https://github.com/openai/math  @ main (2026-10-06)
  statement : lean/ComparatorChallenges/DirectCrouzeix.lean
  proof     : lean/OAI/Analysis/DirectCrouzeix/   (42 files, 7389 lines)

What this file checks, and what it does NOT check:

  ✓ the proof compiles against Mathlib (pinned to the same commit OpenAI used)
  ✓ the two headline theorems depend on no axioms beyond propext /
    Classical.choice / Quot.sound  (i.e. no `sorry`, no extra assumptions)
  ✓ the statement proved is definitionally the statement in the comparator
    challenge file (Check.UniversalBound below is a verbatim copy of it)

  ✗ it does NOT run under `comparator`'s sandbox, so it assumes the files in
    this directory are the ones published by OpenAI and not tampered with
  ✗ it does NOT tell you the formal statement is a faithful rendering of
    Crouzeix's conjecture.  That judgement is human work; read the definitions.
-/
import OAI.Analysis.DirectCrouzeix.Main

open OAI.DirectCrouzeix

section Statements

#check @complete_crouzeix
#check @uniform_sharpness

end Statements

section AxiomAudit

/- Expected output for both: `[propext, Classical.choice, Quot.sound]`.
Anything else — above all `sorryAx` — means the proof is incomplete. -/
#print axioms complete_crouzeix
#print axioms uniform_sharpness

end AxiomAudit

namespace Check

/-! Verbatim copy of the definitions in `ComparatorChallenges/DirectCrouzeix.lean`,
re-declared here so that the `example` below fails if the proved statement and
the challenge statement ever drift apart. -/

noncomputable section

open scoped Matrix Matrix.Norms.L2Operator Kronecker

def numericalRange {n : ℕ} (A : Matrix (Fin n) (Fin n) ℂ) : Set ℂ :=
  {z | ∃ u : EuclideanSpace ℂ (Fin n), ‖u‖ = 1 ∧
    inner ℂ u (Matrix.toEuclideanCLM (n := Fin n) (𝕜 := ℂ) A u) = z}

def polynomialValue {m d : ℕ} (B : Fin (d + 1) → Matrix (Fin m) (Fin m) ℂ)
    (z : ℂ) : Matrix (Fin m) (Fin m) ℂ :=
  ∑ k : Fin (d + 1), z ^ (k : ℕ) • B k

def tensorEvaluation {n m d : ℕ} (A : Matrix (Fin n) (Fin n) ℂ)
    (B : Fin (d + 1) → Matrix (Fin m) (Fin m) ℂ) :
    Matrix (Fin n × Fin m) (Fin n × Fin m) ℂ :=
  ∑ k : Fin (d + 1), (A ^ (k : ℕ)) ⊗ₖ (B k)

def rangeMaximum {n m d : ℕ} (A : Matrix (Fin n) (Fin n) ℂ)
    (B : Fin (d + 1) → Matrix (Fin m) (Fin m) ℂ) : ℝ :=
  sSup ((fun z => ‖polynomialValue B z‖) '' numericalRange A)

def UniversalBound (c : ℝ) : Prop :=
  ∀ (n m d : ℕ), 0 < n → 0 < m →
    ∀ (A : Matrix (Fin n) (Fin n) ℂ)
      (B : Fin (d + 1) → Matrix (Fin m) (Fin m) ℂ),
      ‖tensorEvaluation A B‖ ≤ c * rangeMaximum A B

/-- The challenge statement, closed by OpenAI's theorem.  Compiles only if the
two `UniversalBound`s are definitionally equal. -/
example : UniversalBound 2 := complete_crouzeix

/-- Same for the sharpness half: no constant below 2 can work. -/
example (c : ℝ) (hc : UniversalBound c) : 2 ≤ c := uniform_sharpness c hc

end

end Check
