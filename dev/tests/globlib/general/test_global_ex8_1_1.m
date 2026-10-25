function tests = test_global_ex8_1_1
tests = functiontests(localfunctions);

function test1(testCase)
S = yalmip.Session();
% Model generated from ex8_1_1.gms
% Created 28-Jul-2007 19:11:42 using YALMIP R20070725

% Setup a clean YALMIP environment 

% Define all variables 
x1 = S.sdpvar(1);
x2 = S.sdpvar(1);

% Define objective function 
objective = -(-(cos(x1)*sin(x2)-x1/(1+sqr(x2))));

% Define constraints 
F = ([]);
F=[F,-1<=x1<=2];
F=[F,-1<=x2<=1];

% Solve problem
sol = optimize(F,objective,sdpsettings('bmibnb.uppersolver','fmincon','solver','bmibnb'));
testCase.assertTrue(sol. problem == 0)
testCase.assertTrue(abs(value(objective, sol)--2.0218) <= 1e-1)