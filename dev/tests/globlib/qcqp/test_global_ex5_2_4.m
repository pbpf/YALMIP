function tests = test_global_ex5_2_4
tests = functiontests(localfunctions);

function test1(testCase)
S = yalmip.Session();
% Model generated from ex5_2_4.gms
% Created 28-Jul-2007 19:04:36 using YALMIP R20070725

% Setup a clean YALMIP environment 

% Define all variables 
x1 = S.sdpvar(1);
x2 = S.sdpvar(1);
x3 = S.sdpvar(1);
x4 = S.sdpvar(1);
x5 = S.sdpvar(1);
x6 = S.sdpvar(1);
x7 = S.sdpvar(1);
objvar = S.sdpvar(1);

% Define constraints 
objvar = -((9+(-6*x1)-16*x2-15*x3)*x4+(15+(-6*x1)-16*x2-15*x3)*x5)+x6-5*x7;
F = ([]);
F=[F,x3*x4+x3*x5<=50];
F=[F,x4+x6<=100];
F=[F,x5+x7<=200];
F=[F,(3*x1+x2+x3-2.5)*x4-0.5*x6<=0];
F=[F,(3*x1+x2+x3-1.5)*x5+0.5*x7<=0];
F=[F,x1+x2+x3==1];
F=[F,0<=x1<=1];
F=[F,0<=x2<=1];
F=[F,0<=x3<=1];
F=[F,0<=x4<=100];
F=[F,0<=x5<=200];
F=[F,0<=x6<=100];
F=[F,0<=x7<=200];

% Solve problem
sol = optimize(F,objvar,sdpsettings('bmibnb.uppersolver','fmincon','solver','bmibnb'));

testCase.assertTrue(sol.problem==0)
testCase.assertTrue(abs(value(objvar, sol)--450) <= 2)