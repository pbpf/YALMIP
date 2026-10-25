function tests = test_operator_entropy
tests = functiontests(localfunctions);

function test1(testCase)
S = yalmip.Session();
x = S.sdpvar(2,1);
sol = struct('eval',struct('variables',[],'optvar',[],'values',[]));
sol = assign(x,1, sol);
sol = optimize((x >= 0.1),-entropy(x),sdpsettings('solver','fmincon'));

testCase.assertTrue(sol.problem == 0);
testCase.assertTrue(abs(value(sum(x), sol)-0.73) <= 1e-2);
testCase.assertTrue(abs(-entropy(value(x, sol))--0.7357588) <= 1e-3);

function test2(testCase)
S = yalmip.Session();
x1 = S.sdpvar(1,1);
y = S.sdpvar(1,1);
x2 = S.sdpvar(1,1);
x = [x1;x2];
sol = optimize(([x;y] >= 0.1),-entropy(x)+y,sdpsettings('solver','fmincon'));

testCase.assertTrue(sol.problem == 0);
testCase.assertTrue(abs(value(sum(x), sol)-0.73) <= 1e-2);

