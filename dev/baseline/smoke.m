function smoke()
%SMOKE Quick syntax/behavior smoke test after Stage 1 edits
addpath(genpath('/media/connor/Data/YALMIP'));
addpath('/opt/mosek/11.2/toolbox/r2019b');
cd('/media/connor/Data/YALMIP');

% 1. Basic QP with fmincon (exercises EvalMemo + fmincon_fun/con + yalmip2nonlinearsolver)
x = sdpvar(2,1);
F = [x(1)+x(2) >= 1, x >= 0];
obj = (x(1)-1)^2 + (x(2)-2)^2;
opt = sdpsettings('solver','fmincon','verbose',0);
sol = optimize(F,obj,opt);
fprintf('fmincon QP: %s obj=%.6f\n', sol.info, value(obj));

% 2. IPOPT-style epigraph (expansion state threading)
y = sdpvar(3,1);
F2 = [max(y) <= 2, sum(y) >= -3, y(1)^2 + y(2)^2 <= 4];
sol2 = optimize(F2, norm(y,1), sdpsettings('solver','fmincon','verbose',0));
fprintf('fmincon operators: %s obj=%.6f\n', sol2.info, value(norm(y,1)));

% 3. Robust-style reusemodel path via expandmodel directly
z = sdpvar(1,1);
options = sdpsettings('allowmilp',0,'allownonconvex',0,'verbose',0);
[Fx,~,~,st] = expandmodel(z^2 <= 1,[],options);
fprintf('expandmodel state: nmodels=%d fields=%d\n', numel(st.ALREADY_MODELLED), numel(fieldnames(st)));

% 4. MILP via linprog/intvar to ensure core intact
b = binvar(3,1);
sol3 = optimize(sum(b) >= 2, -sum(b), sdpsettings('verbose',0));
fprintf('MILP: %s obj=%.1f\n', sol3.info, value(sum(b)));

exit(0);
