function tests = test_operator_optimizer16
tests = functiontests(localfunctions);

function test1(testCase)
S = yalmip.Session();

x = S.sdpvar(1,1);
y = S.sdpvar(1,1);
a = S.sdpvar(1,1);
t = S.sdpvar(1,1);
p = x^4+(x-a)^2 + a^2;
[F,objective] = compilesos(sos(p-t),-t,sdpsettings('sos.model',2),[t;a]);
P = optimizer(F,objective,sdpsettings('solver','sedumi,mosek'),a,t);
s1 = P{2};

a = 2;
p = x^4+(x-a)^2 + a^2;
sol = solvesos(sos(p-t),-t)
s2 = value(t, sol);
testCase.assertTrue(abs(s1-s2) <= 1e-4);

x = S.sdpvar(1,1);
a = S.sdpvar(1,1);
t = S.sdpvar(1,1);
p = x^4+(x-a)^2 + a^2;
P = optimizer(sos(p-t),-t,sdpsettings('solver','sedumi,mosek'),a,t);
s3 = P{2};
testCase.assertTrue(abs(s1-s3) <= 1e-4);
