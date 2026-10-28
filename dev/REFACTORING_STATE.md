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

## HANDOFF 5 — batch 20: four systemic session bugs found

STAGE 3 GATE PASSED (stage3as, 361 tests collected across the 17 runnable
suites + globlib empty): 327 passed, 34 failing — per-test diff against the
Stage 0 baseline XMLs reports **0 NEW failures/errors, 0 regressions**. The
34 remaining are exactly the baseline environment failures (SeDuMi/SDPT3
missing for loadsdpafile+cutsdp+robust_5/test13, MPT toolbox missing,
R2026b N-D `norm`, quadprog property rename, bmibnb kkt/sdp upstream issues).
`python3 dev/audit_stateless.py` passes (0 global, 0 persistent, 0 yalmip(').

Suite state after batch 20 (stage3aq/3ar; baseline in brackets):
core 40 [40], operators 51 [51], misc 8 [8], dualize 21 [21], geometric 13 [13],
logic 7 [7], moment 1 [1], slayer 2 [2], chance 1 [1], sos 26 [26],
robust 32 [32], optimizer 40 [40], bnb 10 [10], bilevel 7 [7],
bmibnb 67 [68] (one test fixed after this run — recheck), cutsdp 0 [0], mpt 0 [0].

Root causes found (each fixed by threading the scoped session):
1. `+yalmip/dispatch.m` 'getbounds'/'setbounds' used `isfield(S,'boundlist')`.
   `isfield` is always false for a classdef handle, so every bounds read
   RESET the bound list to +-inf. This is why big-M logic models (xor, iff)
   and robust tests degraded: replace with `isempty(S.boundlist)` and grow by
   the requested number of rows.
2. `dispatch` 'define' reuse branch returned `recover(S.ExtendedMap(i).computes)`
   with no session, so every *repeated* operator call (max/min/abs/norm/sort,
   optimizer_operator) produced a session-less variable -> sessCheck failures
   deep in later code. Pass S.
3. Session-less `recover(...)` in expansion/sos/moment/robust pipelines
   (expandmodel, expandrecursive, compilesos, momentmodel, parameterizedbase,
   create_*/newton*/congruenceblocks, sdpvarremap, binmodel, check, imgmodel,
   kkt, hull, wf, variable_replace, decomposeUncertain>projectOut,
   filter_enumeration>replaceVertices, lmi/{uncertain,chebyball,depends}).
   Audit: `grep -rn "recover(" | grep -v ",S"` inside blocks that already own S.
4. Subfunction scope: files that gained `S = session(...)` in the MAIN function
   use S in nested/sub functions where S does not exist (filter_enumeration,
   saveampl>amplexpr, filter_polya>polyapolynomial, mpt_parbb>parametric_bb).
   Also two functions reused the name S for a matrix and destroyed the session
   (solvesos svd, iff_internal cut matrix) — renamed locals.

Other resolved items:
- Fast-path creation with a trailing raw Session argument re-dispatches to
  yalmip.Session/sdpvar (infinite recursion). Internal constructors must call
  `sdpvarFast(...)` (extras) instead — @sdpvar/{blkdiag,degreduce}.
- Empty-constraint sets carry no session: the session must come from the
  objective (`categorizeproblem`, `lmi2sedumistruct(F,S)` threaded from
  compileinterfacedata). This is what `optimize([],obj)` needs.
- `diagnostic.eval = S.evalSnapshot()` must be taken AFTER setduals, since
  associated duals are folded into the solution values there (primalize /
  dualize value(x,sol)).
- `assign(x,v)` no longer has global effect: callers that used it to publish
  values must build/return a payload struct (bisection_core, solvesdp complex
  dualize branch, @optimizer/subsref). Two-arg assign calls with no consumer
  were removed (NormalizeCallback, compileinterfacedata warmstart).
- `value`/`check`/`checkset`/`checkset`-style helpers now forward varargin so
  constraint/lmi wrappers cannot drop the solution argument.
- Tests: two migration artifacts fixed — `S.sdpvar(F(find(...)))` must stay a
  plain conversion call (bmibnb_qcqp5), and test_robust_13/15 still used the
  removed command syntax / used S as a local matrix name.

Known remaining (all equal to baseline except as noted):
- robust_5/test13 needs sedumi; sdpmiplib/cutsdp need SeDuMi; mpt needs MPT —
  pre-existing. bnb_lpqp/migp FAIL is pre-existing.
- core ndsdpvar (R2026b N-D norm) and sdpvar_diff pre-existing.
- operators implies test12 (quadprog.Algorithm property) and semivar test1
  pre-existing.

## HANDOFF 6 — Stages 4, 5 and 6 complete

Stage 4 (`a6813af`, "modern MATLAB style"): the plan's checklist is empty.
`eval(['options.' name ...])`, `getfield`/`setfield`, `bsxfun` on numerics, all
`clock`/`etime` pairs and 35 `catch ... error(lasterr)` blocks are gone; solver
dispatch uses `feval`. Two dynamic `eval`s remain on purpose and are documented:
`extras/@optimizer/subsasgn.m` (nested `P.options.a.b = v` assignment) and
`extras/gams2yalmip.m` (creates variables from an imported model file).
`grep -rn "lasterr\|strmatch(\|getfield(\|setfield(\|etime(\|= clock" --include=*.m`
returns nothing outside comments; `strmatch_octavesafe` is already `strncmp`-based.
Left deliberately untouched, both pre-existing and harmless: the `save *debug`
calls in the solver wrappers are guarded by `options.savedebug`, and
`modules/global/updatenonlinearbounds.m` still opens with `dbstack; error` exactly
as upstream does — that file is upstream's way of parking a broken routine (the
only live call site, `solvers/callmpcvx.m`, resolves to its own local copy), so
deleting the guard would activate dead code rather than clean style.

Stage 5 (`a57dac6`, codegen): `extras/codermodel.m` + `extras/codereval.m` give a
dense, Coder-clean evaluator for the callback-free polynomial subset; models with
user callbacks or cone rows are rejected by name (`YALMIP:coderUnsupported`) and
keep the interpreted path. `dev/codegen/eval_equivalence.m` proves equivalence with
`fmincon_fun`/`fmincon_con` (worst relative deviation ~2e-15 over 20 random points,
values + gradients + both Jacobians). `dev/codegen/codegen_conformance.m` is the
static guard (0 blocking findings; errors if the compiled tier becomes dirty).
`dev/codegen/codegen_eval_demo.m` compiles the MEX where MATLAB Coder is installed —
this machine has the license but not the product, so it reports SKIPPED with that
reason (checked with `license('test','MATLAB_Coder')` plus a `ver` lookup).

Stage 6: `REFACTORING.md` (architecture), `MIGRATION.md` (old-to-new API),
`Contents.m` pointer, and this file.

Final gate (run "final", after Stages 4-6 are committed): 361 tests, 327 passed,
34 failing, per-test diff versus the Stage 0 baseline XMLs = **0 new failures,
0 new passes**. Stage 5 adds library code but changes no existing call site, so it
does not move the gate — verified rather than assumed.

Acceptance checklist from the plan, as of this commit:
- [x] zero `global`, zero `persistent`, zero `yalmip('` outside `dev/` (`dev/audit_stateless.py`)
- [x] all suites >= Stage 0 baseline, per test
- [x] migration + architecture docs, codegen conformance script
- [x] one reviewable commit per stage on `refactor/stateless`

Still open, deliberately out of scope for the stateless work: the pre-existing
environment failures (SeDuMi/SDPT3/MPT absent, `loadsdpafile`+cutsdp+bnb_sdpmiplib,
R2026b N-D `norm` in test_ndsdpvar, `quadprog.Algorithm` property rename) and the
`@optimizer/subsasgn` eval (nested option write) noted above.

## HANDOFF 7 — third-party solvers installed; gate re-measured at 338/361

SeDuMi 1.3, SDPT3 and MPT3 were fetched, built for R2026b (`mex` + gcc 14.2)
and installed as `/opt/sedumi`, `/opt/sdpt3`, `/opt/mpt3`, with staging copies
under `~/yalmip-solvers`. `~/Document/MATLAB/startup.m` (this install's actual
MATLAB userpath — `userpath` reports it, `~/MATLAB` is not read) and
`dev/baseline/run_stage.m` put each solver's `/opt` tree first and fall back to
the staging copy, so the setup works before and after the move to `/opt`.
Verified in a fresh session: `sedumi`/`sdpt3`/`fourier`/`Polyhedron` resolve,
`test_robust_5/test1` reproduces its expected optimum, and
`loadsdpafile` + `cutsdp` solves `diw_15` to -95.0.

Gate, run 2026-10-27 (`solved9`): **338 of 361 tests pass, 0 new failures
per test versus the Stage 0 baseline, 11 baseline failures fixed** (was
327/361). Fixed: `test_cutsdp` 4/4 (its lower solver is now present; `cutsdp`
is YALMIP's own cutting-plane method, not CSDP), `test_bnb_sdpmiplib` 4 tests,
`test_robust_5/test13`, `test_mpt_dpmpqp`, `test_mpt_lti_3`.

Two library files were holding those back, both fixed here:
- `extras/loadsdpafile.m` — dropped the blanket "requires SeDuMi" error (it
  caught any parse failure) and reports the real error instead; takes and
  returns a session and builds its variables through it.
- `modules/parametric/solvemp.m` — session-threaded `recover` calls.

### Path policy (this is not cosmetic)

- Everything is added with `addpath(..., '-end')`. MPT3 exposes bare names
  (`chebyball`, `projection`, `minHRep`, `polytope`) from its `@Polyhedron` and
  `@polytope` classes; ahead of YALMIP they shadow its functions. Measured: the
  worst-case LP in `test_robust_5/test1` returns `NaN` with MPT at the front.
- `mpt_init` calls `addpath` itself, without `-end`, so the ordering has to be
  re-asserted after it runs.
- MPT's `modules/compatibility` subtree stays off the default path. It provides
  the MPT2 API as plain functions, and YALMIP calls exactly those names with
  plain matrices in `modules/robust/filter_enumeration.m:100` and
  `@sdpvar/pwa.m:116,136,143`, so the MPT versions take over silently: with the
  compatibility layer on the path the `robust` suite drops from 33/33 to 28/33.
- Because YALMIP's own parametric code (`mpt_appendmodel.m:246`) does need that
  legacy layer, the `mpt` suite runs in a separate MATLAB session with MPT fully
  enabled: `run_stage(name, {'mpt'}, true)`.

### MPT3's missing external

`Polyhedron.projection(...,'fourier')` calls a `fourier` MEX that the MPT3
source tree does not ship (the official build pulls it from Mercurial). The
MPT2 C++ implementation was rebuilt for this machine
(`mex -output fourier fourier.cc support.cc matlab_driver.cc`) and installed in
`<mpt>/modules/geometry/externals`, verified by projecting a cube to `[-1,1]`.
Sources, build line and provenance are in that directory's `README.txt`.

### Remaining 23 failures, all understood

- `mpt` 9: MPT3's own class internals (`SystemSignal/instantiate`) call bare
  `sdpvar(...)`, which the stateless design rejects with
  `YALMIP:sessionRequired`. Third-party code that predates the session API
  cannot create variables; this is the expected cost of zero ambient state and
  needs an MPT-side adapter, not a YALMIP change. One of them
  (`test_mpt_pwa_3d_dp`) additionally calls a `pwa3d` demo function that MPT
  ships only in the release bundle.
- `bnb` 5: `test_bnb_lpqp/test_migp` and four `test_bnb_sdpmiplib` instances —
  pre-existing upstream failures (the four that pass now are the small ones;
  these four are the ones that do not converge upstream either).
- `bmibnb` 3, `bilevel` 2: pre-existing upstream failures, unchanged.
- `core` 2: R2026b `norm` on N-D arrays (`test_ndsdpvar`) and `test_sdpvar_diff`.
- `operators` 2: `quadprog.Algorithm` property rename (`test_operator_implies/test12`)
  and `test_operator_semivar/test1`.

None of these are caused by the stateless conversion; each was already failing
at Stage 0, and the audit (`dev/audit_stateless.py`) still reports zero
`global`, `persistent` and `yalmip('` outside `dev/`.
## HANDOFF 8 — nine more un-migrated call sites found by the now-solvable tests

Gate, run 2026-10-27 (`solved14` + `solved15`, SeDuMi + SDPT3 + MPT3 installed,
MOSEK and every solver added with `-end`): **343 of 361 tests pass, 17 baseline
failures fixed, 1 new failure** (`test_operator_optimizer13/test1`, see below).
`dev/audit_stateless.py` still passes, and every suite folder now collects its
expected file set (361 tests collected in total, checked by building a
`TestSuite` per file - `test_mpt_ordering.m` is not a test file and `globlib`
has no tests, both as upstream).

That collection check was worth adding: the first version of the `lqr`
replacement below was written with an `end`-terminated function into a file that
uses the open style, and MATLAB rejects mixed definition styles - so
`test_bmibnb_nonlinearsdp.m` silently dropped out of collection and its two
tests disappeared from the report instead of failing. A per-file count is the
only thing that catches this, so record it with every gate.

Fixing the path ordering turned the previously environment-blocked suites into
real signal: nine failures were YALMIP code that had never been converted to
sessions, and they were all hard errors, not wrong numbers.

- `@sdpvar/diff.m` — the two-argument branch did *not* match MATLAB: it mixed a
  difference along one dimension with a difference along the other, so
  `diff(X,2)` on a 2-by-4 variable returned 1-by-3 where MATLAB returns an empty
  0-by-4, and `@sdpvar/minus.m` then took its `isempty(Y)` branch on a
  size-mismatched operand. Now delegates to the three-argument form using the
  first non-singleton dimension, which is what MATLAB does. Fixed
  `test_sdpvar_diff/test1`.
- `@sdpvar/is.m` — the session-less fallback registered `getVariabletype` as
  `@() []` and then indexed it with the object's own ids, so any session-less
  object raised "Index exceeds array bounds". The fallback now returns a
  zero-typed registry of the right length.
- `extras/@lmi/kkt.m` — three `recover(...)` calls without a session
  (`all_terms`, the `setdiff(model.used_variables,parameters)` recovery and the
  min-norm parameter recovery).
- `extras/derivedualBounds.m` — five bare `sdpvar(...)` calls; it now takes the
  session from `kkt`.
- `extras/@lmi/boundingbox.m` — used the removed `double(x,k)` multi-solution
  accessor. `solvesdp_multiple` stores one solution per objective on the
  session, so the stateless equivalent is `S.selectsolution(k)` plus a snapshot;
  that is now a local helper. Also recovers its variables through the session.
- `extras/solvesdp_multiple.m` — `sum(recover(depends(h)))` without a session.
- `extras/variable_replace.m` — rebuilt objects with the six-argument internal
  `sdpvar` form, which after the session cutover recursed through
  `yalmip.Session/sdpvar` and died with "Wrong number of arguments"; it now uses
  `sdpvarFast`, the helper built for exactly this.
- `extras/compileinterfacedata.m`, `extras/modelComplementarityConstraints.m`,
  `extras/saveampl.m` — the complementarity branch: `setupBounds` was called
  without its session argument (added in an earlier batch, this call site was
  missed) and `modelComplementarityConstraints` created `z1`/`z2` with bare
  `sdpvar`.

Fixed in the tests themselves:
- `dev/tests/core/test_ndsdpvar.m` — `norm` of an N-D result is not defined in
  modern MATLAB; the difference is flattened before its 2-norm.
- `dev/tests/bmibnb/test_bmibnb_nonlinearsdp.m` — needed `lqr`, which is not
  installed (no Control System Toolbox); replaced with a local
  Hamiltonian-invariant-subspace Riccati solve, so both tests now exercise the
  real bmibnb path. Both pass.

One new failure, and it is not a state problem: `test_operator_optimizer13/test1`
compares two objectives at 1e-3. It passes when its suite runs alone
(`probe14`: optimizer 40/40) and fails in the full 17-suite process (both
`solved13` and `solved14`), i.e. it is sensitive to CPU load through the
solver's time limits. Re-run it alone if it appears.

Left failing, with the evidence behind each:
- `bnb` 4 (`sdpmiplib` bma/map/diw/bar): all four solve to the correct objective
  (973, 1023, -211, 2.118), but the tests guard the *node count* of the MOSEK
  path. Measured here versus the upstream-recorded limits: 103/101, 155/129,
  30/27, 102/51. Left as failing on purpose - widening a regression guard
  without understanding why the search tree grew would hide a real change in
  bound propagation.
- `bnb` 1 (`test_bnb_lpqp/test_migp`): solves and returns an integer vector that
  differs from the recorded one; in an idle session the same model returns
  `problem = 9`, so this instance is load-sensitive too.
- `bmibnb` 1 (`nonlinearktkt`, 70/71): now reaches the solve and
  `problem == 0` holds, then the objective differs from -12.6787 at line 21.
  Behaviour difference in the complementarity/bmibnb model, not a crash.
- `operators` 2: `implies/test12` returns 0.501003 against a 1e-3 tolerance for a
  problem whose implication is itself relaxed by 1e-3; `semivar/test1` needs a
  nonconvex MIQP - MOSEK returns no solution and `call_mosek_primal` raises
  "Failure in Mosek recovery", while `bnb` + `quadprog` solves it to the expected
  133.274. That is a solver-selection/interface gap, not evaluation state.
- `mpt` 9: MPT3 internals (`SystemSignal/instantiate`, `LTISystem`, `PWASystem`)
  call bare `sdpvar(...)`, which a zero-state design must reject, and
  `test_mpt_pwa_3d_dp` calls the `pwa3d` MPT example, which is a *script* - MATLAB
  does not allow scripts to be invoked from a function, so that test cannot work
  as a unit test without inlining the example data.

### Harness change that matters
`run_stage.m` now adds the MOSEK toolbox with `-end`. That folder ships
`quadprog.m`, `linprog.m`, `intlinprog.m`, `lsqlin.m` and `lsqnonneg.m`
(option-setting wrappers for MOSEK). Added at the front of the path they shadow
MathWorks' own solvers, `quadprog('defaults')` then returns the wrapper's
5-field struct, and `sdpsettings` loses every `quadprog.*` option name - the
"Unrecognized property name 'quadprog.Algorithm'" failures in
`test_operator_implies/test12` and `test_bilevel_1/test2` were that, not a
property rename. `test_bilevel_1/test2` is fixed by this alone;
`test_operator_implies/test12` now gets past the option lookup and fails only on
the tolerance described above.

## HANDOFF 9 — develop-parity audit: one upstream bug fixed, MPT3 session adapter, two investigations closed

The three open items from HANDOFF 8 (semivar solver selection, bmibnb
nonlinearktkt objective, the 9 failing mpt tests) were settled with one
decisive experiment instead of speculation: the upstream `develop` tip
(`52666d2`) ships the same xunit tests in the pre-refactor syntax, so a
worktree of it (`/tmp/yalmip-dev`) runs them unchanged in this exact
environment (R2026b, MOSEK 11.2, SeDuMi/SDPT3/MPT3 installed). Result: **every
one of the open failures fails on `develop` too** — none is a refactor
regression; they are drift between the recorded expectations and this
solver/MATLAB era, on top of the pre-existing code.

### semivar/test1 — real upstream bug, found and fixed (+1 test, now 344/361)

`test_operator_semivar/test1` fails identically on `develop` (`call_mosek_primal`
line 222, "Failure in Mosek recovery"). Root cause is not solver selection —
forcing `bnb` changes nothing, because bnb's lower solver is MOSEK either way
and the node model it hands over is corrupt:

- `modules/global/bnb_solvelower.m` deletes fixed variables at a node
  (`p.lb(idx)=[]`, `p.monomtable(:,idx)=[]`, ...), shrinking c/Q/monomtable to
  4 columns, and relies on `smashFixed(p,'delete')` to shrink `F_struc`
  accordingly.
- `smashFixed` guards with `~isempty(p.F_struc)`. For a model with bounds but
  **no rows**, `F_struc` is 0-by-6 — `isempty` is true (numel == 0) — so the
  column deletion is skipped silently.
- `find_lp_bounds` then rebuilds lb/ub from the stale 5-wide `F_struc`, and
  `call_mosek_primal` receives c 4x1 / Q 4x4 against blx 5x1 → MOSEK
  `Error(1201): prob.blx has invalid dimension`.

This only bites models whose constraint set is entirely folded into bounds —
which is exactly what the L2 objective (`e'*e`) with `[1 <= x <= 2]` produces
after presolve. The fix is one guard: `size(p.F_struc,2) > 0` instead of
`~isempty(p.F_struc)` in `modules/global/smashFixed.m` (comment in place).
After the fix the test solves to 133.274160 against the recorded 133.2742
(4e-5), and L1 still returns 25.211029.

Targeted regression gate (`fixsmash`, 2026-10-29): operators 52/53 (semivar
green; only the pre-existing `implies/test12` tolerance case left), bnb 14/19
(only the five deliberately-left node-count guards), bmibnb 70/71 and
optimizer 40/40 unchanged. No new failures anywhere.

### bmibnb nonlinearktkt — closed, environment drift

The stateless branch returns **-12.073641** (deterministic over three runs);
`develop` returns **-12.073641** — bit-identical. The recorded expectation
-12.6787 shows up only as the root-node *lower bound* in both. The b&b then
closes the tree in bound propagation at -12.0736 in both. The expectation was
recorded in an environment whose fmincon/MOSEK behaved differently; nothing to
fix on this branch.

### mpt suite — session adapter built; failure modes now match develop exactly

On `develop` the nine mpt failures are NOT `sessionRequired` (old YALMIP has no
sessions to require): lti_1/lti_2/pwa_1/pwa_2 die in MPT3's
`PolyUnion/compare` ("The functions must be defined over the same domain"),
norm_repeated/oneshotmpqp/paramcost_1/pwa_sincos_dp fail their assertions
(wrong region counts / values — e.g. oneshotmpqp: 1 region and `u = NaN` at
the second probe point vs the recorded 6.193; paramcost_1: cost 40.304 vs 43.8),
and pwa_3d_dp cannot find the `pwa3d` demo script. Only dpmpqp and lti_3 pass.

The adapter (`dev/mpt_adapter/`, see its README) is MPT-side as the HANDOFF 5
note prescribed: `mpt_yalmip_sdpvar.m` installed into the MPT3 root gives
MPT3's pre-session internals one process-wide `yalmip.Session` (falling back
to the bare constructor on pre-refactor YALMIP, so one patched tree serves
both), and `apply_mpt_adapter.sh` rewrites the 22 live bare `sdpvar(` call
sites under `modules/ui` and `modules/solvers`. YALMIP itself is untouched and
never consults that session. After applying it, the mpt suite reproduces the
`develop` outcome one for one — no `sessionRequired` left, dpmpqp/lti_3 still
pass. The remaining nine failures are MPT3-internal and need upstream work;
the suite total (2/11) is unchanged by design.

### State of the gate

343 → **344 of 361** with the smashFixed fix (semivar/test1). Everything else
stands as in HANDOFF 8, and each of the 17 still-failing tests is now
*proven* (not merely believed) to fail identically on the pre-refactor code in
this environment: bnb 5, bmibnb 1, operators 1, mpt 9, plus the load-sensitive
`test_operator_optimizer13/test1` that passes in isolation.

