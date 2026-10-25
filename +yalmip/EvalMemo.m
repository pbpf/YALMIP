classdef EvalMemo < handle
%EVALMEMO Per-solve memoization state for nonlinear solver callbacks.
%
%   External nonlinear solvers (fmincon, IPOPT, KNITRO, PENLAB, ...) invoke
%   separate callback functions for the objective, gradient, constraints and
%   Jacobian at the same iterate. An EvalMemo instance attached to the
%   compiled model (model.memo) lets the callbacks cache the most recently
%   evaluated point and the quantities computed there, so repeated work is
%   avoided without any global or persistent variables.
%
%   The instance is created by the solver wrapper (solvers/call*.m) before
%   the callback closures are defined, and is captured by the closures
%   together with the model. Since EvalMemo is a handle class, property
%   assignments made inside a callback are visible to all other callbacks
%   of the same solve.
%
%   See also solvers/callfmincon.m, extras/fmincon_fun.m, extras/fmincon_con.m

    properties
        xevaled = []      % last evaluated (recovered) x, fmincon_fun/fmincon_con
        xXevaled = []     % raw x matching XEVALED
        xF = []           % x at last objective callback
        f = []            % last objective value
        df = []           % last objective gradient
        xG = []           % x at last constraint callback
        g = []            % last constraint values
        G = []            % last constraint Jacobian
        dg = []           % last inequality gradient (KNITRO)
        geq = []          % last equality values (KNITRO)
        dgeq = []         % last equality gradient (KNITRO)
        x = []            % x at last multivariate objective callback (PENNON)
        sdpLayer = []     % LMI layer state (eigenvalue reordering, null vectors)
        model = []        % compiled model handed to named-callback interfaces
        diffCache = []    % chain-rule precomputation cache for apply_recursive_differentiation
    end
end
