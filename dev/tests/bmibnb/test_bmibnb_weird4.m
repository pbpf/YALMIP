function tests = test_bmibnb_weird4
tests = functiontests(localfunctions);

function test1(testCase)
S = yalmip.Session();

% Issue #188
x = S.sdpvar(1,1);
y = S.sdpvar(1,1);
p = sin(1+y*x)^2+cos(y*x);
z = S.sdpvar(1,1);
w = S.sdpvar(1,1);
sol = optimize([-1 <= [x y z w] <= 1, p <= 3],p,sdpsettings('solver','bmibnb'));

testCase.assertTrue(sol.problem == 0)
testCase.assertTrue(abs(value(p, sol)-.5403) <= 1e-2) 