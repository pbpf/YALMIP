function tests = test_operator_optimizer2
tests = functiontests(localfunctions);

function test1(testCase)
S = yalmip.Session();
% Tests issue #39
x = S.sdpvar(1,1);
z = S.sdpvar(1,1);
y = S.sdpvar(1,1);
P = optimizer([-1 <= y <= 1,x <= 10+z*x],x^2,[],[y;z],x)
[~,err] = P{[0;5]};
testCase.assertTrue(err == 0);

function test2(testCase)
S = yalmip.Session();
x = S.sdpvar(1,1);
y = S.sdpvar(1,1);
z = S.sdpvar(1,1);
P = optimizer([-1 <= y <= 1,x <= 10+z*x],x^2,[],[y;z],x)
[~,err] = P{[0;5]};
testCase.assertTrue(err == 0);
