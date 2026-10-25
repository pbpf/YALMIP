function tests = test_sos_book
tests = functiontests(localfunctions);

function test1(testCase)
S = yalmip.Session();

k=2;
mu = S.sdpvar(1,1);
x = S.sdpvar(1,1);
y = S.sdpvar(1,1);
[h,c]=polynomial([x y],2*k-4);
g=y^2*(1-x^2)-(x^2+2*y-1)^2;
F=sos(y+mu-h*g);
sol = solvesos(F,mu,sdpsettings('verbose',0),[mu;c]);

testCase.assertTrue(sol.problem == 0);
testCase.assertTrue(abs(value(mu, sol) - 0.17759) <= 1e-3);

k=4;
x = S.sdpvar(1,1);
y = S.sdpvar(1,1);
[h,c]=polynomial([x y],2*k-4);
g=y^2*(1-x^2)-(x^2+2*y-1)^2;
F=sos(y+mu-h*g);
sol = solvesos(F,mu,sdpsettings('verbose',0),[mu;c]);
testCase.assertTrue(sol.problem == 0);
testCase.assertTrue(abs(value(mu, sol) - 0.0161) <= 1e-3)

x = S.sdpvar(1,1);
y = S.sdpvar(1,1);
lambda = S.sdpvar(1,1);
f=x^4+y^4+2*x^2*y^2-x^2+y^2;
l=1/sqrt(8)-y;
F=sos(l+lambda*f);
sol = solvesos(F,0,sdpsettings('verbose',1,'sos.model',2),lambda);

testCase.assertTrue(sol.problem==0)
testCase.assertTrue(length(sosd(F))==6)

y1 = S.sdpvar(1,1);
y2 = S.sdpvar(1,1);
y3 = S.sdpvar(1,1);
M=[1 y1 y2;
y1 y2 y3;
y2 y3 y3+y2-y1];
sol = optimize(M>=0,y1,sdpsettings('verbose',0));
testCase.assertTrue(sol.problem==0);
sol = optimize(M>=0,-y1,sdpsettings('verbose',0));
testCase.assertTrue(sol.problem==0);
