function tests = test_bmibnb_probing
tests = functiontests(localfunctions);

function test_quadratic(testCase)
S = yalmip.Session();
x = S.sdpvar(1,1);
y = S.sdpvar(1,1);
d1 = S.binvar(1,1);
d2 = S.binvar(1,1);
d3 = S.binvar(1,1);
d4 = S.binvar(1,1);

M1 = [y == -x^2, -10 <= x <= -2];
M2 = [y == x^2, -2 <= x <= 0];
M3 = [y == x^2, 0 <= x <= 3];
M4 = [y == -x^2, 3 <= x <= 10];

Model = [-10 <= x <= 10,-100 <= y <= 100,
        implies(d1,M1)
        implies(d2,M2)
        implies(d3,M3)
        implies(d4,M4)
        d1+d2+d3+d4 == 1];
        
sol = optimize(Model,-y,sdpsettings('solver','bmibnb','savesolveroutput',1));
testCase.assertTrue(sol.problem == 0);
testCase.assertTrue(sol.solveroutput.nodes == 1);
testCase.assertTrue(abs(value(y, sol)-9) <= 1e-2);