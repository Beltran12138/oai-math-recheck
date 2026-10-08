/-
Dump the statement of one or more theorems, plus every `OAI.*` constant that
statement depends on, as one line per constant.

  lake env lean --run StatementDump.lean <module> <theorem>...

Run it once against the comparator challenge module and once against OpenAI's
solution module, then diff the two outputs.  That is gate C for families whose
statement contains a `structure`: re-declaring a structure in our own file
makes a new type, so the copy-and-defeq check used for family 325 cannot work.

What is compared, per constant: kind, universe parameters, type, and for
definitions the body.  Theorem bodies are never followed -- the challenge's is
`sorry` and the solution's is the proof, and neither is the statement.
Constants outside `OAI` (Mathlib, core) are not dumped: both modules are built
against the same pinned Mathlib, so those are the same by construction.
-/
import Lean
open Lean

def kindOf : ConstantInfo → String
  | .axiomInfo _ => "axiom"
  | .defnInfo _ => "def"
  | .thmInfo _ => "theorem"
  | .opaqueInfo _ => "opaque"
  | .quotInfo _ => "quot"
  | .inductInfo _ => "inductive"
  | .ctorInfo _ => "ctor"
  | .recInfo _ => "rec"

/-- Constants this one points at that belong to the statement: the type always,
the body only for definitions, the constructors for inductive types. -/
def refsOf (ci : ConstantInfo) : Array Name :=
  let fromType := ci.type.getUsedConstants
  match ci with
  | .defnInfo d => fromType ++ d.value.getUsedConstants
  | .opaqueInfo d => fromType ++ d.value.getUsedConstants
  | .inductInfo d => fromType ++ d.ctors.toArray
  | _ => fromType

def line (ci : ConstantInfo) : String :=
  let base := s!"{ci.name}\t{kindOf ci}\t{ci.levelParams}\ttype={ci.type.dbgToString}"
  match ci with
  | .defnInfo d => base ++ s!"\tvalue={d.value.dbgToString}"
  | .opaqueInfo d => base ++ s!"\tvalue={d.value.dbgToString}"
  | .inductInfo d =>
    base ++ s!"\tparams={d.numParams}\tindices={d.numIndices}\tctors={d.ctors}\trec={d.isRec}"
  | _ => base

unsafe def main (args : List String) : IO UInt32 := do
  let some modStr := args.head?
    | IO.eprintln "usage: StatementDump <module> <theorem>..."; return 64
  let roots := args.tail.map String.toName
  if roots.isEmpty then
    IO.eprintln "no theorem names given"; return 64
  initSearchPath (← findSysroot)
  enableInitializersExecution
  let env ← importModules #[{ module := modStr.toName }] {}
  let mut seen : NameSet := {}
  let mut todo : Array Name := roots.toArray
  let mut out : Array String := #[]
  let mut missing := 0
  while todo.size > 0 do
    let n := todo.back!
    todo := todo.pop
    if seen.contains n then continue
    seen := seen.insert n
    match env.find? n with
    | none =>
      out := out.push s!"{n}\tMISSING"
      missing := missing + 1
    | some ci =>
      out := out.push (line ci)
      for r in refsOf ci do
        if r.getRoot == `OAI && !seen.contains r then
          todo := todo.push r
  for l in out.qsort (· < ·) do
    IO.println l
  IO.eprintln s!"{out.size} constants dumped from {modStr}, {missing} missing"
  return (if missing == 0 then 0 else 1)
