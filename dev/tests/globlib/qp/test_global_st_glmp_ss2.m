function tests = test_global_st_glmp_ss2
tests = functiontests(localfunctions);

function test1(testCase)
S = yalmip.Session();
% Model generated from st_glmp_ss2.gms
% Created 06-Aug-2007 09:39:34 using YALMIP R20070725

% Setup a clean YALMIP environment 

% Define all variables 
x1 = S.sdpvar(1);
x2 = S.sdpvar(1);
x3 = S.sdpvar(1);
x4 = S.sdpvar(1);
x5 = S.sdpvar(1);

% Define objective function 
objective = -(-x4*x5-x3+0-(0));

% Define constraints 
F = ([]);
F=[F,x1-2*x2<=100];
F=[F,-x1-2*x2<=100];
F=[F,-x1+2*x2>=5];
F=[F,-x1+2*x2<=8];
F=[F,x1+2*x2<=12];
F=[F,x1-x3==0];
F=[F,2*x1-3*x2-x4==-13];
F=[F,x1+x2-x5==1];
F=[F,0<=x1<=7];
F=[F,0<=x2<=6];

% Solve problem
sol = optimize(F,objective,sdpsettings('bmibnb.uppersolver','fmincon','solver','bmibnb'));
testCase.assertTrue(sol.problem==0)
testCase.assertTrue(abs(value(objective, sol)-3) <= 1e-2)