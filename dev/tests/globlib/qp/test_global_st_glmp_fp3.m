function tests = test_global_st_glmp_fp3
tests = functiontests(localfunctions);

function test1(testCase)
S = yalmip.Session();
% Model generated from st_glmp_fp3.gms
% Created 06-Aug-2007 09:41:18 using YALMIP R20070725

% Setup a clean YALMIP environment 

% Define all variables 
x1 = S.sdpvar(1);
x2 = S.sdpvar(1);
x3 = S.sdpvar(1);
x4 = S.sdpvar(1);

% Define objective function 
objective = -(-x3*x4+0-(0));

% Define constraints 
F = ([]);
F=[F,2*x1+x2<=2];
F=[F,x1+x2<=2];
F=[F,-4*x1+x2<=12];
F=[F,-2*x1-x2<=6];
F=[F,-x1-2*x2<=6];
F=[F,x1-x2<=3];
F=[F,x1+x2-x3==0];
F=[F,x1-x2-x4==0];
F=[F,-10<=x1<=1];
F=[F,-10<=x2<=10];

% Solve problem
sol = optimize(F,objective,sdpsettings('bmibnb.uppersolver','fmincon','solver','bmibnb'));
testCase.assertTrue(sol.problem==0)
testCase.assertTrue(abs(value(objective, sol)--12) <= 1e-2)