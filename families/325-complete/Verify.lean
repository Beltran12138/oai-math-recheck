/-
Cross-check inside family 325: does OpenAI's *second* proof development
(lean/OAI/Analysis/NumericalRange, for ComparatorChallenges/CompleteCrouzeix)
close the *first* development's challenge statement
(ComparatorChallenges/DirectCrouzeix)?

The two challenge files state the same inequality in slightly different
spellings (binder names, `Matrix.kronecker` against the `⊗ₖ` notation, an
extra `open scoped ComplexOrder`).  The definitions below are DirectCrouzeix's,
verbatim (gate D diffs them against that file).  If the two `example`s compile,
CompleteCrouzeix's proof proves DirectCrouzeix's statement up to definitional
unfolding: two independent developments, one proposition.
-/
import OAI.Analysis.NumericalRange.Main

namespace Check

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

/-- DirectCrouzeix's statement, closed by CompleteCrouzeix's proof. -/
example : UniversalBound 2 := OAI.CompleteCrouzeix.main.1

/-- Same for the sharpness half. -/
example (c : ℝ) (hc : UniversalBound c) : 2 ≤ c := OAI.CompleteCrouzeix.main.2 c hc

end

end Check
