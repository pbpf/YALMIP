function tests = test_bmibnb_weird5
tests = functiontests(localfunctions);

function test1(testCase)
S = yalmip.Session();

% Issue #187
x = S.sdpvar(1,1);
y = S.sdpvar(1,1);
p = sin(1+y)^2+cos(y*x);
sol = optimize([-1 <= [x y] <= 1, p <= 3],p,sdpsettings('solver','bmibnb'));
testCase.assertTrue(sol.problem == 0)
testCase.assertTrue(abs(value(p, sol)-.5403) <= 1e-2) 