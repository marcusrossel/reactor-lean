import Runtime.Execution.Basic

namespace Execution

open Network Graph
open Class (Reaction)

structure ReactionOutput (exec : Executable net) where
  reactor : ReactorId net
  reaction : Reaction reactor.class
  raw : reaction.val.outputType exec.time

namespace ReactionOutput

variable {exec : Executable net}

def fromRaw {reactor : ReactorId net} {reaction : Reaction reactor.class} (raw : reaction.val.outputType exec.time) : ReactionOutput exec :=
  { reactor, reaction, raw }

def stopRequested (output : ReactionOutput exec) := output.raw.stopRequested

def writtenPortsWithDelayedConnections (output : ReactionOutput exec) : Array (PortId net .output) :=
  output.raw.writtenPorts.filterMap fun port =>
    match output.reaction.subPE.coe port with
    | .inr _ => none
    | .inl port =>
      let id : PortId net .output := ⟨output.reactor, port⟩
      if id.hasDelayedConnection then id else none

def «local» (output : ReactionOutput exec) (port : output.reactor.outputs.vars) : Option (output.reactor.outputs.type port) :=
  match h : output.reaction.subPE.inv (.inl port) with
  | none => none -- independent port
  | some port' => output.reaction.subPE.invEqType h ▸ output.raw.ports port'

-- This function implements the core of the `child` function below.
-- It's only missing some type casts for the `port` (and consequently the return type).
private def child' (output : ReactionOutput exec) {child : ReactorId.Child output.reactor} (port : (child.class.class.interface .inputs).vars) : Option (child.class.class.interface .inputs |>.type port) :=
  match h : output.reaction.subPE.inv (.inr ⟨child.class, port⟩) with
  | none => none -- independent port
  | some port' => output.reaction.subPE.invEqType h ▸ output.raw.ports port'

def child (output : ReactionOutput exec) {child : ReactorId.Child output.reactor} (port : child.val.inputs.vars) : Option (child.val.inputs.type port) :=
  have h₁ := by rw [Graph.Path.Child.class_eq_class]
  have h₂ := by congr; apply Graph.Path.Child.class_eq_class; apply cast_heq
  output.child' (port |> cast h₁) |> cast h₂

def actionEvents (output : ReactionOutput exec) : Queue (Event net) exec.time :=
  -- TODO: Moving this into a where-clause doesn't allow us to unfold it in the proof below.
  let convertEvent event :=
    .action
      event.time
      ⟨output.reactor, output.reaction.subAE.coe event.action⟩
      (output.reaction.subAE.coeEqType ▸ event.value)
  output.raw.events.map convertEvent (by simp [EventType.time, Event.time])

end ReactionOutput
end Execution
