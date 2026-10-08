/-
Does OpenAI's "complete Crouzeix" actually imply the classical Crouzeix conjecture?

`OAI.DirectCrouzeix.complete_crouzeix` is stated for *matrix*-coefficient
polynomials.  The classical conjecture (Crouzeix 2004) is about scalar
polynomials:

    ‖p(A)‖ ≤ 2 · sup { |p z| : z ∈ W A }      (operator norm, W A = numerical range)

This file derives that from their theorem by specialising to 1×1 coefficients,
so that a reader only has to check this one short statement rather than the
five nested definitions in their challenge file.
-/
import OAI.Analysis.DirectCrouzeix.Main

namespace Recheck

noncomputable section

open scoped Matrix Matrix.Norms.L2Operator Kronecker
open OAI.DirectCrouzeix

/-! ### Step 1: padding by a singleton index is an isometry -/

lemma norm_pad {n : ℕ} (v : Fin n → ℂ) :
    ‖(EuclideanSpace.equiv (Fin n × Fin 1) ℂ).symm (fun q => v q.1)‖
      = ‖(EuclideanSpace.equiv (Fin n) ℂ).symm v‖ := by
  simp [EuclideanSpace.norm_eq, Fintype.sum_prod_type]

/-- The operator norm does not grow when we tensor with the 1×1 identity.
Only `≤` is needed below (equality also holds). -/
lemma mulVec_kronecker_one {n : ℕ} (M : Matrix (Fin n) (Fin n) ℂ) (v : Fin n → ℂ) :
    (M ⊗ₖ (1 : Matrix (Fin 1) (Fin 1) ℂ)) *ᵥ (fun q => v q.1)
      = fun q : Fin n × Fin 1 => (M *ᵥ v) q.1 := by
  funext q
  obtain ⟨i, j⟩ := q
  have hj : j = 0 := Subsingleton.elim _ _
  subst hj
  simp [Matrix.mulVec, dotProduct, Fintype.sum_prod_type, Matrix.one_apply]

lemma l2_opNorm_le_kronecker_one {n : ℕ} (M : Matrix (Fin n) (Fin n) ℂ) :
    ‖M‖ ≤ ‖M ⊗ₖ (1 : Matrix (Fin 1) (Fin 1) ℂ)‖ := by
  rw [Matrix.l2_opNorm_def M]
  refine ContinuousLinearMap.opNorm_le_bound _ (norm_nonneg _) fun x => ?_
  have hx : ((Matrix.toEuclideanLin ≪≫ₗ LinearMap.toContinuousLinearMap) M) x
      = (EuclideanSpace.equiv (Fin n) ℂ).symm (M *ᵥ x.ofLp) := rfl
  set y : EuclideanSpace ℂ (Fin n × Fin 1) :=
    (EuclideanSpace.equiv (Fin n × Fin 1) ℂ).symm (fun q => x.ofLp q.1) with hy
  have hyx : ‖y‖ = ‖x‖ := by rw [hy, norm_pad]; rfl
  have hmv := Matrix.l2_opNorm_mulVec (M ⊗ₖ (1 : Matrix (Fin 1) (Fin 1) ℂ)) y
  have hofy : y.ofLp = fun q : Fin n × Fin 1 => x.ofLp q.1 := rfl
  rw [hofy, mulVec_kronecker_one M x.ofLp, hyx] at hmv
  rw [hx]
  calc ‖(EuclideanSpace.equiv (Fin n) ℂ).symm (M *ᵥ x.ofLp)‖
      = ‖(EuclideanSpace.equiv (Fin n × Fin 1) ℂ).symm
          (fun q : Fin n × Fin 1 => (M *ᵥ x.ofLp) q.1)‖ := (norm_pad _).symm
    _ ≤ _ := hmv

/-! ### Step 2: 1×1 coefficient polynomials -/

