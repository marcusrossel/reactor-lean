import Runtime.Network.Graph

namespace Network

-- instance : Ord (Network.Event tree time) where
--   compare e₁ e₂ := compare e₁.local.time e₂.local.time

-- instance : DecidableEq (ActionID tree) := sorry

structure _root_.Network where
  tree : Tree
  reactions : (id : ReactorID tree) → Array $ tree[id].reactionType
  connections : Array (Connection tree)
  reactors :  (id : ReactorID tree) → Reactor $ tree[id].scheme
  tag : Tag
  events : SortedArray (Event tree tag.time) 

structure ReactionID (ν : Network) where
  reactor : ReactorID ν.tree
  reactionIdx : Fin (ν.reactions reactor).size

def reaction (ν : Network) (id : ReactionID ν) : ν.tree[id.reactor].reactionType :=
  (ν.reactions id.reactor)[id.reactionIdx]

structure Next (ν : Network) (min : Time) where
  events : Array (Event ν.tree ν.tag.time)
  remaining : SortedArray (Event ν.tree min)

def nextTag (ν : Network) : Option (Tag.From ν.tag.time) :=
  match ν.events.get? 0 with
  | none => none
  | some nextEvent => ν.tag.advance nextEvent.local.time

def next (ν : Network) (time : Time.From ν.tag.time) : Next ν time :=
  -- TODO: somehow use the fact that the given time is in fact the 
  --       time of the prefix of `ν.events` to show that the times 
  --       of the events in `later` and `postponed` are `≥ time`.
  let ⟨candidates, later⟩ := ν.events.split (·.local.time.val = time)  
  let ⟨current, postponed⟩ := candidates.unique (·.actionID)
  let postponed' : SortedArray _ := ⟨postponed, sorry⟩
  let remaining := postponed'.append later sorry
  {
    events := current,
    remaining := 
      have : Coe (Event ν.tree ν.tag.time) (Event ν.tree time) := sorry -- This is not provable!
      remaining.coe sorry
  }

def triggers {ν : Network} {id : ReactorID ν.tree} (rtr : Reactor (ν.tree[id]).scheme) (rcn : (ν.tree[id]).reactionType) : Bool :=
  rcn.triggers.any fun trigger =>
    match trigger with
    | .port   port   => true -- rtr.inputs.isPresent port
    | .action action => true -- rtr.actions.isPresent action

-- Note: Running a reactor at a time isnt possible. Eg:
--       rcn1 -> subreactor.input -> subreaction -> subreactor.output -> rcn2
def instantaneousRun (ν : Network) (topo : Array (ReactionID ν)) : Network := Id.run do
  for reactionID in topo do
    let reaction := ν.reaction reactionID
    let reactor := ν.reactors reactionID.reactor
    if triggers reactor reaction then
      sorry
    else
      sorry
  sorry

def actionMapForEvents {ν : Network} (events : Array $ Event ν.tree ν.tag.time) : 
  (id : ActionID ν.tree) → Option (((ν.tree[id.reactor]).scheme .actions).type id.action) := 
  fun id => 
    match h : events.findP? (·.actionID = id) with
    | none => none
    | some event =>
      have h₁ : id.reactor = event.reactor := by have h' := Array.findP?_property h; simp at h'; rw [←h']; rfl
      have h₂ : HEq id.action event.local.action := by have h' := Array.findP?_property h; simp at h'; rw [←h']; simp; rfl
      -- (eq_of_heq h₂) ▸ h₁ ▸ event.local.value
      sorry

partial def run (ν : Network) : Network :=
  let topo : Array (ReactionID ν) := sorry
  let ν' := ν.instantaneousRun topo
  match ν'.nextTag with
  | none => ν'
  | some nextTag => 
    let next := ν'.next nextTag.time
    let actionMap := actionMapForEvents next.events 
    run { ν' with
      reactors := fun id => fun
        | .inputs =>  Interface.empty
        | .outputs => Interface.empty
        | .actions => (actionMap ⟨id, ·⟩)
        | .state =>   (ν'.reactors id) .state
      tag := nextTag
      events := next.remaining
    }  

end Network