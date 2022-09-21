import Runtime

/-
network {

  main reactor Main {
    input  := [i1 : Nat,    i2 : String]
    output := [o1 : Bool,   o2 : Unit]
    action := [a1 : String, a2 : Bool × Nat]
    state  := [s1 : Int,    s2 : Bool]
    nested := [x : Sub, y : Sub]
    connections := [x.o1 → y.i3, o1 → x.i2]

    reaction first (i1, !i2, @a1, x.o1) → (o1, x.i2) { 
      let i ← getInput i1
      let i' := (i.getD 0) + 1
      let b := if i' = 0 then true else false
      setOutput o1 b
      setOutput o1 true
      setState s1 (-1 : Int)
      match ← getState s1 with
      | none => return
      | some v => 
        setState s1 (v * 12)
        setState s2 false
    }

    reaction second (i1, !@a1) → (o1, @a2) { 
      let _ := (← getAction a1).map (· ++ "suffix")
      let _ ← getInput i1
      schedule a2 112 "First"
      schedule a2 113 "Second"
      IO.println "Hello"
      let dir := IO.appDir
      let dir' ← IO.appDir
    }
  }

  reactor Sub {
    input  := [i1 : Nat, i2 : Bool, i3 : Unit]
    output := [o1 : Unit]
    action := []
    state  := []
    nested := [a : Grand, b : Grand]
    connections := []
  }

  reactor Grand {
    input  := []
    output := []
    action := []
    state  := []
    nested := []
    connections := []
  }
}
-/

inductive Classes 
  | Main
  | Sub
  | Grand

inductive Main.Input  | i1 | i2 deriving DecidableEq
inductive Main.Output | o1 | o2 deriving DecidableEq
inductive Main.Action | a1 | a2 deriving DecidableEq
inductive Main.State  | s1 | s2 deriving DecidableEq
inductive Main.Nested | x  | y  deriving DecidableEq

inductive Main.Reaction1.PortSource   | i1 | i2 | x.o1 deriving DecidableEq
inductive Main.Reaction1.PortEffect   | o1 | x.i2 deriving DecidableEq
inductive Main.Reaction1.ActionSource | a1 deriving DecidableEq
inductive Main.Reaction1.ActionEffect deriving DecidableEq

inductive Main.Reaction2.PortSource   | i1 deriving DecidableEq
inductive Main.Reaction2.PortEffect   | o1 | o2 deriving DecidableEq
inductive Main.Reaction2.ActionSource | a1 deriving DecidableEq
inductive Main.Reaction2.ActionEffect | a2 deriving DecidableEq

def Main.scheme : Reactor.Scheme Classes := {
  interface := fun
    | .inputs => { 
      vars := Input
      type := fun
        | .i1 => Nat
        | .i2 => String
    }
    | .outputs => {
      vars := Output
      type := fun
        | .o1 => Bool
        | .o2 => Unit
    }
    | .actions => {
      vars := Action
      type := fun
        | .a1 => String
        | .a2 => Bool × Nat
    }
    | .state => {
      vars := State
      type := fun
        | .s1 => Int
        | .s2 => Bool
    }
  children := Main.Nested
  «class» := fun 
    | .x => .Sub
    | .y => .Sub
}

inductive Sub.Input  | i1 | i2 | i3 deriving DecidableEq
inductive Sub.Output | o1 deriving DecidableEq
inductive Sub.Action deriving DecidableEq
inductive Sub.State  deriving DecidableEq
inductive Sub.Nested | a | b deriving DecidableEq

def Sub.scheme : Reactor.Scheme Classes := {
  interface := fun
    | .inputs => { 
      vars := Input
      type := fun
        | .i1 => Nat
        | .i2 => Bool
        | .i3 => Unit
    }
    | .outputs => {
      vars := Output
      type := fun
        | .o1 => Unit
    }
    | .actions => {
      vars := Action
      type := (·.rec)
    }
    | .state => {
      vars := State
      type := (·.rec)
    }
  children := Sub.Nested
  «class» := fun
    | .a => .Grand
    | .b => .Grand
}

