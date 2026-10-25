function tests = test_mpt_dpmpqp
tests = functiontests(localfunctions);

function test1(dummy)
S = yalmip.Session();

% Model data
A = [2 -1;1 0];
B = [1;0];
C = [0.5 0.5];
nx = 2; % Number of states
nu = 1; % Number of inputs

% Prediction horizon
N = 5;
% States x(k), ..., x(k+N)
x = S.sdpvar(repmat(nx,1,N),repmat(1,1,N));
% Inputs u(k), ..., u(k+N) (last one not used) u = sdpvar(repmat(nu,1,N),repmat(1,1,N));
u = S.sdpvar(repmat(nu,1,N),repmat(1,1,N));

J{N} = 0;
F = ([]);
for k = N-1:-1:1

    % Feasible region
    F = (-1 <= u{k}     <= 1);
    F = F + (-1 <= C*x{k}   <= 1);
    F = F + (-5 <= x{k}     <= 5);
    F = F + (-1 <= C*x{k+1} <= 1);
    F = F + (-5 <= x{k+1}   <= 5);
    % Dynamics
    F = F + (x{k+1} == A*x{k}+B*u{k});
    % Cost in value iteration
    %  obj = obj + x{k}'*x{k} + u{k}'*u{k}
    obj = x{k}'*x{k} + u{k}'*u{k} + J{k+1};
    % Solve one-step problem
    [sol{k},diagnost{k},Uz{k},J{k},Optimizer{k}] = solvemp(F,obj,sdpsettings('solver','mpt'),x{k},u{k});    
end

optsol = struct('eval',struct('variables',[],'optvar',[],'values',[]));
optsol = assign(x{k},[1;0.5], optsol)
assert(diagnost{1}.problem == 0);
assert(abs(value(J{k}, optsol) - 3.82456140350877) <= 1e-5);

optsol = assign(x{k},[0.5;1], optsol)
assert(abs(value(J{k}, optsol) - 1.6140350) <= 1e-5);

optsol = assign(x{k},[0;1.9], optsol)
assert(abs(value(J{k}, optsol) - 8.755) <= 1e-5);

optsol = assign(x{k},[-0.1;-1.85], optsol)
assert(abs(value(J{k}, optsol) - 6.61825) <= 1e-5);