lemma polynomialValue_scalar {d : ℕ} (p : Polynomial ℂ) (hd : p.natDegree < d + 1) (z : ℂ) :
    polynomialValue (fun k : Fin (d + 1) => p.coeff k • (1 : Matrix (Fin 1) (Fin 1) ℂ)) z
      = p.eval z • (1 : Matrix (Fin 1) (Fin 1) ℂ) := by
  rw [Polynomial.eval_eq_sum_range' hd]
  simp only [polynomialValue, smul_smul, ← Finset.sum_smul]
  congr 1
  rw [Fin.sum_univ_eq_sum_range (fun t => z ^ t * p.coeff t) (d + 1)]
  exact Finset.sum_congr rfl fun k _ => mul_comm _ _

lemma norm_smul_one_fin_one (c : ℂ) :
    ‖(c • (1 : Matrix (Fin 1) (Fin 1) ℂ))‖ = ‖c‖ := by
  rw [Matrix.smul_one_eq_diagonal, Matrix.l2_opNorm_diagonal]
  simp

lemma tensorEvaluation_scalar {n d : ℕ} (A : Matrix (Fin n) (Fin n) ℂ)
    (p : Polynomial ℂ) (hd : p.natDegree < d + 1) :
    tensorEvaluation A (fun k : Fin (d + 1) => p.coeff k • (1 : Matrix (Fin 1) (Fin 1) ℂ))
      = (Polynomial.aeval A p) ⊗ₖ (1 : Matrix (Fin 1) (Fin 1) ℂ) := by
  ext q r
  obtain ⟨i, j⟩ := q
  obtain ⟨k, l⟩ := r
  have hj : j = 0 := Subsingleton.elim _ _
  have hl : l = 0 := Subsingleton.elim _ _
  subst hj; subst hl
  have hL : tensorEvaluation A
      (fun t : Fin (d + 1) => p.coeff t • (1 : Matrix (Fin 1) (Fin 1) ℂ)) (i, 0) (k, 0)
      = ∑ t : Fin (d + 1), p.coeff (t : ℕ) * (A ^ (t : ℕ)) i k := by
    simp [tensorEvaluation, Matrix.sum_apply, mul_comm]
  have hR : ((Polynomial.aeval A p) ⊗ₖ (1 : Matrix (Fin 1) (Fin 1) ℂ)) (i, 0) (k, 0)
      = ∑ t ∈ Finset.range (d + 1), p.coeff t * (A ^ t) i k := by
    rw [Polynomial.aeval_eq_sum_range' hd]
    simp [Matrix.sum_apply]
  rw [hL, hR, Fin.sum_univ_eq_sum_range (fun t => p.coeff t * (A ^ t) i k) (d + 1)]

/-! ### Step 3: the classical statement -/

/-- **Classical Crouzeix inequality**, derived from `complete_crouzeix`.
For every square complex matrix `A` and every polynomial `p`,
the operator norm of `p A` is at most twice the sup of `|p|` on the
numerical range of `A`. -/
theorem scalar_crouzeix {n : ℕ} (hn : 0 < n) (A : Matrix (Fin n) (Fin n) ℂ)
    (p : Polynomial ℂ) :
    ‖(Polynomial.aeval A) p‖
      ≤ 2 * sSup ((fun z => ‖p.eval z‖) '' numericalRange A) := by
  have hd : p.natDegree < p.natDegree + 1 := Nat.lt_succ_self _
  set B : Fin (p.natDegree + 1) → Matrix (Fin 1) (Fin 1) ℂ :=
    fun k => p.coeff k • (1 : Matrix (Fin 1) (Fin 1) ℂ) with hB
  have hmain := complete_crouzeix n 1 p.natDegree hn one_pos A B
  rw [tensorEvaluation_scalar A p hd] at hmain
  have himg : (fun z => ‖polynomialValue B z‖) '' numericalRange A
      = (fun z => ‖p.eval z‖) '' numericalRange A := by
    apply Set.image_congr
    intro z _
    rw [hB, polynomialValue_scalar p hd z, norm_smul_one_fin_one]
  have hrange : rangeMaximum A B = sSup ((fun z => ‖p.eval z‖) '' numericalRange A) := by
    rw [rangeMaximum, himg]
  rw [hrange] at hmain
  exact le_trans (l2_opNorm_le_kronecker_one _) hmain

/-! ### Step 4: sanity check on `numericalRange` itself

`scalar_crouzeix` is only as meaningful as `numericalRange`.  Note which
direction is dangerous: if `numericalRange A` were *too large*, the supremum on
the right would be larger and the inequality would be *weaker*.  So the `⊆`
half below is the one that has to hold, and it does. -/

/-- For a 1×1 matrix the numerical range is exactly the singleton `{A 0 0}` —
not larger (which would weaken the bound) and not empty. -/
theorem numericalRange_fin_one (A : Matrix (Fin 1) (Fin 1) ℂ) :
    numericalRange A = {A 0 0} := by
  ext z
  simp only [numericalRange, Set.mem_setOf_eq, Set.mem_singleton_iff]
  constructor
  · rintro ⟨u, hu, rfl⟩
    have h1 : ‖u.ofLp 0‖ = 1 := by
      simpa [EuclideanSpace.norm_eq, Real.sqrt_eq_one] using hu
    have hc : u.ofLp 0 * (starRingEnd ℂ) (u.ofLp 0) = 1 := by
      rw [mul_comm, RCLike.conj_mul]; simp [h1]
    have hu' : (Matrix.toEuclideanCLM (n := Fin 1) (𝕜 := ℂ) A u).ofLp = A *ᵥ u.ofLp := by
      rw [show u = WithLp.toLp 2 u.ofLp from rfl, Matrix.toEuclideanCLM_toLp]
    rw [EuclideanSpace.inner_eq_star_dotProduct, hu']
    simp only [dotProduct, Matrix.mulVec, Fin.sum_univ_one, Pi.star_apply, RCLike.star_def]
    rw [mul_assoc, hc, mul_one]
  · rintro rfl
    refine ⟨EuclideanSpace.equiv (Fin 1) ℂ |>.symm (fun _ => 1), ?_, ?_⟩
    · simp [EuclideanSpace.norm_eq]
    · simp [Matrix.toEuclideanCLM_toLp, Matrix.mulVec, dotProduct,
        EuclideanSpace.inner_eq_star_dotProduct]


end

/- The derivation must not smuggle in anything the gates do not see, so it
states its own axiom dependency.  This lands in the log gate C keeps, next to
the same question asked of OpenAI's two theorems through a file of theirs. -/
#print axioms scalar_crouzeix
#print axioms numericalRange_fin_one

end Recheck
