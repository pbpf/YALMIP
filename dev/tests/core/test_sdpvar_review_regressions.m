function tests = test_sdpvar_review_regressions
tests = functiontests(localfunctions);

function test_prod_dimensions(testCase)
S = yalmip.Session();
for shape = {[3 1],[1 3],[2 3]}
    dims = shape{1};
    x = S.sdpvar(dims(1),dims(2),'full');
    z = reshape(1:prod(dims),dims);
    sol = struct('eval',struct('variables',[],'optvar',[],'values',[]));
    sol = assign(x,z, sol);
    testCase.verifyEqual(value(prod(x), sol),prod(z));
    for dim = 1:3
        testCase.verifyEqual(value(prod(x,dim), sol),prod(z,dim));
    end
end

function test_prod_zero(testCase)
S = yalmip.Session();
x = S.sdpvar(1);
sol = struct('eval',struct('variables',[],'optvar',[],'values',[]));
testCase.verifyEqual(value(prod([x;0]), sol),0);
testCase.verifyEqual(value(prod([0 x]), sol),0);
sol = assign(x,2, sol);
testCase.verifyEqual(value(prod([x 0;x x]), sol),[4 0]);

function test_median_two(testCase)
S = yalmip.Session();
x = S.sdpvar(2,1);
sol = struct('eval',struct('variables',[],'optvar',[],'values',[]));
sol = assign(x,[2;4], sol);
testCase.verifyEqual(value(median(x), sol),3);
testCase.verifyEqual(value(median(x'), sol),3);

function test_sort_descending(testCase)
S = yalmip.Session();
for z = {[1 10;2 20],[1 3 2],[1;3;2]}
    a = z{1};
    x = S.sdpvar(size(a,1),size(a,2),'full');
    sol = struct('eval',struct('variables',[],'optvar',[],'values',[]));
    sol = assign(x,a, sol);
    [y,loc] = sort(x,'descend');
    [expected,indices] = sort(a,'descend');
    testCase.verifyEqual(value(y, sol),expected);
    testCase.verifyEqual(value(loc, sol),indices);
    testCase.verifyEqual(value(sort(x,'descend'), sol),expected);
end

function test_trapz_matrix(testCase)
S = yalmip.Session();
x = S.sdpvar(3,2,'full');
z = [1 3;2 4;7 8];
sol = struct('eval',struct('variables',[],'optvar',[],'values',[]));
sol = assign(x,z, sol);
testCase.verifyEqual(value(trapz(x), sol),trapz(z));

function test_cumtrapz_scalar(testCase)
S = yalmip.Session();
x = S.sdpvar(1);
sol = struct('eval',struct('variables',[],'optvar',[],'values',[]));
sol = assign(x,2, sol);
testCase.verifyEqual(value(cumtrapz(x), sol),0);
testCase.verifyEqual(value(cumtrapz(3+x), sol),0);

function test_cumsum_scalar_and_dimensions(testCase)
S = yalmip.Session();
x = S.sdpvar(1);
sol = struct('eval',struct('variables',[],'optvar',[],'values',[]));
sol = assign(x,3, sol);
testCase.verifyEqual(value(cumsum(2+x), sol),5);
y = S.sdpvar(3,2,'full');
z = [1 2;3 4;5 6];
sol = assign(y,z, sol);
for dim = 1:4
    testCase.verifyEqual(value(cumsum(y,dim), sol),cumsum(z,dim));
end

function test_mrdivide_rectangular(testCase)
S = yalmip.Session();
x = S.sdpvar(2,3,'full');
z = [1 2 3;4 5 6];
sol = struct('eval',struct('variables',[],'optvar',[],'values',[]));
sol = assign(x,z, sol);
for divisor = {[1 0 0;0 1 0],[eye(3);1 1 1]}
    b = divisor{1};
    testCase.verifyEqual(value(x/b, sol),z/b,'AbsTol',1e-12);
end

function test_mrdivide_infinity(testCase)
S = yalmip.Session();
x = S.sdpvar(2,3,'full');
testCase.verifyEqual(x/Inf,zeros(2,3));
testCase.verifyEqual(x/(-Inf),zeros(2,3));

function test_fft_shapes_and_lengths(testCase)
S = yalmip.Session();
x = S.sdpvar(3,1);
z = [1;2;4];
sol = struct('eval',struct('variables',[],'optvar',[],'values',[]));
sol = assign(x,z, sol);
for row = 0:1
    if row
        a = x.'; b = z.';
    else
        a = x; b = z;
    end
    testCase.verifyEqual(value(fft(a), sol),fft(b),'AbsTol',1e-12);
    for n = [0 1 2 3 5]
        testCase.verifyEqual(value(fft(a,n), sol),fft(b,n),'AbsTol',1e-12);
    end
end

function test_jacobian_explicit_order(testCase)
S = yalmip.Session();
x = S.sdpvar(3,1);
f = x(1)^2+2*x(2)^2+3*x(3)^2;
sol = struct('eval',struct('variables',[],'optvar',[],'values',[]));
sol = assign(x,[1;2;3], sol);
orders = perms(1:3);
for i = 1:size(orders,1)
    order = orders(i,:);
    expected = [2 8 18];
    testCase.verifyEqual(value(jacobian(f,x(order),1), sol),expected(order));
    testCase.verifyEqual(value(jacobian(f,x(order)), sol),expected(order));
    testCase.verifyEqual(value(jacobian([f;2*f],x(order),1), sol),[expected(order);2*expected(order)]);
end
