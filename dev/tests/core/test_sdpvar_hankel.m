function tests = test_sdpvar_hankel
tests = functiontests(localfunctions);

function test1(testCase)
S = yalmip.Session();

c = S.sdpvar(4,1);
sol = struct('eval',struct('variables',[],'optvar',[],'values',[]));
sol = assign(c,[2 4 6 8]', sol);
ok = all(all(value(hankel(c,c), sol)-hankel(value(c, sol),value(c, sol)) == 0));
testCase.assertTrue(ok)

ok = all(all(value(hankel(c), sol)-hankel(value(c, sol)) == 0));
testCase.assertTrue(ok)

r = S.sdpvar(4,1);
sol = assign(r,-[2 4 6 8]', sol);
ok = all(all(value(hankel(c,r), sol)-hankel(value(c, sol),value(r, sol)) == 0));
testCase.assertTrue(ok)

c = S.sdpvar(4,1);
sol = assign(c,[2 4 6 8]', sol);
r = S.sdpvar(2,1);
sol = assign(r,-[2 4]', sol);
ok = all(all(value(hankel(c,r), sol)-hankel(value(c, sol),value(r, sol)) == 0));
testCase.assertTrue(ok)

ok = all(all(value(hankel(r,c'), sol)-hankel(value(r, sol),value(c', sol)) == 0));
testCase.assertTrue(ok)

c = S.sdpvar(2,3);
r = S.sdpvar(4,1);
sol = assign(c,[1 2 3;4 5 6], sol);
sol = assign(r,[1 2 3 4]', sol);
ok = all(all(value(hankel(c,r), sol)-hankel(value(c, sol),value(r, sol))==0));
testCase.assertTrue(ok)

c = S.sdpvar(2,3);
r = S.sdpvar(4,1);
sol = assign(c,[1 2 3;4 5 6], sol);
sol = assign(r,[1 2 3 4]', sol);
ok = all(all(value(hankel(r,c), sol)-hankel(value(r, sol),value(c, sol))==0));
testCase.assertTrue(ok)

c = S.sdpvar(4,1,'full','complex');
sol = assign(c,[2 4 6 8]'+sqrt(-1)*[5 4 3 2]', sol);
ok = all(all(value(hankel(c,c), sol)-hankel(value(c, sol),value(c, sol)) == 0));
testCase.assertTrue(ok)

ok = all(all(value(hankel(c), sol)-hankel(value(c, sol)) == 0));
testCase.assertTrue(ok)

c = S.sdpvar(4,1,'full','complex');
sol = assign(c,[2 4 6 8]'+sqrt(-1)*[5 4 3 2]', sol);
r = S.sdpvar(4,1);
sol = assign(r,-[2 4 6 8]', sol);
ok = all(all(value(hankel(c,r), sol)-hankel(value(c, sol),value(r, sol)) == 0));
testCase.assertTrue(ok)

r = S.sdpvar(2,1);
sol = assign(r,-[2 4]'+sqrt(-1), sol);
ok = all(all(value(hankel(c,r), sol)-hankel(value(c, sol),value(r, sol)) == 0));
testCase.assertTrue(ok)

ok = all(all(value(hankel(r,c'), sol)-hankel(value(r, sol),value(c', sol)) == 0));
testCase.assertTrue(ok)

c = S.sdpvar(2,3);
r = S.sdpvar(4,1);
sol = assign(c,[1 2 3;4 5 6], sol);
sol = assign(r,[1 2 3 4]'*sqrt(-1), sol);
ok = all(all(value(hankel(c,r), sol)-hankel(value(c, sol),value(r, sol))==0));
testCase.assertTrue(ok)

c = S.sdpvar(2,3);
r = S.sdpvar(4,1);
sol = assign(c,[1 2 3;4 5 6]*sqrt(-1), sol);
sol = assign(r,[1 2 3 4]', sol);
ok = all(all(value(hankel(r,c), sol)-hankel(value(r, sol),value(c, sol))==0));
testCase.assertTrue(ok)