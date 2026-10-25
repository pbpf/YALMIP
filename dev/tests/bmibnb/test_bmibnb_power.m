function tests = test_global_power
tests = functiontests(localfunctions);

function test1(testCase)
S = yalmip.Session();

x = S.sdpvar(1,1);
y = S.sdpvar(1,1);
ops =sdpsettings('solver','bmibnb');
sol = optimize([0 <= [x] <= 5, -5 <= y <= 5, x==.1], (x^y-10)^2,ops)

testCase.assertTrue(sol.problem==0)
testCase.assertTrue(abs(value(y, sol)--1) <= 1e-3)

function test2(testCase)
S = yalmip.Session();

x = S.sdpvar(2,1);
y = S.sdpvar(2,1);
ops =sdpsettings('solver','bmibnb');
sol = optimize([0 <= [x] <= 5, -5 <= y <= 5, x==.1], sum(sum((x.^y-10).^2)),ops)

testCase.assertTrue(sol.problem==0)
testCase.assertTrue(norm(value(y, sol)-[-1;-1]) <= 1e-3)