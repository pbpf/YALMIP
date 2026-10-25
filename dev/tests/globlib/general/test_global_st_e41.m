function tests = test_global_st_e41
tests = functiontests(localfunctions);

function test1(testCase)
S = yalmip.Session();
% Model generated from st_e41.gms
% Created 06-Aug-2007 09:45:49 using YALMIP R20070725

% Setup a clean YALMIP environment 

% Define all variables 
x1 = S.sdpvar(1);
x2 = S.sdpvar(1);
x3 = S.sdpvar(1);
x4 = S.sdpvar(1);

% Define objective function 
objective = -(-(200*x1^0.6+200*x2^0.6+200*x3^0.6+300*x4^0.6)+0-(0));

% Define constraints 
F = ([]);
F=[F,-(-x3*sqr(1-x1)*sqr(1-x4)-(1-x3)*sqr(1-x2*(1-(1-x1)*(1-x4))))<=0.1];
F=[F,(-x3*sqr(1-x1)*sqr(1-x4))-(1-x3)*sqr(1-x2*(1-(1-x1)*(1-x4)))<=0];
F=[F,0.5<=x1<=1];
F=[F,0.5<=x2<=1];
F=[F,0.5<=x3<=1];
F=[F,0.5<=x4<=1];

% Solve problem
sol = optimize(F,objective,sdpsettings('bmibnb.uppersolver','fmincon','solver','bmibnb'));
testCase.assertTrue(sol.problem==0)
testCase.assertTrue(abs(value(objective, sol)-641.8236) <= 10)