function tests = test_global_ex9_1_1
tests = functiontests(localfunctions);

function test1(testCase)
S = yalmip.Session();
% Model generated from ex9_1_1.gms
% Created 11-Mar-2008 15:58:14 using YALMIP R20070810

% Setup a clean YALMIP environment 

% Define all variables 
x1 = S.sdpvar(1);
x2 = S.sdpvar(1);
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

% Define objective function 
objective = -3*x1+2*x2-0-x4-(0);

% Define constraints 
F = ([]);
F=[F,x1+4*x2-2*x4+x5==16];
F=[F,3*x1-2*x2+8*x4+x6==48];
F=[F,x1-3*x2-2*x4+x7==-12];
F=[F,-x1+x8==0];
F=[F,x1+x9==4];
F=[F,x10*x5==0];
F=[F,x11*x6==0];
F=[F,x12*x7==0];
F=[F,x13*x8==0];
F=[F,x14*x9==0];
F=[F,x10+3*x11+x12-x13+x14==1];
F=[F,2*x11-3*x12==0];
F=[F,0<=x4];
F=[F,0<=x5];
F=[F,0<=x6];
F=[F,0<=x7];
F=[F,0<=x8];
F=[F,0<=x9];
F=[F,0<=x10];
F=[F,0<=x11];
F=[F,0<=x12];
F=[F,0<=x13];
F=[F,0<=x14];

% Solve problem
sol = optimize(F,objective,sdpsettings('bmibnb.uppersolver','fmincon','solver','bmibnb'));
testCase.assertTrue(sol.problem==0)
testCase.assertTrue(abs(value(objective, sol)--13) <= 1e-2)