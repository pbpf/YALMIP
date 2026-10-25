function tests = test_global_st_jcbpafex
tests = functiontests(localfunctions);

function test1(testCase)
S = yalmip.Session();
% Model generated from st_jcbpafex.gms
% Created 06-Aug-2007 09:36:40 using YALMIP R20070725

% Setup a clean YALMIP environment 

% Define all variables 
x1 = S.sdpvar(1);
x2 = S.sdpvar(1);

% Define objective function 
objective = -(-(x1*x2-x1-x2)+0-(0));

% Define constraints 
F = ([]);
F=[F,-6*x1+8*x2<=3];
F=[F,3*x1-x2<=3];
F=[F,0<=x1<=5];
F=[F,0<=x2<=5];

% Solve problem
sol = optimize(F,objective,sdpsettings('bmibnb.uppersolver','fmincon','solver','bmibnb'));
testCase.assertTrue(sol.problem==0)
testCase.assertTrue(abs(value(objective, sol)--1.0833) <= 1e-2)