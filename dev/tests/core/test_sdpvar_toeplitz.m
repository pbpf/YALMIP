function tests = test_sdpvar_toeplitz
tests = functiontests(localfunctions);

function test1(testCase)
S = yalmip.Session();
c = S.sdpvar(4,1);
sol = struct('eval',struct('variables',[],'optvar',[],'values',[]));
sol = assign(c,[2 4 6 8]', sol);
ok = all(all(value(toeplitz(c,c), sol)-toeplitz(value(c, sol),value(c, sol)) == 0));
testCase.assertTrue(ok)

ok = all(all(value(toeplitz(c), sol)-toeplitz(value(c, sol)) == 0));
testCase.assertTrue(ok)

r = S.sdpvar(4,1);
sol = assign(r,-[2 4 6 8]', sol);
ok = all(all(value(toeplitz(c,r), sol)-toeplitz(value(c, sol),value(r, sol)) == 0));
testCase.assertTrue(ok)

c = S.sdpvar(4,1);
sol = assign(c,[2 4 6 8]', sol);
r = S.sdpvar(2,1);
sol = assign(r,-[2 4]', sol);
ok = all(all(value(toeplitz(c,r), sol)-toeplitz(value(c, sol),value(r, sol)) == 0));
testCase.assertTrue(ok)

ok = all(all(value(toeplitz(r,c'), sol)-toeplitz(value(r, sol),value(c', sol)) == 0));
testCase.assertTrue(ok)

if 0
    % This case is not well-defined. Gives different answers in different
    % versions
    c = S.sdpvar(2,3);
    r = S.sdpvar(4,1);
    sol = assign(c,[1 2 3;4 5 6], sol);
    sol = assign(r,[1 2 3 4]', sol);
    ok = all(all(value(toeplitz(c,r), sol)-toeplitz(value(c, sol),value(r, sol))==0));
    testCase.assertTrue(ok)
end

c = S.sdpvar(2,3);
r = S.sdpvar(4,1);
sol = assign(c,[1 2 3;4 5 6], sol);
sol = assign(r,[1 2 3 4]', sol);
ok = all(all(value(toeplitz(r,c), sol)-toeplitz(value(r, sol),value(c, sol))==0));
testCase.assertTrue(ok)

c = S.sdpvar(4,1,'full','complex');
sol = assign(c,[2 4 6 8]'+sqrt(-1)*[5 4 3 2]', sol);
ok = all(all(value(toeplitz(c,c), sol)-toeplitz(value(c, sol),value(c, sol)) == 0));
testCase.assertTrue(ok)

ok = all(all(value(toeplitz(c), sol)-toeplitz(value(c, sol)) == 0));
testCase.assertTrue(ok)

c = S.sdpvar(4,1,'full','complex');
sol = assign(c,[2 4 6 8]'+sqrt(-1)*[5 4 3 2]', sol);
r = S.sdpvar(4,1);
sol = assign(r,-[2 4 6 8]', sol);
ok = all(all(value(toeplitz(c,r), sol)-toeplitz(value(c, sol),value(r, sol)) == 0));
testCase.assertTrue(ok)

r = S.sdpvar(2,1);
sol = assign(r,-[2 4]'+sqrt(-1), sol);
ok = all(all(value(toeplitz(c,r), sol)-toeplitz(value(c, sol),value(r, sol)) == 0));
testCase.assertTrue(ok)

ok = all(all(value(toeplitz(r,c'), sol)-toeplitz(value(r, sol),value(c', sol)) == 0));
testCase.assertTrue(ok)

if 0
    % This case is not well-defined. Gives different answers in different
    % versions
    c = S.sdpvar(2,3);
    r = S.sdpvar(4,1);
    sol = assign(c,[1 2 3;4 5 6], sol);
    sol = assign(r,[1 2 3 4]'*sqrt(-1), sol);
    ok = all(all(value(toeplitz(c,r), sol)-toeplitz(value(c, sol),value(r, sol))==0));
    testCase.assertTrue(ok)
end

c = S.sdpvar(2,3);
r = S.sdpvar(4,1);
sol = assign(c,[1 2 3;4 5 6]*sqrt(-1), sol);
sol = assign(r,[1 2 3 4]', sol);
ok = all(all(value(toeplitz(r,c), sol)-toeplitz(value(r, sol),value(c, sol))==0));
testCase.assertTrue(ok)