inductive Grand.Input  deriving DecidableEq
inductive Grand.Output deriving DecidableEq
inductive Grand.Action deriving DecidableEq
inductive Grand.State  deriving DecidableEq
inductive Grand.Nested deriving DecidableEq

def Grand.scheme : Reactor.Scheme Classes := {
  interface := fun
    | .inputs => { 
      vars := Input
      type := (·.rec)
    }
    | .outputs => {
      vars := Output
      type := (·.rec)
    }
    | .actions => {
      vars := Action
      type := (·.rec)
    }
    | .state => {
      vars := State
      type := (·.rec)
    }
  children := Empty
  «class» := (·.rec)
}

def graph : Network.Graph := {
  classes := Classes
  root := .Main
  schemes := fun
    | .Main => Main.scheme
    | .Sub => Sub.scheme
    | .Grand => Grand.scheme
}

instance : InjectiveCoe Main.Reaction1.PortSource (graph.reactionInputScheme .Main).vars := {
  coe := sorry
  inv := sorry
  invInj := sorry
  coeInvId := sorry
}

instance : InjectiveCoe Main.Reaction1.PortEffect (graph.reactionOutputScheme .Main).vars := {
  coe := sorry
  inv := sorry
  invInj := sorry
  coeInvId := sorry
}

instance : InjectiveCoe Main.Reaction1.ActionSource (graph.schemes .Main |>.interface .actions |>.vars) := {
  coe := sorry
  inv := sorry
  invInj := sorry
  coeInvId := sorry
}

instance : InjectiveCoe Main.Reaction1.ActionEffect (graph.schemes .Main |>.interface .actions |>.vars) := {
  coe := sorry
  inv := sorry
  invInj := sorry
  coeInvId := sorry
}

instance : InjectiveCoe Main.Reaction2.PortSource (graph.reactionInputScheme .Main).vars := {
  coe := sorry
  inv := sorry
  invInj := sorry
  coeInvId := sorry
}

instance : InjectiveCoe Main.Reaction2.PortEffect (graph.reactionOutputScheme .Main).vars := {
  coe := sorry
  inv := sorry
  invInj := sorry
  coeInvId := sorry
}

instance : InjectiveCoe Main.Reaction2.ActionSource (graph.schemes .Main |>.interface .actions |>.vars) := {
  coe := sorry
  inv := sorry
  invInj := sorry
  coeInvId := sorry
}

instance : InjectiveCoe Main.Reaction2.ActionEffect (graph.schemes .Main |>.interface .actions |>.vars) := {
  coe := sorry
  inv := sorry
  invInj := sorry
  coeInvId := sorry
}

def network : Network := {
  toGraph := graph
  reactions := fun
    | .Main => #[
      {
        portSources   := Main.Reaction1.PortSource
        portEffects   := Main.Reaction1.PortEffect
        actionSources := Main.Reaction1.ActionSource
        actionEffects := Main.Reaction1.ActionEffect
        triggers      := #[.port .i2]
        body          := sorry
      },
      {
        portSources   := Main.Reaction2.PortSource
        portEffects   := Main.Reaction2.PortEffect
        actionSources := Main.Reaction2.ActionSource
        actionEffects := Main.Reaction2.ActionEffect
        triggers      := #[.action .a1]
        body          := sorry
      }
    ]
    | .Sub => #[]
    | .Grand => #[]
  connections := {
    outForIn := fun input => -- TODO: Try to get pattern matching working for this.
      if      input = ⟨.cons .y .nil, .i3⟩ then some ⟨.cons .x .nil, .o1⟩
      else if input = ⟨.cons .x .nil, .i2⟩ then some ⟨.nil, .o1⟩
      else                                      none
    eqType := sorry
  }
}

def main : IO Unit := do
  sorry --exec.run #[] 0