function tests = test_global_wall
tests = functiontests(localfunctions);

function test1(testCase)
S = yalmip.Session();
% Model generated from wall.gms
% Created 21-Aug-2007 17:09:27 using YALMIP R20070810

% Setup a clean YALMIP environment 

% Define all variables 
objvar = S.sdpvar(1);
x2 = S.sdpvar(1);
x3 = S.sdpvar(1);
x4 = S.sdpvar(1);
x5 = S.sdpvar(1);
x6 = S.sdpvar(1);

% Define constraints 

F = ([x2 x3 x4 x5 x6]>=0);
F=[F,objvar*x2==1];
F=[F,x3 == 4.8*x4*objvar];
F=[F,x5==0.98*x2*x6];
F=[F,x6*x4==1];
F=[F,objvar-x2+1E-7*x3-1E-5*x5==0];
F=[F,2*objvar-2*x2+1E-7*x3-0.01*x4-1E-5*x5+0.01*x6==0];

% Solve problem
sol = optimize(F,objvar,sdpsettings('bmibnb.uppersolver','fmincon','solver','bmibnb'));
testCase.assertTrue(sol.problem==0 || sol.problem == 4)
testCase.assertTrue(abs(value(objvar, sol)-1) <= 1e-2)