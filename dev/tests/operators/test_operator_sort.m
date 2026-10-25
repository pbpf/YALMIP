function tests = test_operator_sort
tests = functiontests(localfunctions);

function test1(testCase)
S = yalmip.Session();
x = S.sdpvar(4,1);
z = S.sdpvar(4,1);
[y,loc] = sort(x);
w = randn(4,1);
sol = optimize((-100 <= x <= 100)+(z == y),norm(x-w,1));
testCase.assertTrue(sol.problem == 0);
testCase.assertTrue(norm(sort(w)-value(z, sol)) <= 1e-4);

A = ones(20,5);
b = (1:20)';
x = S.sdpvar(5,1);
e = b-A*x;
F = (mean(x) == median(x)) + (-100 <= x <= 100);
sol = optimize(F,norm(e,1));
testCase.assertTrue(sol.problem == 0);
testCase.assertTrue(abs(mean(value(x, sol))-median(value(x, sol)))<1e-4);
testCase.assertTrue(abs(norm(value(e, sol),1)-100)<1e-4);
