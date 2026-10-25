# YALMIP Stateless Refactoring — Stage 0 Baseline

Recorded: 2026-10-25, branch `refactor/stateless`, base commit `52666d2` (develop).

## Environment

- MATLAB R2026b (26.2.0), Linux x64
- Solvers available: **MOSEK 11.2** (`/opt/mosek/11.2/toolbox/r2019b`), Optimization Toolbox
  (linprog/quadprog/fmincon), no SeDuMi/SDPT3/other external solvers.
- Runner: `runxunittests('dev/tests/<suite>')`, per-suite JUnit XML in `dev/baseline/`.

## Per-suite baseline (361 tests total)

| Suite      | Tests | Failures | Errors | Notes |
|------------|------:|---------:|-------:|-------|
| bilevel    |   9   | 0 | 2 | solver-availability related |
| bmibnb     |  71   | 1 | 2 | |
| bnb        |  19   | 1 | 8 | most errors: missing non-MOSEK LP/QP paths |
| chance     |   1   | 0 | 0 | |
| core       |  42   | 0 | 2 | test_ndsdpvar (N-D `norm` removed in R2026b), test_sdpvar_diff (size mismatch) |
| cutsdp     |   4   | 0 | 4 | `getdimarg` R2026b incompatibility |
| dualize    |  21   | 0 | 0 | |
| geometric  |  13   | 0 | 0 | |
| globlib    |   0   | 0 | 0 | tests in subfolders, not collected by `testsuite(folder)` |
| logic      |   7   | 0 | 0 | |
| misc       |   8   | 0 | 0 | |
| moment     |   1   | 0 | 0 | |
| mpt        |  11   | 5 | 6 | MPT toolbox not installed |
| operators  |  53   | 1 | 1 | |
| optimizer  |  40   | 0 | 0 | |
| robust     |  33   | 0 | 1 | |
| slayer     |   2   | 0 | 0 | |
| sos        |  26   | 0 | 0 | |
| **Total**  | **361** | **8** | **26** | 327 passing |

## Gate for all refactoring stages

A stage is accepted when a re-run produces **no new failures/errors** relative to this
table (suite-by-suite). Pre-existing failures listed above are expected and not blockers.

Reproduction:

```bash
export MOSEKLM_LICENSE_FILE=/home/connor/mosek/mosek.lic
/opt/MATLAB/R2026b/bin/matlab -batch "addpath('dev/baseline'); run_one('core')"
# (run_one(suite) loops over a suite; XML written to dev/baseline/<suite>.xml)
```
