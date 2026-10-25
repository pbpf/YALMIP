function smoke3()
%SMOKE3 Stage 3 integration smoke test: session API end-to-end
addpath(genpath('/media/connor/Data/YALMIP'));
addpath('/opt/mosek/11.2/toolbox/r2019b');
cd('/media/connor/Data/YALMIP');

% 1. Session-based creation with display names
S = yalmip.Session();
x = S.sdpvar("x",[3 1]);
u = S.intvar("u",2,2);
b = S.binvar("b",2,1);
fprintf('creation ok: x is %s, u is %s, b is %s\n', class(x), class(u), class(b));

% 2. Constraint creation + optimize with automatic session discovery
F = [x >= 1, sum(u) <= 10, b(1) + b(2) >= 1, implies(b(1),b(2))];
obj = sum(x) + sum(sum(u));
ops = sdpsettings('verbose',0);
sol = optimize(F, obj, ops);
fprintf('MILP: %s obj=%.4f\n', sol.info, value(obj, sol));

% 3. value/dual with explicit sol
v = value(x(2), sol);
d = dual(x >= 1, sol);
fprintf('value/dual: v=%.4f dual=%.4f\n', v, d);

% 4. Nonlinear operators (expansion machinery + session threading)
y = S.sdpvar(2,1);
F2 = [max(y) <= 2, exp(y(1)) + y(2) <= 10, y >= 0];
sol2 = optimize(F2, sum(y), sdpsettings('solver','fmincon','verbose',0));
fprintf('NLP with operators: %s obj=%.4f\n', sol2.info, value(sum(y), sol2));

% 5. Multi-session isolation
S2 = yalmip.Session();
x2 = S2.sdpvar(2,1);
try
    z = x + x2;
    fprintf('SESSION ISOLATION: FAILED (mixing allowed)\n');
catch
    fprintf('session isolation: OK (mixing errors)\n');
end

% 6. Old API errors with migration message
try
    q = sdpvar(2,2);
    fprintf('OLD API: FAILED (still accepted)\n');
catch
    fprintf('old API rejection: OK\n');
end

% 7. sdisplay uses embedded names
sd = sdisplay(x(1) + x(2)^2); fprintf('sdisplay: %s\n', sd{1});

% 8. Parametric optimizer object
t = S.sdpvar("t",1,1);
P = optimizer(x >= t, sum(x), sdpsettings('verbose',0), t, x);
vals = P{2};
fprintf('optimizer: ok, first=%g\n', vals(1));

% 9. Version function
fprintf('version: %s\n', yalmipversion());

exit(0);
