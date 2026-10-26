function [f,df,g,geq,dg,dgeq,xevaled] = codereval(cm,x)
%CODEREVAL Coder-compatible evaluation core for a codermodel.
%
%   [f,df] = codereval(cm,x) evaluates the objective of a model prepared by
%   CODERMODEL at the decision point x. With more outputs it also returns the
%   polynomial constraint rows and their Jacobians:
%
%     [f,df,g,geq,dg,dgeq,xevaled] = codereval(cm,x)
%
%   The function is a pure function of (cm,x): everything is dense, all loop
%   bounds come from the input shapes, and there is no array growth, no
%   try/catch and no runtime function lookup, so it compiles with MATLAB Coder.
%   It mirrors the interpreted pair fmincon_fun/fmincon_con and is numerically
%   equivalent for the supported (polynomial, callback-free) models.
%
%   See also CODERMODEL, CODEGEN_EVAL_DEMO

x = x(:);
nFull = cm.nFull;
nDec  = cm.nDec;

% Expanded variable values; the decision variables sit at linearindicies and
% every scheme entry only depends on values that were computed before it.
xevaled = zeros(nFull,1);
xevaled(cm.linearindicies) = x;

% d(xevaled)/d(x), dense because the chain runs through the scheme entries.
J = zeros(nFull,nDec);
for i = 1:nDec
    J(cm.linearindicies(i),i) = 1;
end

for k = 1:cm.nScheme
    idx = cm.schemeVars(k);
    row = cm.powers(k,:);

    val = 1;
    for j = 1:nFull
        e = row(j);
        if e ~= 0
            val = val * xevaled(j)^e;
        end
    end
    xevaled(idx) = val;

    dval = 0;
    for j = 1:nFull
        e = row(j);
        if e ~= 0
            term = e * xevaled(j)^(e-1);
            for i = 1:nFull
                if i ~= j && row(i) ~= 0
                    term = term * xevaled(i)^row(i);
                end
            end
            dval = dval + term * J(j,:);
        end
    end
    J(idx,:) = dval;
end

% Objective f = f0 + c'*x + x'*Q*x
f = cm.f0 + cm.c'*xevaled + xevaled'*(cm.Q*xevaled);
df = J'*(cm.c + (cm.Q + cm.Q')*xevaled);

% Polynomial constraint rows a'*x - b
g   = cm.Aineq*xevaled - cm.bineq;
dg  = (cm.Aineq*J)';
geq = cm.Aeq*xevaled - cm.beq;
dgeq = (cm.Aeq*J)';
