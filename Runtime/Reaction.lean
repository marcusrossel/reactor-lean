import Runtime.Time
import Runtime.Interface
import Runtime.Utilities

structure Reaction.Event (σAction : Interface.Scheme) (min : Time) where 
  action : σAction.vars
  time   : Time.From min
  value  : σAction.type action

instance : LE (Reaction.Event σAction time) where
  le e₁ e₂ := e₁.time ≤ e₂.time

instance : Decidable ((e₁ : Reaction.Event σAction time) ≤ e₂) := by
  simp [LE.le]; infer_instance

namespace ReactionM
open Reaction

structure Input (σPortSource σActionSource σState σParam : Interface.Scheme) where
  ports          : Interface? σPortSource
  actions        : Interface? σActionSource
  state          : Interface σState
  params         : Interface σParam
  tag            : Tag
  physicalOffset : Duration

structure Output (σPortEffect σActionEffect σState : Interface.Scheme) (min : Time) where
  ports  : Interface? σPortEffect := Interface?.empty
  state  : Interface σState
  events : SortedArray (Event σActionEffect min) := #[]#

abbrev _root_.ReactionT (σPortSource σPortEffect σActionSource σActionEffect σState σParam : Interface.Scheme) (m : Type → Type) (α : Type) := 
  (input : Input σPortSource σActionSource σState σParam) → m (Output σPortEffect σActionEffect σState input.tag.time × α)

abbrev _root_.ReactionM (σPortSource σPortEffect σActionSource σActionEffect σState σParam : Interface.Scheme) := 
  ReactionT σPortSource σPortEffect σActionSource σActionEffect σState σParam IO

variable {σInput σOutput σAction σPortSource σPortEffect σActionSource σActionEffect σState σParam : Interface.Scheme} 

def Output.merge (o₁ o₂ : ReactionM.Output σPortEffect σActionEffect σState time) : Output σPortEffect σActionEffect σState time where
  ports  := o₁.ports.merge o₂.ports
  state  := o₂.state
  events := o₁.events.merge o₂.events

def Input.noop (input : ReactionM.Input σPortSource σActionSource σState σParam) : Output σPortEffect σActionEffect σState input.tag.time where 
  state := input.state 

instance : Monad (ReactionM σPortSource σPortEffect σActionSource σActionEffect σState σParam) where
  pure a input := do
    let output := input.noop
    return (output, a)
  map f ma input := do
    let (output, a) ← ma input
    return (output, f a)
  seq mf ma input₁ := do
    let (output₁, a) ← ma () input₁
    let input₂ := { input₁ with state := output₁.state }
    let (output₂, f) ← mf input₂
    return (output₂, f a)
  bind ma f input₁ := do
    let (output₁, a) ← ma input₁
    let input₂ := { input₁ with state := output₁.state }
    let (output₂, b) ← f a input₂
    let output := output₁.merge output₂
    return (output, b)

instance : MonadLift IO (ReactionM σPortSource σPortEffect σActionSource σActionEffect σState σParam) where
  monadLift io input world := 
    match io world with 
    | .error e world' => .error e world'
    | .ok    a world' => .ok (input.noop, a) world'

def getInput (port : σPortSource.vars) : ReactionM σPortSource σPortEffect σActionSource σActionEffect σState σParam (Option $ σPortSource.type port) :=
  fun input => return (input.noop, input.ports port)

def getState (stv : σState.vars) : ReactionM σPortSource σPortEffect σActionSource σActionEffect σState σParam (σState.type stv) :=
  fun input => return (input.noop, input.state stv)

def getAction (action : σActionSource.vars) : ReactionM σPortSource σPortEffect σActionSource σActionEffect σState σParam (Option $ σActionSource.type action) :=
  fun input => return (input.noop, input.actions action)

def getParam (param : σParam.vars) : ReactionM σPortSource σPortEffect σActionSource σActionEffect σState σParam (σParam.type param) :=
  fun input => return (input.noop, input.params param)

