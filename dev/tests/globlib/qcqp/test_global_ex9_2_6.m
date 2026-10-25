function tests = test_global_ex9_2_6
tests = functiontests(localfunctions);

function test1(testCase)
S = yalmip.Session();
% Model generated from ex9_2_6.gms
% Created 28-Jul-2007 18:03:04 using YALMIP R20070725

% Setup a clean YALMIP environment 

% Define all variables 
objvar = S.sdpvar(1);
x2 = S.sdpvar(1);
x3 = S.sdpvar(1);
x4 = S.sdpvar(1);
x5 = S.sdpvar(1);
x6 = S.sdpvar(1);
x7 = S.sdpvar(1);
x8 = S.sdpvar(1);
x9 = S.sdpvar(1);
x10 = S.sdpvar(1);
x11 = S.sdpvar(1);
x12 = S.sdpvar(1);
x13 = S.sdpvar(1);
x14 = S.sdpvar(1);
x15 = S.sdpvar(1);
x16 = S.sdpvar(1);
x17 = S.sdpvar(1);

% Define constraints 
objvar=x2*x2-2*x2+x3*x3-2*x3+x4*x4+x5*x5;
F = ([]);
F=[F,-x4+x6==-0.5];
F=[F,-x5+x7==-0.5];
F=[F,x4+x8==1.5];
F=[F,x5+x9==1.5];
F=[F,x6*x12==0];
F=[F,x7*x13==0];
F=[F,x8*x14==0];
F=[F,x9*x15==0];
F=[F,x10*x16==0];
F=[F,x11*x17==0];
F=[F,-2*x2+2*x4-x12+x14==0];
F=[F,-2*x3+2*x5-x13+x15==0];
F=[F,0<=x2];
F=[F,0<=x3];
F=[F,0<=x4];
F=[F,0<=x5];
F=[F,0<=x6<=200];
F=[F,0<=x7<=200];
F=[F,0<=x8<=200];
F=[F,0<=x9<=200];
F=[F,0<=x10<=200];
F=[F,0<=x11<=200];
F=[F,0<=x12<=200];
F=[F,0<=x13<=200];
F=[F,0<=x14<=200];
F=[F,0<=x15<=200];
F=[F,0<=x16<=200];
F=[F,0<=x17<=200];

% Solve problem
sol = optimize(F,objvar,sdpsettings('bmibnb.uppersolver','fmincon','solver','bmibnb'))
testCase.assertTrue(sol.problem==0)
testCase.assertTrue(abs(value(objvar, sol)--1) <= 1e-2)

