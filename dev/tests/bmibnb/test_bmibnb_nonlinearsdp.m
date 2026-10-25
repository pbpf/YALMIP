function tests = test_global_bmibnb_gamscontrol1
tests = functiontests(localfunctions);

function test1(testCase)
S = yalmip.Session();

A = [1 2;-3 0];B = [1;1];
[K0,P0] = lqr(A,B,eye(2),1);
sol = struct('eval',struct('variables',[],'optvar',[],'values',[]));
P = S.sdpvar(2,2);sol = assign(P,2*P0, sol);K0(K0>1)=1;K0(K0<-1)=-1;
K = S.sdpvar(1,2);sol = assign(K,-K0, sol);
F = (K<=1)+(K>=-1)+(P>=0)+((A+B*K)'*P+P*(A+B*K) <= -eye(2)-K'*K);
F = F+(diag(P)>=0)+(P(:)>=-151) + (P(:)<=150) + (P>=P0)+(K>=-100) + (K<=100);

obj = trace(P);

sol = optimize(F,obj,sdpsettings('solver','bmibnb','bmibnb.uppersolver','none'))

testCase.assertTrue(sol.problem == 0)
testCase.assertTrue(abs(value(obj, sol)-5.4615) <=  2e-1)

function test2(testCase)
S = yalmip.Session();

A = [1 2;-3 0];B = [1;1];
[K0,P0] = lqr(A,B,eye(2),1);
sol = struct('eval',struct('variables',[],'optvar',[],'values',[]));
P = S.sdpvar(2,2);sol = assign(P,2*P0, sol);K0(K0>1)=1;K0(K0<-1)=-1;
K = S.sdpvar(1,2);sol = assign(K,-K0, sol);
F = (K<=1)+(K>=-1)+(P>=0)+((A+B*K)'*P+P*(A+B*K) <= -eye(2)-K'*K);
F = F+(diag(P)>=0)+(P(:)>=-151) + (P(:)<=150) + (P>=P0)+(K>=-100) + (K<=100);

obj = trace(P);

sol = optimize(F,obj,sdpsettings('solver','bmibnb','bmibnb.uppersolver','fmincon'))
testCase.assertTrue(sol.problem == 0)
testCase.assertTrue(abs(value(obj, sol)-5.4615) <=  2e-2)

sol = optimize(F,obj,sdpsettings('solver','bmibnb','bmibnb.uppersolver','fmincon','bmibnb.uppersdprelax',0))
testCase.assertTrue(sol.problem == 0)
testCase.assertTrue(abs(value(obj, sol)-5.4615) <=  2e-2)

sol = optimize(F,obj,sdpsettings('solver','bmibnb','bmibnb.uppersolver','fmincon','bmibnb.uppersdprelax',1))
testCase.assertTrue(sol.problem == 0)
testCase.assertTrue(abs(value(obj, sol)-5.4615) <=  2e-2)
