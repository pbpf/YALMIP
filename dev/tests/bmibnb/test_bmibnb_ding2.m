function tests = test_global_bmibnb_ding2
tests = functiontests(localfunctions);

function test1(testCase)
S = yalmip.Session();
%J Glob Optim (2007) 38:421�436
%DOI 10.1007/s10898-006-9091-3
%ORIGINAL ARTICLE
%Accelerating convergence of cutting plane algorithms
%for disjoint bilinear programming
x = S.sdpvar(4,1);
y = S.sdpvar(4,1);
C = [-3 1 0 1;1 -4 2 0;0 2 -4 1;1 0 1 -3];
A1 = [1 2 3 4;2 3 4 1;3 4 1 2;4 1 2 3];
A2 = A1;
b1 = [10;10;10;10];
b2 = b1;
obj = x'*C*y;
F = [x>=0,y>=0,A1*x==b1,A2*y==b2];
sol = optimize(F,obj,sdpsettings('solver','bmibnb'));
testCase.assertTrue(sol.problem==0)
testCase.assertTrue(abs(value(obj, sol)--4) <= 1e-4)