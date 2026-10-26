# Migrating to the stateless YALMIP API

Everything in the left column used to work through hidden global state and no
longer does. The right column is the supported form. Error identifier for the
removed forms is `YALMIP:sessionRequired`, and mixing variables from two
sessions raises `YALMIP:sessionMismatch`.

## 1. Variable creation

| Old | New |
|---|---|
| `x = sdpvar(3,1)` | `S = yalmip.Session(); x = S.sdpvar(3,1)` |
| `P = sdpvar(3,3,'symmetric','complex')` | `P = S.sdpvar(3,3,'symmetric','complex')` |
| `x = intvar(2,2)`, `binvar`, `uncvar`, `semivar` | `S.intvar(2,2)`, `S.binvar`, `S.uncvar`, `S.semivar` |
| `sdpvar x y z` (command syntax) | removed — assign explicitly: `x = S.sdpvar(1); y = S.sdpvar(1);` |
| `x = sdpvar(1); y = sdpvar(1);` (implicit shared state) | create both from the **same** session object |

The command syntax disappeared because it wrote variables into the caller's
workspace through `assignin`; there is no registry to attach them to anymore.

Optional display names (used by `sdisplay` instead of workspace sniffing):

```matlab
x = S.sdpvar("x",[3 1]);   % sdisplay prints x(1), x(2), x(3)
```

## 2. Reading solutions

| Old | New |
|---|---|
| `optimize(F,obj)` then `value(x)` | `sol = optimize(F,obj); value(x, sol)` |
| `dual(F)` | `sol = optimize(F,obj); dual(F, sol)` |
| `assign(x,v)` (published into global state) | `sol = assign(x,v,sol)` — it now *returns* the payload |
| `value(x, 2)` (pick the 2nd solution) | `value` no longer takes an index — each `optimize`/`solvemp` call returns its own `sol`; `S.selectsolution(i)` still selects inside the session |
| `relaxvalue(x)`, `relaxdouble(x)` | `relaxvalue(x, sol)`, `relaxdouble(x, sol)` |
| `check(F)`, `checkset(F)`, `isfeasible(F)` | `check(F, sol)`, `checkset(F, sol)`, `isfeasible(F, tol, sol)` |

`sol.eval` is the evaluation snapshot (monomial table, variable types, primal
values, duals); it is attached automatically, and `value`/`dual` read from it.

One consequence worth internalising: expressions built from variables of a
session that never took part in the solve evaluate to `NaN`, exactly as before,
but there is no longer a "most recent solve" that a later `value(x)` call could
accidentally pick up.

## 3. Dispatcher commands

`yalmip('...')` and `extras/yalmip.m` are deleted. The commands that were public
enough to matter:

| Old | New |
|---|---|
| `yalmip('clear')` | `S = yalmip.Session();` for a fresh registry, or `S.clear()` |
| `yalmip('version')` / `yalmip('ver')` | `yalmipversion()` |
| `yalmip('solver','mosek')` | `S.solver('mosek')` (stores `S.preferedSolver`; `sdpsettings('solver',...)` unchanged) |
| `yalmip('getinternalsdpvarstate')` / `setinternalsdpvarstate` | `st = S.snapshotState();` / `S.restoreState(st)` |
| `yalmip('info')` | `S.info()` |
| any other `yalmip('cmd',a,b)` | `S.<cmd>(a,b)` — see `dev/session_method_map.json` for the full list |

## 4. Mixed-session mistakes

```matlab
S1 = yalmip.Session(); x = S1.sdpvar(2,1);
S2 = yalmip.Session(); y = S2.sdpvar(2,1);
x + y            % error: YALMIP:sessionMismatch
```

The variable ids of two sessions index different tables, so combining them would
silently produce a wrong model; the operator now refuses.

## 5. Custom operators and `define`

Registration goes through the session:

```matlab
S.define('define','myop', x, y);       % was yalmip('define','myop',x,y)
```

`evalin('caller', ...)` remains for user-defined operator strings
(`extras/define.m`) and for the Symbolic Toolbox bridge (`@sdpvar/sym.m`).

## 6. Solver callbacks

Solver wrappers no longer use `global latest_*` for memoisation. A wrapper
creates a `yalmip.EvalMemo` handle and closes over it:

```matlab
memo = yalmip.EvalMemo();
fun  = @(x) fmincon_fun(x, model, memo);
```

For interfaces that accept only a function *name*, the memoisation is simply
dropped — results are identical, only repeated callback setup is not cached.

## 7. What did *not* change

`optimize`, `sdpsettings`, `optimizer`, `value`-free model building, all
operators (`>=`, `==`, `norm`, `sos`, `implies`, ...), `export`, `dualize`,
`primalize`, `bmibnb`, `bnb`, `cutsdp`, `sdisplay` call signatures. The only
universal difference is that every symbolic object must come from a session.
