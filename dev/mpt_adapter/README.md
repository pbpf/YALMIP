# MPT3 session adapter

YALMIP's stateless refactor removed all ambient state: bare `sdpvar(...)`
errors with `YALMIP:sessionRequired`. MPT3's UI classes predate that API and
create their variables with bare calls, so five `mpt` suite tests die before
they can run (`SystemSignal/instantiate` <- `AbstractSystem/instantiate` <-
`AbstractController/toYALMIP`).

This adapter is MPT-side, as called for in `dev/REFACTORING_STATE.md`:
nothing in YALMIP changes, and YALMIP itself never consults the adapter's
session.

## What it does

- `mpt_yalmip_sdpvar.m` is installed into the MPT3 root. With the stateless
  YALMIP on the path it creates variables through a single process-wide
  `yalmip.Session` shared by all MPT3 internals; with the pre-refactor
  (global-state) YALMIP it falls back to the bare constructor, so one patched
  MPT3 tree works with both.
- `apply_mpt_adapter.sh <MPT_ROOT>` (default `/opt/mpt3`) copies the helper
  and rewrites the 22 live bare `sdpvar(` call sites under
  `modules/ui/@SystemSignal`, `modules/ui/@PWASystem`,
  `modules/ui/@ULTISystem` and `modules/solvers`. The script is idempotent,
  skips comments, and prints a per-file count (`mpt_enum_plcp.m` has three
  commented-out sites and ends at 0). The only untouched live matches are
  documentation examples inside `@Opt/Opt.xml`.

To revert, `git -C <mpt3-source> checkout` the tree or re-extract it; the
wrapper file is `rm <MPT_ROOT>/mpt_yalmip_sdpvar.m`.

## Evidence (2026-10-29, R2026b, MOSEK 11.2, MPT3 at /opt/mpt3)

Running the upstream (develop, `52666d2`) versions of the `mpt` tests on the
pre-refactor code in this environment shows they fail there too — the
expectations come from a different solver era:

| test (mpt suite) | develop + this env | stateless + adapter |
|---|---|---|
| dpmpqp, lti_3 | pass | pass |
| lti_1, lti_2, pwa_1, pwa_2 | `PolyUnion/compare: The functions must be defined over the same domain` | same |
| norm_repeated, oneshotmpqp, paramcost_1, pwa_sincos_dp | assertion failure (wrong region counts / values) | same |
| pwa_3d_dp | `pwa3d` ships only in the MPT release bundle | same |

After the adapter the stateless branch reproduces the develop behaviour
exactly: no `sessionRequired` remains, and every failure mode matches the
pre-refactor run one for one. The remaining failures are MPT3-internal
(most plausibly the MPQP enumeration behaving differently against
MOSEK 11 / R2026b than against the solver stack the expectations were
recorded with) and need upstream MPT3 work, not YALMIP changes.

Measured on develop, for the record: `oneshotmpqp` yields 1 region and
`u = NaN` at the second test point (expectation: 4 regions, 6.193);
`paramcost_1` yields cost 40.304 vs 43.8 with 1 region;
`norm_repeated` yields 4/9/10 regions vs 4/6/6.
