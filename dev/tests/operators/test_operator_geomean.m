function tests = test_geomean
tests = functiontests(localfunctions);

function test1(testCase)
S = yalmip.Session();
% Test real vector geomean, length == 2^n
randn('seed',1234);
rand('seed',1234);
A = randn(15,2);
b = rand(15,1)*5;
x = S.sdpvar(2,1);
obj = geomean(b-A*x);
sol = optimize([],-obj);
testCase.assertTrue(norm(value(x', sol)-[-0.055 0.2697]) <= 1e-2);

% Test real vector geomean, length == 2^n
randn('seed',1234);
rand('seed',1234);
A = randn(16,2);
b = rand(16,1)*5;
x = S.sdpvar(2,1);
obj = geomean(b-A*x);
optsol = optimize([],-obj);
testCase.assertTrue(norm(value(x', optsol) - [-0.0114 -0.2072]) <= 1e-2);

% Test real matrix geomean, length ~2^n
randn('seed',1234);
rand('seed',1234);
D = randn(5,5);
P = S.sdpvar(5,5);
obj = geomean(P);
optsol2 = optimize((P <= D*D'),-obj);
testCase.assertTrue(abs(value(obj, optsol2) - 2.003) <= 1e-3);
 
% Test real matrix geomean, length == 2^n
randn('seed',1234);
rand('seed',1234);
D = randn(8,8);
P = S.sdpvar(8,8);
obj = geomean(P);
optsol3 = optimize((P <= D*D'),-obj);
testCase.assertTrue(abs(value(obj, optsol3) - 3.322) <= 1e-3);

% Test real matrix geomean, length == 2
randn('seed',1234);
rand('seed',1234);
D = randn(2,2);
P = S.sdpvar(2,2);
obj = geomean(P);
optsol4 = optimize((P <= D*D'),-obj);
testCase.assertTrue(abs(value(obj, optsol4) - 2.0289) <= 1e-3);


function test2(testCase)
S = yalmip.Session();
% Test complex matrix geomean, length ~2^n
randn('seed',1234);
rand('seed',1234);
D = randn(5,5)+sqrt(-1)*randn(5,5);D = D + D'+eye(5)*10;
P = S.sdpvar(5,5,'he','co');
obj = geomean(P);
sol = optimize((P <= D),-obj);
testCase.assertTrue(abs(value(obj, sol) - 9.075) <= 1e-2)
 
% Test complex matrix geomean, length == 2^n
randn('seed',1234);
rand('seed',1234);
D = randn(8,8)+sqrt(-1)*randn(8,8);D = D + D'+eye(8)*20;
P = S.sdpvar(8,8,'he','co');
obj = geomean(P);
optsol = optimize((P <= D),-obj);
testCase.assertTrue((value(obj, optsol) - 18.4207) <= 1e-2)
 