# YALMIP stateless refactoring — architecture notes

This file describes how the library is organised **after** the stateless
cutover (branch `refactor/stateless`). For the user-facing old-to-new API
table, see [MIGRATION.md](MIGRATION.md).

## 1. Goal: no hidden state

The upstream design kept all modelling state in three places:

* the central dispatcher `yalmip('cmd', ...)` with `persistent` state,
* `global` declarations in ~46 files (expansion state, callback memoisation,
  third-party handshakes),
* scattered `persistent` caches (solver lists, SOS kernels, random hashes,
  node keepers, ...).

The refactored tree has none of that:

```
grep -rn "^\s*global\b"     --include=*.m . # 0 hits outside dev/
grep -rn "^\s*persistent\b" --include=*.m . # 0 hits outside dev/
grep -rn "yalmip('"         --include=*.m . # 0 hits outside dev/
```

`python3 dev/audit_stateless.py` enforces this (and that the old dispatcher
file `extras/yalmip.m` stays deleted) and is part of the acceptance gate.

## 2. `yalmip.Session` — the single state carrier

`+yalmip/Session.m` is a `classdef (handle)` owning everything that used to be
global: the monomial table and its hash, variable type/registry lists (int,
bin, semicont, uncertain, parameter, extended, auxiliary, logic),
`ExtendedMap`/`ExtendedMapHashes`, `DependencyMap`, SOS data, solution stack and
dual storage, the LMI id counter, bounds, preferred solver, display names and the
solver cache (`S.solverCache`, which also de-duplicated the two copies that used
to live in `compileinterfacedata.m` and `solvesdp.m`).

Every former dispatcher command is now a named method. The mapping is kept in
`dev/session_method_map.json`. Internally the methods are one-liners that call
`+yalmip/dispatch.m`, which holds the original `switch` body verbatim with
`internal_sdpvarstate`/`internal_setstate` replaced by the session handle `S`.
Argument indexing is preserved (`varargin{1}` is the command string), so the
conversion stayed mechanical and reviewable.

Public creation entry points:

```matlab
S = yalmip.Session();
x = S.sdpvar(3,1);                 % also S.sdpvar("x",3,1) for a display name
P = S.sdpvar(3,3,'symmetric');
z = S.intvar(2,2);  b = S.binvar(1,1);
w = S.uncvar(2,1);  q = S.semivar(2,2);  p = S.parvar(1,3);
```

## 3. Symbolic objects carry their session

`sdpvar`, `lmi`, `constraint`, `optimizer`, `blkvar` and `ndsdpvar` objects have
a `sess` property pointing at the owning session. That is what keeps
`optimize(F,obj)` signature-compatible: the pipeline discovers the session from
the data it is handed and threads it explicitly from there.

How to obtain the session, by context:

| Context | How |
|---|---|
| inside `@sdpvar/*.m` methods | `S = X.sess;` (direct field access; `isfield`/`session()` do not work on legacy-class objects) |
| multi-operand `@sdpvar` methods | `S = sessCheck(X,Y);` — errors `YALMIP:sessionMismatch` on cross-session operands |
| `@lmi`, `@constraint`, `@optimizer` methods | `S = X.sess;` |
| anywhere else holding a symbolic object | `S = session(X);` or the tolerant `S = sessOf(X);` |
| solve pipeline | `S` is an explicit parameter, discovered in `solvesdp`/`compileinterfacedata` |
| solver wrappers | `interfacedata.sess` (stamped by `compileinterfacedata`) |

`extras/sessOf.m` is the single safe accessor for cross-class reads: legacy-class
dot access from *outside* the class folder goes through the object's overloaded
`subsref`, so `X.sess` written in a plain function can fail — `sessOf` hides that.

## 4. Construction paths and the dispatch trap

A call like `sdpvar(S, ...)` would be re-dispatched to the `Session.sdpvar`
method (MATLAB picks the dominant class among *all* arguments), producing
infinite recursion. Two routes avoid it:

