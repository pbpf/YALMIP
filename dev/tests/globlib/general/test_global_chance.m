function tests = test_global_chance
tests = functiontests(localfunctions);

function test1(testCase)
S = yalmip.Session();
% Model generated from chance.gms
% Created 28-Jul-2007 17:29:58 using YALMIP R20070725

% Setup a clean YALMIP environment 

% Define all variables 
objvar = S.sdpvar(1);
x2 = S.sdpvar(1);
x3 = S.sdpvar(1);
x4 = S.sdpvar(1);
x5 = S.sdpvar(1);

% Define constraints 
F = ([]);
F=[F,objvar-24.55*x2-26.75*x3-39*x4-40.5*x5==0];
F=[F,x2+x3+x4+x5==1];
F=[F,12*x2-1.645*sqrtm(0.28*sqr(x2)+0.19*sqr(x3)+20.5*sqr(x4)+0.62*sqr(x5))+11.9*x3+41.8*x4+52.1*x5>=21];
F=[F,2.3*x2+5.6*x3+11.1*x4+1.3*x5>=5];
F=[F,0<=x2];
F=[F,0<=x3];
F=[F,0<=x4];
F=[F,0<=x5];

% Solve problem
sol = optimize(F,objvar,sdpsettings('bmibnb.uppersolver','fmincon','solver','bmibnb'));

testCase.assertTrue(sol.problem==0)
testCase.assertTrue(abs(value(objvar, sol)-29.8944) <= 1e-2) 