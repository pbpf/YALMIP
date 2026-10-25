function tests = test_global_st_glmp_kky
tests = functiontests(localfunctions);

function test1(testCase)
S = yalmip.Session();
% Model generated from st_glmp_kky.gms
% Created 06-Aug-2007 09:40:18 using YALMIP R20070725

% Setup a clean YALMIP environment 

% Define all variables 
x1 = S.sdpvar(1);
x2 = S.sdpvar(1);
x3 = S.sdpvar(1);
x4 = S.sdpvar(1);
x5 = S.sdpvar(1);
x6 = S.sdpvar(1);
x7 = S.sdpvar(1);

% Define objective function 
objective = -(-(x4*x5+x6*x7)-x3+0-(0));

% Define constraints 
F = ([]);
F=[F,-5*x1+8*x2<=24];
F=[F,-5*x1-8*x2<=100];
F=[F,-6*x1+3*x2<=100];
F=[F,-4*x1-5*x2<=-10];
F=[F,5*x1-8*x2<=100];
F=[F,5*x1+8*x2<=44];
F=[F,6*x1-3*x2<=15];
F=[F,4*x1+5*x2<=100];
F=[F,3*x1-4*x2-x3==0];
F=[F,x1+2*x2-x4==1.5];
F=[F,2*x1-x2-x5==-4];
F=[F,x1-2*x2-x6==-8.5];
F=[F,2*x1+x2-x7==1];
F=[F,0<=x1<=10];
F=[F,0<=x2<=10];

% Solve problem
sol = optimize(F,objective,sdpsettings('bmibnb.uppersolver','fmincon','solver','bmibnb'));
testCase.assertTrue(sol.problem==0)
testCase.assertTrue(abs(value(objective, sol)--2.5) <= 1e-2)