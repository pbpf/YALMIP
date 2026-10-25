function tests = test_global_fct
tests = functiontests(localfunctions);

function test1(testCase)
S = yalmip.Session();
% Model generated from fct.gms
% Created 28-Jul-2007 18:05:59 using YALMIP R20070725

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

objvar=(2*x6+x7)

% Define constraints 
F = ([]);
F=[F,-(sqr(x8)+sqr(x9)+sqr(x10)+sqr(x11)+sqr(x12))+x7==0];
F=[F,-x3-x5+x6==0];
F=[F,-(sqr(sqr(x8)-x9)+sqr(x10)+2*sqr(x11)+sqr(x12-x9))+x2==0];
F=[F,-abs(sin(4*mod(x2,3.14159265358979)))+x3==0];
F=[F,-(sqr(x8+x9-x10+x11-x12)+2*sqr(x9-x8+x10-x11+x12))+x4==0];
F=[F,-abs(sin(3*mod(x4,3.14159265358979)))+x5==0];
F=[F,3*sqr(x9)+sqr(x10)-2*sqr(x11)+sqr(x12)+x8==0];
F=[F,x8+4*x9-x10+x11-3*x12==0];
F=[F,sqr(x8)-sqr(x10)+2*sqr(x9)-sqr(x11)-sqr(x12)==0];
F=[F,-10<=x8<=5];
F=[F,-10<=x9<=5];
F=[F,-10<=x10<=5];
F=[F,-10<=x11<=5];
F=[F,-10<=x12<=5];

% Solve problem
sol = optimize(F,objvar,sdpsettings('bmibnb.uppersolver','fmincon','solver','bmibnb'));

testCase.assertTrue(sol.problem==0)
testCase.assertTrue(abs(value(objvar, sol)-0) <= 1e-2) 