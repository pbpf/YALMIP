function tests = test_global_ex9_2_8
tests = functiontests(localfunctions);

function test1(testCase)
S = yalmip.Session();
% Model generated from ex9_2_8.gms
% Created 28-Jul-2007 18:04:59 using YALMIP R20070725

% Setup a clean YALMIP environment 

% Define all variables 
objvar = S.sdpvar(1);
x2 = S.sdpvar(1);
x3 = S.sdpvar(1);
x4 = S.sdpvar(1);
x5 = S.sdpvar(1);
x6 = S.sdpvar(1);
x7 = S.sdpvar(1);

objvar = 3*x3-4*x2*x3+2*x2+1;

% Define constraints 
F = ([]);
F=[F,-x3+x4==0];
F=[F,x3+x5==1];
F=[F,x6*x4==0];
F=[F,x7*x5==0];
F=[F,4*x2-x6+x7==1];
F=[F,0<=x2<=1];
F=[F,0<=x3];
F=[F,0<=x4<=20];
F=[F,0<=x5<=20];
F=[F,0==x6];
F=[F,0==x7];

% Solve problem
sol = optimize(F,objvar,sdpsettings('bmibnb.uppersolver','fmincon','solver','bmibnb'));

testCase.assertTrue(sol.problem==0)
testCase.assertTrue(abs(value(objvar, sol)-1.5) <= 1e-2) 