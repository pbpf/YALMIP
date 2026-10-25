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

---

## HANDOFF (session boundary) — Stage 3 integration state

LATEST STATE (end of session): creation chain now reaches
`sdpvar.m` keyword branch -> inlined core -> `appendYALMIPvariables(S,...)`.
Current blocking error (exact stack):

    Error in yalmip.Session/getMonomtable
    Error in sdpvar (line 334)          % [mt,variabletype,...] = S.getMonomtable();
    Error in yalmip.Session/sdpvar (line 106)
    "Variable output array 'varargout' must be a cell array."

Diagnosis hint: the one-liner is
`function varargout = getMonomtable(obj, varargin); varargout = yalmip.dispatch(obj,'monomtable',varargin{:}); end`
Inspect `+yalmip/dispatch.m` case 'monomtable' (early `return` paths and the
nargout==2/4 branches) for a path where varargout is assigned a non-cell or
where the case falls through without assigning varargout while nargout>0.
NOTE: sdpvarCore was merged INTO @sdpvar/sdpvar.m (keyword branch) because
@sdpvar-folder functions cannot be called with a non-sdpvar first argument,
and class(struct,'sdpvar') is illegal outside the @folder.

The tree is MID-CUTOVER: all conversions are in place (0 global, 0 persistent,
0 yalmip(' calls outside dev, dispatcher deleted, tests migrated) but the
session-creation path has ONE known unresolved link and the full pipeline has
not yet been smoke-tested end-to-end.

### Immediate next steps (in order)
1. **sdpvarCore visibility**: `+yalmip/Session.m` sdpvar() method routes via
   `sdpvar(varargin{:},'session',{obj})` -> `@sdpvar/sdpvar.m` keyword branch ->
   `sdpvarCore(S,args)` — but sdpvarCore lives in `@sdpvar/` and is not callable
   with a Session first argument. It was MOVED to `extras/sdpvarCore.m` already
   (git mv), but external `class(struct,'sdpvar')` construction needs verification
   (quick probe: build a struct with all sdpvar fields and call class(s,'sdpvar')
   from a plain function; if it errors, keep sdpvarCore in @sdpvar and instead
   pass a dummy sdpvar as first arg, or perform construction inside sdpvar.m).
2. Then run `dev/baseline/smoke3.m` (covers creation, optimize, value/dual,
   operators, session isolation, old-API errors, sdisplay, optimizer, version).
3. Fix forward through smoke failures; then run the per-suite gate
   (`dev/baseline/run_stage.m`) and compare with
   `python3 dev/baseline/compare_stage.py` (0 NEW failures = pass).
4. Commit "Stage 3" once green; then Stages 4-6 per the plan.

### Key invariants for any fix
- The ONE allowed dispatch pattern: Session methods one-liner ->
  `yalmip.dispatch(obj,'cmd',args)` (+yalmip/dispatch.m holds the former
  switch over session state; original dispatcher indexing preserved:
  varargin{1} = command string).
- Creation route: S.sdpvar(...) -> sdpvar(...,'session',{S}) keyword ->
  sdpvarCore(S,...) -> appendYALMIPvariables(S,...). Fast paths in sdpvar.m
  take an optional TRAILING session argument.
- Evaluation: optimize returns diagnostic with `.eval` (S.evalSnapshot());
  value(x,sol)/dual(F,sol)/assign(x,v,sol) read sol.eval.

## HANDOFF 2 (session boundary) — after creation-chain green

smoke3 all green (commit f74cc45). Suite state (stage3d): core 29/42,
operators 37/53, misc 3/8 — remaining errors cluster in the OPERATOR
EXPANSION path. Next session, attack in this order:
1. operators/model.m line 73: the catch swallows the real error — run
   e.g. `S.sdpvar(2);F=[norm(x)<=1];optimize(F)` without catch to see the
   underlying failure (suspect: max_internal/norm operators calling
   S.define with wrong arg convention, or sessCheck line 10 rejecting
   operands that are struct-payload sdpvars).
2. sessCheck.m line 10: dumps when operand is a converted struct? Verify
   sess1's try/catch works for all operand shapes.
3. compileinterfacedata.m:766, sdpsettings.m:341, linearize (value
   single-arg inside library code), test HigherOrder/'x' typos in tests.
Known-OK: creation chain, constraints, MILP/NLP solve, value/dual/assign
with explicit sol, session isolation, sdisplay names, optimizer, version.

## HANDOFF 3 — Stage 3 convergence state (core 34/42, operators 40/53)

Next attack list (highest value first):
1. sessCheck:10 cluster (sort/max/nchoosek/rcone models): operator model
   bodies call S.sdpvar/sessCheck on operands WITHOUT sess — find where
   those operands are built (suspect: dispatch.m 'define' branches and
   @sdpvar/{sort,max,...}.m char paths calling sdpvarFast WITHOUT session
   or recover(ids) without S). grep for sdpvarFast( calls lacking S and
   recover( calls without ,S in dispatch.m + @sdpvar + operators.
2. value line 13 x3 (linearize): @sdpvar/linearize internally calls
   value(x) single-arg — thread the solution payload or make linearize
   accept sol.
3. model:73 passthrough reveals per-operator causes one by one (geomean
   detset:68 composition, exp/interp1 'Dot indexing').
4. misc 3/8: blackbox value single-arg; implies sdpsettings:341.

## HANDOFF 4 — core 38/42, operators 46/53, misc 6/8 (all zero hard-fails)

Remaining (11 errors total):
- operators: interp1_internal (S=sessOf(x) empty at :56 — verify x carries
  sess when model() dispatches), nchoosek (index not integer — arg
  convention off-by-one after S strip), exp test3, blackbox test_base
  (value single-arg in library), implies test12 (sdpsettings:341), test_operator_int
  ('x' undefined — TEST bug: S = sdpvarargumentsession(p,x,vin) in
  coefficients.m has no x in scope; check test call pattern).
- core: HigherOrder (test bug — variable never defined), ndsdpvar test1
  (norm on N-D — R2026b pagenorm, pre-existing), diff (pre-existing),
  sdpvar_replace test1/2 (nonlinearreplace recover chain — same
  session-threading pattern as batch 12).
- misc: 2 left (unidentified — re-aggregate).
Pattern proven: session threading via scoped S (NOT sdpsession — it
returns empty in some graph contexts, root cause not fully diagnosed).
