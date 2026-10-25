function tests = test_global_st_qpk1
tests = functiontests(localfunctions);

function test1(testCase)
S = yalmip.Session();
% Model generated from st_qpk1.gms
% Created 28-Jul-2007 18:15:36 using YALMIP R20070725

% Setup a clean YALMIP environment 

% Define all variables 
x1 = S.sdpvar(1);
x2 = S.sdpvar(1);

% Define objective function 
objective = -(-(2*x1-2*x1*x1+2*x1*x2+3*x2-2*x2*x2));

% Define constraints 
F = ([]);
F=[F,-x1+x2<=1];
F=[F,x1-x2<=1];
F=[F,-x1+2*x2<=3];
F=[F,2*x1-x2<=3];
F=[F,0<=x1];
F=[F,0<=x2];

% Solve problem
sol = optimize(F,objective,sdpsettings('bmibnb.uppersolver','fmincon','solver','bmibnb'));

testCase.assertTrue(sol.problem==0)
testCase.assertTrue(abs(value(objective, sol)--3) <= 1e-2) 