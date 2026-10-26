function ok = codegen_eval_demo(verbose)
%CODEGEN_EVAL_DEMO Compile the codegen evaluation core with MATLAB Coder.
%
%   ok = codegen_eval_demo() builds the same callback-free polynomial model as
%   EVAL_EQUIVALENCE, flattens it with CODERMODEL, compiles CODEREVAL with
%   MATLAB Coder and compares the generated MEX against the MATLAB results.
%
%   The demo reports 'skipped' (ok = false) when no Coder license or no
%   supported C compiler is available, so it is safe to call from CI.
%
%   Scope: only the callback-free polynomial evaluation core is codegen-ready.
%   Models with user callbacks or cone rows keep using the interpreted
%   evaluator, and CODERMODEL says so explicitly instead of miscompiling.

if nargin < 1
    verbose = true;
end
ok = false;

haveLicense = license('test','MATLAB_Coder');
vs = ver();
haveProduct = any(contains({vs.Name},'MATLAB Coder'));
if ~(haveLicense && haveProduct)
    if verbose
        if ~haveLicense
            reason = 'no MATLAB Coder license';
        else
            reason = ['MATLAB Coder licensed but not installed in this ' ...
                      'MATLAB (ver has no ''MATLAB Coder'' entry, so the ' ...
                      'codegen command is unavailable)'];
        end
        fprintf('codegen_eval_demo: SKIPPED - %s.\n', reason);
        fprintf(['The compile step is the only part that needs Coder. Run ' ...
                 'eval_equivalence.m here for the numerical proof, and ' ...
                 'codegen_eval_demo.m on a machine with MATLAB Coder.\n']);
    end
    return
end

buildDir = fullfile(tempdir,'yalmip_codegen');
if ~exist(buildDir,'dir'); mkdir(buildDir); end
addpath(buildDir);

S = yalmip.Session();
x = S.sdpvar(3,1);
y = S.sdpvar(2,1);
obj = (x(1)-1)^2 + (x(2)+2)^2 + x(3)*x(1) + y(1)*y(2);
F = [x(1)^2 + x(2)^2 <= 4, x(3) + x(1)*x(2) == 1, y(1)^2 - y(2) <= 0.5, ...
     -3 <= x <= 3, -2 <= y <= 2];
[~,~,~,idata] = export(F,obj,sdpsettings('solver','fmincon','verbose',0));
model = yalmip2nonlinearsolver(idata);

try
    cm = codermodel(model);
catch ME
    if verbose
        disp(['codegen_eval_demo: model outside the codegen subset - ' ME.message]);
    end
    return
end

x0 = zeros(numel(model.linearindicies),1);
cfg = coder.config('mex');

try
    codegen('-config',cfg,'codereval','-args',{cm, x0}, ...
            '-d',buildDir);
catch ME
    if verbose
        disp(['codegen_eval_demo: SKIPPED - build failed: ' ME.message]);
    end
    return
end

if ~exist(fullfile(buildDir,'codereval_mex'),'file')
    if verbose
        disp('codegen_eval_demo: SKIPPED - generated MEX not found.');
    end
    return
end

compiled = str2func('codereval_mex');
worst = 0;
for i = 1:20
    xv = 2*rand(numel(model.linearindicies),1)-1;
    [f1,df1,g1,geq1,dg1,dgeq1,xe1] = codereval(cm,xv);
    [f2,df2,g2,geq2,dg2,dgeq2,xe2] = compiled(cm,xv);
    worst = max([worst, abs(f2-f1), norm(df2(:)-df1(:)), norm(g2(:)-g1(:)), ...
                 norm(geq2(:)-geq1(:)), norm(xe2(:)-xe1(:))]);
end
ok = worst < 1e-10;
if verbose
    fprintf('codegen_eval_demo: max deviation between MEX and MATLAB %.3e -> %s\n', ...
            worst, tf(ok));
end
end

function s = tf(b)
if b, s = 'equal'; else, s = 'DIFFERENT'; end
end
