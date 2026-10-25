function tests = test_robust_10
tests = functiontests(localfunctions);

function test1(testCase)
S = yalmip.Session();
% Test of Bertsime-Sim D-norm

testCase.assertTrue(true)
return
p = 1.5;
a = randn(2,1);

% Analytic value
o1 = max(norm(a,inf),norm(a,1)/p);

% Robust optimization over explicitly reduced model
w = S.sdpvar(2,1);
t = S.sdpvar(1,1);
W1 = [norm(w,1)<=1];
W2 = [norm(w,inf)<=1/p];
H = hull(W1,W2);
% Avoid MPT
%W = projection(H,w);
W = [-0.894427190999917  -0.447213595499956   0.894427200730095
  -0.894427190999916   0.447213595499957   0.894427189632882
  -0.447213595499957   0.894427190999916   0.894427175418485
  -0.447213595499957  -0.894427190999916   0.894427197612909
   0.447213595499958   0.894427190999916   0.894427160069838
   0.447213595499957  -0.894427190999916   0.894427182264263
   0.894427190999916   0.447213595499958   0.894427158935590
   0.894427190999916  -0.447213595499958   0.8944271700328029]*[1;-w]<=0
sol = optimize([uncertain(w),W,a'*w<=t],t);
o2 = value(t, sol);

% Robust optimization over original model
% FAILS, issues #123
if 0
w = S.sdpvar(2,1);
t = S.sdpvar(1,1);
W1 = [norm(w,1)<=1];
W2 = [norm(w,inf)<=1/p];
[H,tt,y] = hull(W1,W2);
optsol = optimize([uncertain(w),H,a'*w<=t],t,sdpsettings('verbose',0));
o3 = value(t, optsol);
testCase.assertTrue(abs(o1-o3) <= 1e-4);


% Robust optimization over original model
w = S.sdpvar(2,1);
t = S.sdpvar(1,1);
W1 = [norm(w,1)<=1];
W2 = [norm(w,inf)<=1/p];
optsol2 = optimize([uncertain(w),[W1,W2],a'*w<=t],t,sdpsettings('verbose',0,'robust.lplp','enumeration'));

o3 = value(t, optsol2);
testCase.assertTrue(abs(o1-o3) <= 1e-4);
end


