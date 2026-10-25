function tests = test_operator_exp
tests = functiontests(localfunctions);

function test1(testCase)
S = yalmip.Session();

x = S.sdpvar(1,1);
y = S.sdpvar(1,1);
obj = -x;
sol = optimize((exp(2*x + 1) <= 3),obj,sdpsettings('solver','fmincon'));

testCase.assertTrue(sol.problem == 0)
testCase.assertTrue(abs(value(obj, sol)--0.04930614506222) <= 1e-4);

function test2(testCase)
S = yalmip.Session();
x = S.sdpvar(1,1);
y = S.sdpvar(1,1);
obj = -x-y;
sol = optimize((exp(max([2*x+1 3*y+2])) <= 3),obj,sdpsettings('solver','fmincon'));

testCase.assertTrue(sol.problem == 0)
testCase.assertTrue(abs(value(obj, sol)-0.25115642610991) <= 1e-4);

function test3(testCase)
S = yalmip.Session();
x = S.sdpvar(1,1);
y = S.sdpvar(1,1);
obj = -x-y;
sol = optimize((exp(min([2*x+1 3*y+2])) <= 3),obj,sdpsettings('solver','fmincon','warning',0));
testCase.assertTrue(sol.problem == -4)

function test4(testCase)
S = yalmip.Session();
x = S.sdpvar(1,1);
y = S.sdpvar(1,1);
obj = -x-y;
sol = optimize((max([exp(2*x+1) exp(3*y+2)]) <= 3),obj,sdpsettings('solver','fmincon'));

testCase.assertTrue(sol.problem == 0)
testCase.assertTrue(abs(value(obj, sol)-0.25115642610991) <= 1e-4);
