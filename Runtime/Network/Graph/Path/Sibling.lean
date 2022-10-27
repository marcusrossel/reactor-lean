import Runtime.Network.Graph.Path.Extends

namespace Network.Graph.Path

-- Note: Every node is its own sibling.
inductive Sibling : Path graph start → Path graph start → Prop
  | nil : Sibling .nil .nil
  | cons : (path₁ ≻ parent) → (path₂ ≻ parent) → Sibling path₁ path₂

infix:35 " ≂ " => Sibling

theorem Sibling.refl : ∀ path : Path graph start, (path ≂ path)
  | .nil => nil
  | .cons _ subpath => by have ⟨_, h⟩ := Extends.cons subpath; exact cons h h 

theorem Sibling.symm : (path₁ ≂ path₂) → (path₂ ≂ path₁)
  | nil => nil
  | cons h₁ h₂ => cons h₂ h₁

theorem Sibling.iff_eq_prefix : (path₁ ≂ path₂) ↔ (path₁.prefix? = path₂.prefix?) := by
  constructor
  case mp =>
    cases path₁ <;> cases path₂
    case nil.nil => simp
    case cons.cons => intro h; cases h; simp_all [Extends.iff_prefix?]
    case nil.cons => intro h; cases h; case _ h _ => have := h.isCons; contradiction
    case cons.nil => intro h; cases h; case _ h   => have := h.isCons; contradiction
  case mpr =>
    intro h
    by_cases hp : path₁.prefix?.isSome
    case inr =>
      have hc₁ := isNil_iff_not_isCons.mpr <| mt isCons_prefix_isSome hp; simp at hc₁
      rw [h] at hp
      have hc₂ := isNil_iff_not_isCons.mpr <| mt isCons_prefix_isSome hp; simp at hc₂
      simp [hc₁, hc₂, Sibling.nil]
    case inl =>
      have ⟨_, hp₁⟩ := Option.isSome_def.mp hp
      have he₁ := Extends.iff_prefix?.mpr hp₁
      rw [h] at hp
      have ⟨_, hp₂⟩ := Option.isSome_def.mp hp
      have he₂ := Extends.iff_prefix?.mpr hp₂
      simp_all
      exact Sibling.cons he₁ he₂

instance : Decidable (path₁ ≂ path₂) :=
  if h : path₁.prefix? = path₂.prefix? 
  then isTrue <| Sibling.iff_eq_prefix.mpr h
  else isFalse <| mt Sibling.iff_eq_prefix.mp h
  
end Network.Graph.Path