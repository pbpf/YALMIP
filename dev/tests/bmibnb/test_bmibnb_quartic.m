function tests = test_global_bmibnb_quartic
tests = functiontests(localfunctions);

function test1(testCase)
S = yalmip.Session();

x = S.sdpvar(1,1);
y = S.sdpvar(1,1);
F = (x^3+y^5 <= 5) + (y >= 0);
F = F + (-100 <= [x y] <= 100) % Always bounded domain
obj = -x;

sol = optimize(F,obj,sdpsettings('solver','bmibnb'))

testCase.assertTrue(abs(value(obj, sol)--1.71) <= 1e-4)