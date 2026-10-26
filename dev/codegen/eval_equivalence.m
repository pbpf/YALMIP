function ok = eval_equivalence(verbose)
%EVAL_EQUIVALENCE Numerical equivalence of the codegen evaluation core.
%
%   ok = eval_equivalence() builds a small polynomial NLP, evaluates it with the
%   interpreted evaluator (fmincon_fun/fmincon_con, sparse, with memoisation)
%   and with the Coder-ready core (codermodel + codereval, dense), and compares
%   objective, gradient, constraint rows and Jacobians.
%
%   This runs without a MATLAB Coder license; it is the correctness half of the
%   Stage 5 deliverable (the compilation half is codegen_eval_demo.m).

if nargin < 1
    verbose = true;
end

S = yalmip.Session();
x = S.sdpvar(3,1);
y = S.sdpvar(2,1);
% Polynomial, callback-free: monomials only, no cones.
obj = (x(1)-1)^2 + (x(2)+2)^2 + x(3)*x(1) + y(1)*y(2);
F = [x(1)^2 + x(2)^2 <= 4, ...
     x(3) + x(1)*x(2) == 1, ...
     y(1)^2 - y(2) <= 0.5, ...
     -3 <= x <= 3, -2 <= y <= 2];
ops = sdpsettings('solver','fmincon','verbose',0);
[~,~,~,idata] = export(F,obj,ops);
model = yalmip2nonlinearsolver(idata);

if isempty(model.evaluation_scheme)
    if verbose
        disp('eval_equivalence: model has no polynomial scheme/Anonlinineq; nothing to compare.');
    end
    ok = false;
    return
end

try
    cm = codermodel(model);
catch ME
    if verbose
        disp(['eval_equivalence: codermodel rejected this model: ' ME.message]);
    end
    ok = false;
    return
end

% The interpreted pair needs its memo object
model.memo = yalmip.EvalMemo();

worst = 0;
for trial = 1:20
    xdec = 2*rand(numel(model.linearindicies),1) - 1;

    [fRef,dfRef] = fmincon_fun(xdec,model);
    [gRef,geqRef,dgRef,dgeqRef] = fmincon_con(xdec,model);

    [fNew,dfNew,gNew,geqNew,dgNew,dgeqNew] = codereval(cm,xdec);

    d = [abs(fNew-fRef), gradnorm(dfNew,dfRef), gradnorm(gNew,gRef), ...
         gradnorm(geqNew,geqRef), matnorm(dgNew,dgRef), matnorm(dgeqNew,dgeqRef)];
    worst = max([worst, d(:)']);
end

ok = worst < 1e-8;
if verbose
    fprintf('eval_equivalence: worst relative deviation %.3e -> %s\n', worst, tern(ok));
end
end

function n = gradnorm(a,b)
a = full(a(:)); b = full(b(:));
if numel(a) ~= numel(b)
    n = inf; return
end
n = norm(a-b)/max(1,norm(b));
end

function n = matnorm(a,b)
a = full(a); b = full(b);
if ~isequal(size(a),size(b))
    n = inf; return
end
n = norm(a-b,'fro')/max(1,norm(b,'fro'));
end

function s = tern(b)
if b, s = 'equal'; else, s = 'DIFFERENT'; end
end
