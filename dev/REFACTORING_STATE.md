# Stage 3 conversion specification (stateless cutover)

This document is the binding spec for converting all remaining call sites.
The foundation is already in place; read it before editing anything.

## What exists already

- `+yalmip/Session.m` — classdef (handle) holding ALL registry state. Its
  methods implement the former `yalmip('cmd',...)` dispatcher commands.
  Command→method mapping: `dev/session_method_map.json`.
  Creation methods: `S.sdpvar/S.intvar/S.binvar/S.uncvar/S.semivar`.
- `@sdpvar/sdpvarCore.m` — session-aware variable constructor (registration
  via `appendYALMIPvariables(S,...)`). Sets `sess` and `name` fields.
- `@sdpvar/sdpvar.m` — retains ONLY: struct load path, 1-arg copy path,
  internal fast paths (5-9 args, optional trailing Session argument stored
  in the result). Everything else errors `YALMIP:sessionRequired`.
- `extras/intvarCore.m`, `binvarCore.m`, `uncvarCore.m`, `semivarCore.m`.
- Old `extras/intvar.m`, `binvar.m`, `uncvar.m`, `operators/semivar.m` are
  migration-error stubs.
- `extras/expandmodel.m` / `expandrecursive.m` already thread an
  `expansionstate` struct (Stage 1) — they still call `yalmip('...')` and
  need the session threaded as described below.

## Conversion rules

1. **No `yalmip('...')` calls may remain** (the dispatcher `extras/yalmip.m`
   will be deleted). Convert `yalmip('cmd', a, b)` → `S.<method>(a, b)` with
   the method name from `dev/session_method_map.json`.
   Multi-output works: `[mt,vt] = S.getMonomtable()`.

2. **Getting the session `S` in each context**:
   - Inside `@sdpvar/*.m` methods: `S = X.sess;` (direct field access OK).
     For routines with several operands use `S = sessCheck(X,Y);`
     (new helper `@sdpvar/sessCheck.m`, errors on session mismatch and
     returns the non-empty session).
   - Inside `@lmi/*.m`, `@constraint/*.m`, `@optimizer/*.m`: `S = X.sess;`
     (those classes gain a `sess` field; see below).
   - Anywhere else holding a symbolic object: `S = session(X);` — new public
     methods `@sdpvar/session.m`, `@lmi/session.m`, `@constraint/session.m`
     (create them; 3-line methods returning `X.sess`).
   - In the solve pipeline: `S` is threaded as an explicit parameter
     (solvesdp discovers it from `F` and passes it down).
   - In `yalmiptest.m` and demos: create `S = yalmip.Session();` at the top.

3. **Variable creation** in internal code: `sdpvar(...)` → `S.sdpvar(...)`,
   `binvar(...)` → `S.binvar(...)`, etc. Inside `@sdpvar` methods use
   `sdpvarCore(S,...)` directly. Never call `sdpvar/intvar/binvar/...`
   directly — they are error stubs now.

4. **Fast paths**: every `sdpvar(dim1,dim2,vars,basis,...)` call with 5+
   arguments MUST append the session as trailing argument: `..., S`.
   (Without it the result has `sess = []` and fails loudly later.)

5. **Binary operators** (`plus.m minus.m mtimes.m times.m mrdivide.m
   mldivide.m rdivide.m ldivide.m kron.m conv.m deconv.m vertcat.m
   horzcat.m cat.m` and any other method using two sdpvar operands):
   insert `S = sessCheck(X,Y);` (or with the actual operand names) at the
   top and use `S` where a session is needed. Unary methods need nothing
   (sess travels inside the copied struct).

