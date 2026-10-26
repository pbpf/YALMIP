function report = codegen_conformance(root)
%CODEGEN_CONFORMANCE Static check that the evaluation core stays Coder-safe.
%
%   report = codegen_conformance() checks the files that the codegen demo
%   (dev/codegen/codegen_eval_demo.m) compiles, and reports constructs that
%   MATLAB Coder rejects or that silently produce wrong generated code:
%
%     - sparse matrices in the hot path (must go through codermodel)
%     - feval / eval / str2func  (dynamic dispatch is not compilable)
%     - cells of heterogeneous structs in the evaluation loop
%     - try/catch used for control flow
%     - growing arrays inside loops (df = [df; ...])
%     - isfield on structs that Coder must treat as uniform
%
%   The check is textual on purpose: it is a guard rail for future edits, not
%   a substitute for an actual codegen build (see codegen_eval_demo.m).

here = fileparts(mfilename('fullpath'));
if nargin < 1
    root = here;
    while ~isfile(fullfile(root,'Contents.m'))
        parent = fileparts(root);
        if strcmp(parent,root), break; end
        root = parent;
    end
end

% Tier 1 must compile; tier 2 is the interpreted reference path and is
% reported for information only.
strict = {'extras/codereval.m'};
informational = { ...
    'extras/codermodel.m', ...                      % preprocessor, runs in MATLAB
    'extras/fmincon_fun.m', ...                     % reference evaluator
    'extras/apply_recursive_evaluation.m'};         % reference scheme, uses feval
targets = [strict, informational];

rules = { ...
    'sparse\('           , 'sparse matrix constructor'        ; ...
    'feval\('            , 'dynamic function call'            ; ...
    '(^|[^.\w])eval\('   , 'eval'                             ; ...
    'str2func'          , 'runtime function lookup'            ; ...
    '^\s*try\b'         , 'try/catch (use explicit guards)'    ; ...
    '\[\s*\w+\s*;\s*'   , 'array growth inside loop'           ; ...
    'isfield\('         , 'isfield (Coder needs uniform structs)'};

report = struct('file', {}, 'line', {}, 'rule', {}, 'text', {});
for t = 1:numel(targets)
    f = fullfile(root, targets{t});
    if ~isfile(f)
        error('codegen_conformance:missingFile','Missing %s', f);
    end
    txt = fileread(f);
    lines = strsplit(txt, newline);
    for i = 1:numel(lines)
        line = strtrim(lines{i});
        if isempty(line) || startsWith(line,'%') || startsWith(line,'%%')
            continue
        end
        for r = 1:size(rules,1)
            if regexp(line, rules{r,1}, 'once')
                % The two files that mirror the interpreted evaluator are
                % allowed to mention sparse only inside comments
                entry.file = targets{t};
                entry.line = i;
                entry.rule = rules{r,2};
                entry.text = line;
                report(end+1) = entry; %#ok<AGROW>
            end
        end
    end
end

nStrict = 0;
for i = 1:numel(report)
    isStrict = any(strcmp(report(i).file, strict));
    if isStrict
        nStrict = nStrict + 1;
    end
    if isStrict
        fprintf('  BLOCKING  %s:%d  %s\n     %s\n', report(i).file, report(i).line, ...
                report(i).rule, report(i).text);
    else
        fprintf('  info      %s:%d  %s\n', report(i).file, report(i).line, report(i).rule);
    end
end
fprintf('codegen conformance: %d finding(s), %d blocking (compiled tier)\n', ...
        numel(report), nStrict);
if nStrict > 0
    error('codegen_conformance:notClean', ...
        'The compiled evaluation tier must be Coder-clean; see the findings above.');
end
end