* **User/registry creation**: `S.sdpvar(args...)` →
  `sdpvar(args..., 'session', {S})` → the keyword branch of `@sdpvar/sdpvar.m`
  unpacks the cell payload (no object in the argument list → no dispatch) and
  performs registration through `appendYALMIPvariables(S, ...)`.
* **Internal fast paths** (variables built from known ids/basis, no
  registration): call `sdpvarFast(...)` from `extras/`, which lives outside the
  class folder so a trailing session argument is not re-dispatched. It finishes
  via `sdpvar('finalize', struct)` because `class(s,'sdpvar')` is only legal
  inside `@sdpvar`.

Any `sdpvar(dim1,dim2,vars,basis,...)` style call must therefore pass the
session, otherwise the result silently has `sess = []` and fails later.

## 5. Solution evaluation without a "last solution"

`optimize`/`solvesdp` still return the diagnostic struct, now carrying an
evaluation snapshot:

```matlab
sol = optimize(F,obj,options);
v = value(x, sol);      z = dual(F, sol);     assign(x, v, sol)
```

`solvesdp` attaches `diagnostic.eval = S.evalSnapshot()` **after** dual recovery,
because associated duals (from `dualize`/`primalize`) are folded into the solution
values inside `setdual`. The snapshot holds `monomtable`, `variabletype`,
`variables`, `optvar`, `values`, `duals_index`, `duals_data`.

Consequences worth knowing:

* `value(x)` / `dual(F)` with a single argument error with
  `YALMIP:sessionRequired` and a pointer to the new form.
* `assign(x, v)` no longer writes anywhere global — it returns the updated
  payload; internal code that used it to publish values now builds/returns one.
* Warm-start cannot read a previous solution from the library; the initial-point
  paths simply see "no values" (NaN → 0) as they did before any solve.

## 6. Callback memoisation, expansion state, non-state `evalin`

* `+yalmip/EvalMemo.m` (handle) replaces the `latest_*` global family: solver
  wrappers create one instance and close over it
  (`fun = @(x) fmincon_fun(x,model,memo);`). Interfaces that only accept a
  function *name* dropped memoisation entirely (a performance-only loss).
* Model-expansion bookkeeping (`ALREADY_MODELLED`, marker variables, GP flags,
  ...) travels in an `expansionstate` struct created by `expandmodel` and passed
  through `expandrecursive` (`defaultexpansionstate.m`).
* The remaining `evalin('caller', ...)` uses are not state channels:
  `extras/define.m` (user-defined operator strings), `@sdpvar/sym.m` (Symbolic
  Toolbox interop), `@lmi/lmi.m` (string-parsed constraints) and the two
  workspace-inspection diagnostics `S.clear()` / `S.info()` in
  `+yalmip/dispatch.m`, which kept their upstream behaviour of listing and
  clearing `sdpvar`/`lmi` variables in the caller's workspace.
* `sdisplay` uses the display name captured at creation
  (`S.sdpvar("x",[3 1])` → `x(1), x(2), ...`) instead of sniffing the caller's
  workspace, and falls back to generic names when no name was given.

## 7. Version and clear

`yalmip('version')` → `yalmipversion()` (`extras/yalmipversion.m`).
`yalmip('clear')` is gone; `S.clear()` resets the session registry (it still
clears `sdpvar`/`lmi` variables in the caller's workspace, as the old command
did). Prefer simply creating a new session. Registry save/restore for tests and
serialisation uses `S.snapshotState()` / `S.restoreState(s)`.

## 8. Verification

The acceptance gate for every stage is a per-test comparison against the
Stage 0 baseline XMLs in `dev/baseline/` — no new failures/errors allowed, the
pre-existing environment failures (SeDuMi/SDPT3/MPT missing, R2026b `norm` on
N-D arrays, renamed solver properties) are expected.

```bash
export MOSEKLM_LICENSE_FILE=~/mosek/mosek.lic
/opt/MATLAB/R2026b/bin/matlab -batch "addpath(genpath(pwd)); addpath('/opt/mosek/11.2/toolbox/r2019b'); run_stage('stageX',{suites})"
```

Stage 3 closed at 327 passed / 34 pre-existing failures, 0 new.