6. **`sess` field on the other classes**:
   - `@constraint/constraint.m`: after `F.Evaluated{1} = Z;` add
     `F.sess = Z.sess;` (Z is the evaluated sdpvar). Replace
     `yalmip('ConstraintID')` with `F.sess.lmiid()`. Same in the chaining
     operators `@constraint/{ge,le,gt,lt}.m` using `X.sess.lmiid()`.
   - `@lmi/lmi.m`: after the fresh prototype is created set `F.sess = [];`
     then in the class-dispatch branches set `F.sess = X.sess` (sdpvar
     case), `F.sess = Fi{1}.sess` (char/parse case after eval), and for the
     constraint case after `getlist` set `F.sess = X.sess`. Replace
     `yalmip('lmiid')` with `F.sess.lmiid()`.
   - All `@lmi` methods that build result lmis from operands: sess travels
     via struct copy/mutation automatically; where an lmi is built from
     scratch use `lmiCore(S,...)`-style or copy `.sess` from an operand.
   - `@optimizer/optimizer.m`: store `P.sess = session(<constraints>);`
     and use it in presolve/subsref/solve.
   - `@blkvar`, `@ndsdpvar`: their structs wrap sdpvar data — copy `sess`
     from operands where they are built; creation entry points gain a
     leading session (see `ndsdpvarCore(S,...)` called from sdpvarCore).

7. **Solution evaluation (the former "last solution" global)**:
   - `optimize(F,obj,options)` keeps its signature. `extras/solvesdp.m`
     discovers `S = session(F)` (or `S = session(F(i))` per element / from
     `h` when F is empty) and threads it everywhere; at the end it attaches
     `diagnostic.eval = S.evalSnapshot();` before returning so that
     `value(x, sol)` and `dual(F, sol)` work.
   - `value(X)` → `value(X, sol)`; `dual(F)` → `dual(F, sol)`;
     `assign(X, sol)` keeps its name. Implementations read the payload from
     `sol.eval` (fields: monomtable, variabletype, variables, optvar,
     values, duals_index, duals_data) instead of `yalmip('getsolution')` /
     `yalmip('monomtable')`. `value(X)` with one argument errors with
     `YALMIP:sessionRequired` and a message telling the user to pass the
     solution: `v = value(x, sol)`.
   - Internal callers of `value(...)` (modules, displays): obtain the
     solution struct they mean (usually the local `output`/`diagnostic` of
     the solve in scope) and pass it: `value(expr, sol)`.

8. **Version**: `yalmip('ver')` / `yalmip('version')` → new function
   `yalmipversion()` (create `extras/yalmipversion.m` returning
   `'20250626'`).

9. **sdisplay**: replace the `evalin('caller','whos')` name inference with
   the embedded display name: variables created via
   `S.sdpvar("x",[3 1])` carry `.name`; display as `x(1)`, `x(2)`...
   Fall back to generic names when `.name` is empty.

10. **Solver wrappers** (`solvers/call*.m`): receive the session inside
    `interfacedata` (`compileinterfacedata` stamps
    `interfacedata.sess = S`). Replace any `yalmip('...')` calls with
    `interfacedata.sess.<method>(...)`.

11. **expandmodel/expandrecursive**: add a trailing `S` argument (threaded
    from compileinterfacedata); replace their `yalmip('...')` calls with
    `S.<method>(...)`. The `expansionstate` struct from Stage 1 stays.

12. **Persistent-related helpers already converted** (do not re-touch):
    EvalMemo memoization, expansion state, solver cache is now
    `S.solverCache` (struct with fields CACHED_SOLVERS, allsolvers,
    EXISTTIME, NCHECKS) — replaces the persistent caches in
    `compileinterfacedata.m` and `solvesdp.m`.

## Test migration (dev/)

- At the top of each test function (or setup): `S = yalmip.Session();`
- `sdpvar(...)` → `S.sdpvar(...)`, `intvar` → `S.intvar`, `binvar` →
  `S.binvar`, `semivar` → `S.semivar`, `uncvar` → `S.uncvar`.
- `optimize(F,...)` stays; capture `sol = optimize(F,...)` and replace
  `value(x)` → `value(x,sol)`, `dual(F)` → `dual(F,sol)`.
- `yalmip('clear')` → delete the line (no global state to clear) unless the
  test specifically needs a fresh registry — then create a new session and
  recreate variables.
- `yalmip('version')` → `yalmipversion()`.
- Any other `yalmip('cmd',...)` in tests: use the session method map
  against a session created in the test.
- The old `yalmip('getinternalsdpvarstate')`/`setinternalsdpvarstate` pairs
  (globlib tests) → `st = S.snapshotState(); ... S.restoreState(st);`
