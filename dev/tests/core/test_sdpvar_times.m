function tests = test_sdpvar_times
tests = functiontests(localfunctions);

function test1(testCase)
S = yalmip.Session();
x = S.sdpvar(1,1);
y = S.sdpvar(1,1);
testCase.assertTrue(isequal(value(isequal([x*x x*x;x*x x*x]-x.*[x x;x x],zeros(2))),1))
testCase.assertTrue(isequal(value(isequal([x*x x*x;x*x x*x]-[x x;x x].*x,zeros(2))),1))
testCase.assertTrue(isequal(value(isequal([x*y x*y;x*y x*y]-[x x;x x].*y,zeros(2))),1))
testCase.assertTrue(isequal(value(isequal([x*y x*y;x*y x*y]-y.*[x x;x x],zeros(2))),1))

x = S.sdpvar(2,1,'full','complex');
w = randn(2,1) + sqrt(-1)*randn(2,1);
v = randn(2,1) + sqrt(-1)*randn(2,1);
sol = struct('eval',struct('variables',[],'optvar',[],'values',[]));
sol = assign(x,w, sol);
testCase.assertTrue(all(value(w.*v - x.*v, sol) <= 1e-12))