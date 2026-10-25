function tests = test_operator_abs
tests = functiontests(localfunctions);

function test1(testCase)
S = yalmip.Session();

x = S.sdpvar(1,1);
y = S.sdpvar(1,1);
obj = abs(1+abs(x-5));
sol = optimize([],obj)

testCase.assertTrue(sol.problem == 0)
testCase.assertTrue(abs(value(obj, sol) - 1) <= 1e-4);

function test2(testCase)
S = yalmip.Session();
x = S.sdpvar(1,1);
y = S.sdpvar(1,1);
F = (abs(1+abs(x-5)) + abs(y)<=10) 
obj = -x
sol = optimize(F,obj)
testCase.assertTrue(abs(value(obj, sol)--14) <= 1e-4);

function test3(testCase)
S = yalmip.Session();
x = S.sdpvar(1,1);
sol = optimize([-2 <= x <= 1],x*abs(x),sdpsettings('solver','bmibnb'))
testCase.assertTrue(sol.problem == 0)
testCase.assertTrue(abs(value(x, sol)--2) <= 1e-4);
