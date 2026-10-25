function tests = test_operator_optimizer15
tests = functiontests(localfunctions);

function test1(testCase)
S = yalmip.Session();

x = S.sdpvar(1,1);
y = S.sdpvar(1,1);
z = S.sdpvar(1,1);
P = optimizer([x <= y*z],x^2,sdpsettings('solver','+quadprog'),[y;z],x)
testCase.assertTrue(abs(P{[-2;5]}--10) <= 1e-4);