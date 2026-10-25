function tests = test_global_ex4_1_8
tests = functiontests(localfunctions);

function test1(testCase)
S = yalmip.Session();
% Model generated from ex4_1_8.gms
% Created 28-Jul-2007 18:54:37 using YALMIP R20070725

% Setup a clean YALMIP environment 

% Define all variables 
x1 = S.sdpvar(1);
x2 = S.sdpvar(1);
objvar = S.sdpvar(1);

% Define constraints 
objvar = -(-(sqr(x2)-7*x2)+12*x1);
F = ([]);
F=[F,-2*power(x1,4)-x2==-2];
F=[F,0<=x1<=2];
F=[F,0<=x2<=3];

% Solve problem
sol = optimize(F,objvar,sdpsettings('bmibnb.uppersolver','fmincon','solver','bmibnb'));

testCase.assertTrue(sol.problem==0)
testCase.assertTrue(abs(value(objvar, sol)- -16.7389) <= 1e-2) 