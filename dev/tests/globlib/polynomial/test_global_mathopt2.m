function tests = test_global_mathopt2
tests = functiontests(localfunctions);

function test1(testCase)
S = yalmip.Session();
% Model generated from mathopt2.gms
% Created 24-Jul-2007 13:39:10 using YALMIP R20070523

% Setup a clean YALMIP environment 

% Define all variables 
x1 = S.sdpvar(1);
x2 = S.sdpvar(1);

% Define objective function 
objective = -(-(sqr(2*sqr(x1)-x2)+sqr(x2-6*sqr(x1))));

% Define constraints 
F = ([]);
F=[F,x1-(x1*x2+10*x2)==0];
F=[F,x1-3*x2==0];
F=[F,x1+x2<=1];
F=[F,-x1+x2<=2];

% Solve problem
sol = optimize(F,objective,sdpsettings('bmibnb.uppersolver','fmincon','solver','bmibnb'));
testCase.assertTrue(sol.problem==0)
testCase.assertTrue(abs(value(objective, sol)-0) <= 1e-2)