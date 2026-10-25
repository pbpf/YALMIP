function tests = test_global_st_robot
tests = functiontests(localfunctions);

function test1(testCase)
S = yalmip.Session();
% Model generated from st_robot.gms
% Created 28-Jul-2007 18:17:16 using YALMIP R20070725

% Setup a clean YALMIP environment 

% Define all variables 
x1 = S.sdpvar(1);
x2 = S.sdpvar(1);
x3 = S.sdpvar(1);
x4 = S.sdpvar(1);
x5 = S.sdpvar(1);
x6 = S.sdpvar(1);
x7 = S.sdpvar(1);
x8 = S.sdpvar(1);

% Define objective function 
objective = -(0);

% Define constraints 
F = ([]);
F=[F,0.004731*x1*x3-0.1238*x1-0.3578*x2*x3-0.001637*x2-0.9338*x4+x7==0.3571];
F=[F,0.2238*x1*x3+0.2638*x1+0.7623*x2*x3-0.07745*x2-0.6734*x4-x7==0.6022];
F=[F,x6*x8+0.3578*x1+0.004731*x2==0];
F=[F,-0.7623*x1+0.2238*x2==-0.3461];
F=[F,power(x1,2)+power(x2,2)==1];
F=[F,power(x3,2)+power(x4,2)==1];
F=[F,power(x5,2)+power(x6,2)==1];
F=[F,power(x7,2)+power(x8,2)==1];
F=[F,-1<=x1<=1];
F=[F,-1<=x2<=1];
F=[F,-1<=x3<=1];
F=[F,-1<=x4<=1];
F=[F,-1<=x5<=1];
F=[F,-1<=x6<=1];
F=[F,-1<=x7<=1];
F=[F,-1<=x8<=1];

% Solve problem
sol = optimize(F,objective,sdpsettings('bmibnb.uppersolver','fmincon','solver','bmibnb'));

testCase.assertTrue(sol.problem==0)
testCase.assertTrue(abs(value(objective, sol)-0) <= 1e-2) 