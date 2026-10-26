function cm = codermodel(model)
%CODERMODEL Dense, Coder-compatible variant of a compiled YALMIP model.
%
%   cm = codermodel(model) takes the model struct that export/compileinterfacedata
%   hands to the solver wrappers and rewrites the parts the evaluation core
%   touches into shapes MATLAB Coder accepts:
%
%     * every sparse matrix turned dense (full)
%     * the cell-array evaluation scheme flattened to index arrays
%     * one dense exponent row per nonlinear (scheme) variable
%     * a dense Jacobian layout, so no array growth happens in the loops
%
%   Supported scope: polynomial objectives and polynomial inequality/equality
%   rows (the Anonlinineq/Anonlineq representation), i.e. problems whose
%   evaluation scheme contains only 'monom' groups. User callbacks and
%   transcendental operator groups ('eval') stay on the interpreted evaluator
%   and raise YALMIP:coderUnsupported, as does anything involving cones.
%
%   See also CODEREVAL, CODEGEN_CONFORMANCE

if ~isfield(model,'evaluation_scheme')
    error('YALMIP:coderUnsupported','codermodel: model has no evaluation_scheme; use the interpreted path.');
end

scheme = model.evaluation_scheme;
for i = 1:numel(scheme)
    entry = scheme{i};
    if ~strcmp(entry.group,'monom')
        error('YALMIP:coderUnsupported', ...
            ['codermodel: operator "' entry.group '" in the evaluation scheme needs a ' ...
             'runtime callback. This model stays on the interpreted evaluator.']);
    end
end

if isfield(model,'K') && (any(model.K.q(:) > 0) || any(model.K.e(:) > 0) || any(model.K.s(:) > 0) || any(model.K.r(:) > 0))
    error('YALMIP:coderUnsupported', ...
        'codermodel: cone/SDP rows are not part of the codegen subset; use the interpreted evaluator.');
end

nFull = length(model.c);

% Flatten the scheme: variables are listed in evaluation order, which is
% topologically valid (a monomial only depends on earlier entries).
vars = zeros(0,1);
for i = 1:numel(scheme)
    % The scheme lists positions into model.monomials, not expanded ids
    v = scheme{i}.variables(:);
    if isfield(model,'monomials') && ~isempty(model.monomials)
        v = double(model.monomials(v(:))');
    end
    vars = [vars; v]; %#ok<AGROW>
end
vars = unique(vars,'stable');
nScheme = numel(vars);

mt = full(model.monomtable);
cm.nFull      = nFull;
cm.nScheme    = nScheme;
cm.schemeVars = double(vars(:));
cm.powers     = double(mt(vars,:));          % one dense exponent row each

% Decision variables and their positions inside the expanded vector
cm.linearindicies = double(model.linearindicies(:));
cm.nDec = numel(cm.linearindicies);

% Objective:  f = f0 + c'*x + x'*Q*x   (dense)
cm.f0 = double(model.f);
cm.c  = double(full(model.c(:)));
cm.Q  = double(full(model.Q));

% Polynomial constraint rows:  a'*x - b
if isfield(model,'Anonlinineq') && ~isempty(model.Anonlinineq)
    cm.Aineq = double(full(model.Anonlinineq));
    cm.bineq = double(full(model.bnonlinineq(:)));
else
    cm.Aineq = zeros(0,nFull);
    cm.bineq = zeros(0,1);
end
if isfield(model,'Anonlineq') && ~isempty(model.Anonlineq)
    cm.Aeq = double(full(model.Anonlineq));
    cm.beq = double(full(model.bnonlineq(:)));
else
    cm.Aeq = zeros(0,nFull);
    cm.beq = zeros(0,1);
end
% Linear rows are constant maps and handled by the solver directly
cm.isCoderModel = 1;
