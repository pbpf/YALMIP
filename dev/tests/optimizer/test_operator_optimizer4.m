function tests = test_operator_optimizer4
tests = functiontests(localfunctions);

function test1(testCase)
S = yalmip.Session();
x = S.sdpvar(1,1);
y = S.sdpvar(1,1);
u = S.sdpvar(1,1);
z = S.sdpvar(1,1);
P = optimizer([x <= u,y <= z], -x-y,[],[u;z],[x;y]);
sol = optimize([],(P{[u;z]}-[7;2])'*(P{[u;z]}-[7;2]));
testCase.assertTrue(sol.problem == 0)

function test2(testCase)
S = yalmip.Session();
x = S.sdpvar(1,1);
y = S.sdpvar(1,1);
u = S.sdpvar(1,1);
z = S.sdpvar(1,1);
P = optimizer([x <= u,y <= z], -x-y,[],[u;z],[x;y]);
sol = optimize([],(P{1+[u;z]}-[7;2])'*(P{1+[u;z]}-[7;2]));
testCase.assertTrue(sol.problem == 0)