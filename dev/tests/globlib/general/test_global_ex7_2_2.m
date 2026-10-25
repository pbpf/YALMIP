function tests = test_global_ex7_2_2
tests = functiontests(localfunctions);

function test1(testCase)
S = yalmip.Session();
% Model generated from ex7_2_2.gms
% Created 28-Jul-2007 17:38:18 using YALMIP R20070725

% Setup a clean YALMIP environment 

% Define all variables 
x1 = S.sdpvar(1);
x2 = S.sdpvar(1);
x3 = S.sdpvar(1);
x4 = S.sdpvar(1);
x5 = S.sdpvar(1);
x6 = S.sdpvar(1);
objvar = S.sdpvar(1);

% Define constraints 
objvar = -x4;
F = ([]);
F=[F,0.09755988*x1*x5+x1==1];
F=[F,0.0965842812*x2*x6+x2-x1==0];
F=[F,0.0391908*x3*x5+x3+x1==1];
F=[F,0.03527172*x4*x6+x4-x1+x2-x3==0];
F=[F,x5^0.5+x6^0.5<=4];
F=[F,0<=x1<=1];
F=[F,0<=x2<=1];
F=[F,0<=x3<=1];
F=[F,0<=x4<=1];
F=[F,1e-005<=x5<=16];
F=[F,1e-005<=x6<=16];

% Solve problem
sol = optimize(F,objvar,sdpsettings('bmibnb.uppersolver','fmincon','solver','bmibnb'))

testCase.assertTrue(sol.problem==0)
testCase.assertTrue(abs(value(objvar, sol)--0.3888) <= 1e-3)