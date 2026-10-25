function tests = test_robust_5
tests = functiontests(localfunctions);

function test1(testCase)
S = yalmip.Session();
% Test the duality filter, in particular derivation of c,B,A

x = S.sdpvar(3,1);
w = S.sdpvar(2,1);
A = magic(10);
E = A(:,1:2);
A = A(:,2:4);

sol = optimize([uncertain(w),-1<=w<=1,sum(w)<=1.5,(A+E*w*ones(1,3))*x <= 10],sum(x),sdpsettings('robust.lplp','duality','verbose',0));
testCase.assertTrue(abs(value(sum(x), sol)--0.16868) <=  1e-3);
testCase.assertTrue(sol.problem == 0);

sol = optimize([uncertain(w),-1<=w<=1,sum(w)<=1.5,(A+E*w*ones(1,3))*x <= 10],sum(x),sdpsettings('robust.lplp','','verbose',0));
testCase.assertTrue(abs(value(sum(x), sol)--0.16868) <=  1e-3);
testCase.assertTrue(sol.problem == 0);


