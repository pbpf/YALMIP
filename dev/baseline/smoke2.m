function smoke2()
%SMOKE2 Stage 2 smoke test: lmi templates, hash draws, memo paths
addpath(genpath('/media/connor/Data/YALMIP'));
addpath('/opt/mosek/11.2/toolbox/r2019b');
cd('/media/connor/Data/YALMIP');

% lmi creation (formerly persistent temp/F0)
x = sdpvar(3,1);
F = [x >= 1, sum(x) <= 10, x(1)^2 <= 4];
sol = optimize(F, sum(x), sdpsettings('verbose',0));
fprintf('lmi QP: %s obj=%.4f\n', sol.info, value(sum(x)));

% hash draws (stateless)
h1 = gen_rand_hash(0,5,1);
h2 = gen_rand_hash(0,5,1);
fprintf('hash deterministic: %d, range ok: %d\n', isequal(h1,h2), all(isfinite(h1)));

% parametric optimizer path (uses gen_rand_hash + memo machinery)
u = sdpvar(1,1); t = sdpvar(1,1);
F3 = [u + t >= -1, u - t >= -2, 3*u + t <= 5];
obj = (u-1)^2;
P = optimizer(F3, obj, sdpsettings('verbose',0), u, [u;t]);
sol3 = P{0.5};
fprintf('optimizer parametric: usol=%.4f\n', sol3(1));

% nonlinear memo path again (apply_recursive_differentiation diffCache)
z = sdpvar(2,1);
sol4 = optimize([z(1)*z(2) >= 2, exp(z(1)) + z(2) <= 10, z >= -5], sum(z), sdpsettings('solver','fmincon','verbose',0));
fprintf('fmincon nonlinear: %s obj=%.4f\n', sol4.info, value(sum(z)));

exit(0);
