function tests = test_global_ex4_1_4
tests = functiontests(localfunctions);

function test1(testCase)
S = yalmip.Session();
% Model generated from ex4_1_4.gms
% Created 28-Jul-2007 18:51:43 using YALMIP R20070725

% Setup a clean YALMIP environment 

% Define all variables 
x1 = S.sdpvar(1);

% Define objective function 
objective = -(-(4*sqr(x1)-4*power(x1,3)+power(x1,4)));

% Define constraints 
F = ([]);
F=[F,-5<=x1<=5];

% Solve problem
sol = optimize(F,objective,sdpsettings('bmibnb.uppersolver','fmincon','solver','bmibnb'));

testCase.assertTrue(sol.problem==0)
testCase.assertTrue(abs(value(objective, sol)- 0) <= 1e-2) 