def getTag : ReactionM σPortSource σPortEffect σActionSource σActionEffect σState σParam Tag := 
  fun input => return (input.noop, input.tag)

def getLogicalTime : ReactionM σPortSource σPortEffect σActionSource σActionEffect σState σParam Time := 
  return (← getTag).time

def getPhysicalTime : ReactionM σPortSource σPortEffect σActionSource σActionEffect σState σParam Time :=
  fun input => return (input.noop, (← Time.now) - input.physicalOffset)

def setOutput (port : σPortEffect.vars) (v : σPortEffect.type port) : ReactionM σPortSource σPortEffect σActionSource σActionEffect σState σParam Unit :=
  fun input => 
    let ports := fun p => if h : p = port then some (h ▸ v) else none
    let output := { ports := ports, state := input.state }
    return (output, ())

def setState (stv : σState.vars) (v : σState.type stv) : ReactionM σPortSource σPortEffect σActionSource σActionEffect σState σParam Unit :=
  fun input =>
    let state := fun s => if h : s = stv then h ▸ v else input.state s
    let output := { state := state }
    return (output, ())

def schedule (action : σActionEffect.vars) (delay : Duration) (v : σActionEffect.type action) : ReactionM σPortSource σPortEffect σActionSource σActionEffect σState σParam Unit := 
  fun input => 
    let time := input.tag.time.advance delay
    let event : Event σActionEffect input.tag.time := { action := action, time := time, value := v }
    let output := { state := input.state, events := #[event]# }
    return (output, ())

end ReactionM

namespace Reaction

inductive Trigger (Port Action Timer : Type)
  | startup
  | shutdown
  | port (p : Port)
  | action (a : Action)
  | timer (t : Timer)

open Reaction in
structure _root_.Reaction (σInput σOutput σAction σState σParam : Interface.Scheme) (TimerNames : Type) where
  portSources : Type
  portEffects : Type 
  actionSources : Type
  actionEffects : Type
  triggers : Array (Trigger portSources actionSources TimerNames)
  [portSourcesDecEq : DecidableEq portSources]
  [portEffectsDecEq : DecidableEq portEffects]
  [actionSourcesDecEq : DecidableEq actionSources]
  [actionEffectsDecEq : DecidableEq actionEffects]
  [portSourcesInjCoe : InjectiveCoe portSources σInput.vars]
  [portEffectsInjCoe : InjectiveCoe portEffects σOutput.vars]
  [actionSourcesInjCoe : InjectiveCoe actionSources σAction.vars]
  [actionEffectsInjCoe : InjectiveCoe actionEffects σAction.vars]
  body : ReactionM (σInput.restrict portSources) (σOutput.restrict portEffects) (σAction.restrict actionSources) (σAction.restrict actionEffects) σState σParam Unit

open Reaction in
attribute [instance] portSourcesDecEq portEffectsDecEq actionSourcesDecEq actionEffectsDecEq portSourcesInjCoe portEffectsInjCoe actionSourcesInjCoe actionEffectsInjCoe

abbrev outputType (rcn : Reaction σInput σOutput σAction σState σParam TimerNames) :=
  ReactionM.Output (σOutput.restrict rcn.portEffects) (σAction.restrict rcn.actionEffects) σState 

def run 
  (rcn : Reaction σInput σOutput σAction σState σParam TimerNames) 
  (inputs : Interface? σInput) (actions : Interface? σAction) 
  (state : Interface σState) (params : Interface σParam) 
  (tag : Tag) (physicalOffset : Duration) : 
  IO (rcn.outputType tag.time) := do
  let ⟨output, _⟩ ← rcn.body { 
    ports := (inputs ·), actions := (actions ·), 
    state := state, params := params, 
    tag := tag, physicalOffset := physicalOffset 
  }
  return output

end Reaction