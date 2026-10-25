function tests = test_sdpvar_quaddecomp
tests = functiontests(localfunctions);

function test1(testCase)
S = yalmip.Session();
a = S.sdpvar(1,1);
b = S.sdpvar(1,1);
p = 2*b^2+a^2;

[Q,c,f,dummy,nonquadratic] = vecquaddecomp(p,[a b]);
testCase.assertTrue(norm(full(Q{1})-[1 0;0 2])<1e-10);

a = S.sdpvar(1,1);
b = S.sdpvar(1,1);
p = 2*b^2+a^2+3*a*b;
[Q,c,f,dummy,nonquadratic] = vecquaddecomp(p,[a b]);
testCase.assertTrue(norm(full(Q{1})-[1 1.5;1.5 2])<1e-10);

a = S.sdpvar(1,1);
b = S.sdpvar(1,1);
p = 2*b^2+3*a*b+a^2;
[Q,c,f,dummy,nonquadratic] = vecquaddecomp(p,[a b]);
testCase.assertTrue(norm(full(Q{1})-[1 1.5;1.5 2])<1e-10);

a = S.sdpvar(1,1);
b = S.sdpvar(1,1);
p = 3*a*b+a^2+2*b^2+b(1);
[Q,c,f,dummy,nonquadratic] = vecquaddecomp(p,[a b]);
testCase.assertTrue(norm(full(Q{1})-[1 1.5;1.5 2])<1e-10);
testCase.assertTrue(norm(full(c{1}-[0;1]))<1e-10);


