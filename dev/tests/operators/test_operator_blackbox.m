function tests = test_operator_blackbox
tests = functiontests(localfunctions);

function test_base(testCase)
S = yalmip.Session();

x = S.sdpvar(1,1);
sol = struct('eval',struct('variables',[],'optvar',[],'values',[]));
sol = assign(x,0.1, sol);
ops = sdpsettings('debug',1,'fmincon.algorithm','sqp','usex0',1);
sol = optimize(blackbox(x,@(x)mytestOLD(x,1)) >= 0,x,ops)
testCase.assertTrue(sol.problem == 0);

x = S.sdpvar(1,1);
obj = blackbox(x,@(x)(sin(10*x)+abs(sin(x))+x));
sol=optimize((integer(x)) + (-pi <= x <= pi),obj,sdpsettings('solver','bmibnb'));
testCase.assertTrue(sol.problem == 0);


function test_absmax(testCase)
S = yalmip.Session();
n = 3;
c = randn(3*n,1);
A = randn(10*n,3*n);
b = rand(10*n,1)+1;
x = S.sdpvar(2*n,1);
Domain = [0 <= x <= 1];
for i = 1:n        
    Bounds = @(L,U)[~(L<0 & U>0)*min(abs(L),abs(U)) max(abs(L),abs(U))];
    f = blackbox(x(i)-x(i+n),@abs,'convex','bounds',Bounds);
    z = (x(i)+x(i+n)+f)/2;
    x = [x;z];
end
sol = optimize([Domain, A*x <= b], c'*x,sdpsettings('solver','bmibnb','debug',1));
testCase.assertTrue(sol.problem == 0);


function test_sort(testCase)
S = yalmip.Session();

% Just some data that runs
n = 3;
m = 10;
w = S.sdpvar(n,1);
p = (m:-1:1)'/10;
R = reshape(1:m*n,m,n);
w0 = (1:n)';
f = @(w)(sort(R*w,'descend')'*p);
objective = blackbox(w,f)+norm(w-w0,1);
ops = sdpsettings('solver','fmincon','fmincon.algorithm','active-set');
Model = [norm(w,inf)<=1];    
sol = optimize(Model,objective,ops);
testCase.assertTrue(sol.problem == 0);




