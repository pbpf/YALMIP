function tests = test_global_prob05
tests = functiontests(localfunctions);

function test1(testCase)
S = yalmip.Session();
% Model generated from prob05.gms
% Created 24-Jul-2007 13:49:10 using YALMIP R20070523

% Setup a clean YALMIP environment 

% Define all variables 
x1 = S.sdpvar(1);
x2 = S.sdpvar(1);

% Define objective function 
objective = -(-2*x1-x2);

% Define constraints 
F = ([]);
F=[F,-16*x1*x2<=-1];
F=[F,(-4*sqr(x1))-4*sqr(x2)<=-1];
F=[F,0.001<=x1<=1];
F=[F,0.001<=x2<=1];

% Solve problem
sol = optimize(F,objective,sdpsettings('bmibnb.uppersolver','fmincon','solver','bmibnb'));
testCase.assertTrue(sol.problem==0)
testCase.assertTrue(abs(value(objective, sol)-0.7418) <= 1e-1)