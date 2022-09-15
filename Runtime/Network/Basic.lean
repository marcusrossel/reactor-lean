import Runtime.Reactor

namespace Network

abbrev ReactorID := Tree.Path.Rooted

-- A network graph is a tree of reactor ids with a function 
-- that maps each path in that tree to a reactor scheme.
structure Graph where
  tree : Tree
  schemes : (ReactorID tree) → Reactor.Scheme

structure ActionID (graph : Graph) where
  reactor : ReactorID graph.tree
  action : (graph.schemes reactor .actions).vars

-- TODO: This is exactly the same as the instance for `DecidableEq (Σ a : Type, a)`.
instance : DecidableEq (ActionID graph) :=
  fun ⟨a₁, b₁⟩ ⟨a₂, b₂⟩ => 
    if h : a₁ = a₂ then 
      if h' : (h ▸ b₁) = b₂ then
        .isTrue (by subst h h'; rfl)
      else 
        .isFalse (by 
          subst h
          intro hc
          injection hc
          contradiction
        )
    else
      .isFalse (by
        intro hc
        injection hc
        contradiction
      )

structure PortID (kind : Reactor.PortKind) (graph : Graph) where
  reactor : ReactorID graph.tree
  port : (graph.schemes reactor kind).vars

abbrev Graph.subschemes (graph : Graph) (reactorID : ReactorID graph.tree) : graph.tree[reactorID].branches → Reactor.Scheme := 
  fun branch => graph.schemes (reactorID.extend branch)

abbrev Graph.subscheme (graph : Graph) (reactorID : ReactorID graph.tree) (kind : Reactor.InterfaceKind) :=
  ⨄ fun branch => (graph.subschemes reactorID branch) kind

theorem Graph.child_schemes_eq_parent_subschemes {graph : Graph} {child parent : ReactorID graph.tree} (h : child.isChildOf parent) : 
  graph.schemes child = graph.subschemes parent (Tree.Path.Rooted.last child h) := by
  sorry

abbrev Graph.reactionInputScheme (graph : Graph) (reactorID : ReactorID graph.tree) :=
  let localInputs := (graph.schemes reactorID) .inputs
  let nestedOutputs := graph.subscheme reactorID .outputs
  localInputs ⊎ nestedOutputs

abbrev Graph.reactionOutputScheme (graph : Graph) (reactorID : ReactorID graph.tree) :=
  let localOutputs := (graph.schemes reactorID) .outputs
  let nestedInputs := graph.subscheme reactorID .inputs
  localOutputs ⊎ nestedInputs

-- Lean can't "see through" this automatically.
theorem Graph.reactionOutputScheme_local_type (graph : Graph) (reactorID output) :
  (graph.reactionOutputScheme reactorID).type (.inl output) = ((graph.schemes reactorID) .outputs).type output := rfl

abbrev Graph.reactionType (graph : Graph) (reactorID : ReactorID graph.tree) :=
  let localScheme := graph.schemes reactorID
  Reaction (graph.reactionInputScheme reactorID) (graph.reactionOutputScheme reactorID) (localScheme .actions) (localScheme .state)

-- Lean can't automatically infer this automatically.
instance {graph : Graph} {reactorID : ReactorID graph.tree} {reaction : graph.reactionType reactorID} : 
  InjectiveCoe reaction.portSources (graph.reactionInputScheme reactorID).vars :=
  reaction.portSourcesInjCoe

-- Lean can't automatically infer this automatically.
instance {graph : Graph} {reactorID : ReactorID graph.tree} {reaction : graph.reactionType reactorID} : 
  InjectiveCoe reaction.portEffects (graph.reactionOutputScheme reactorID).vars :=
  reaction.portEffectsInjCoe

structure Connection (graph : Graph) where
  output : PortID .output graph
  input : PortID .input graph
  matchingTypes : (graph.schemes output.reactor .outputs).type output.port = (graph.schemes input.reactor .inputs).type input.port

structure _root_.Network extends Graph where
  connections : Array (Connection graph)
  reactions : (id : ReactorID toGraph.tree) → Array (toGraph.reactionType id)

abbrev graph (net : Network) : Graph := net.toGraph

structure ReactionID (net : Network) where
  reactor : ReactorID net.tree
  reactionIdx : Fin (net.reactions reactor).size

abbrev reaction (net : Network) (id : ReactionID net) : net.reactionType id.reactor :=
  (net.reactions id.reactor)[id.reactionIdx]

end Network