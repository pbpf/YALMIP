function plin = linearize(p, sol)
% LINEARIZE Linearize SDPVAR object at a solution
%
% h = LINEARIZE(p, sol)
%
% Returns linearization p(value(x)) + dp(value(x))*(x-value(x))
% where x is the SDPVAR variables defining the polynomial p(x), and the
% values are taken from the solution payload sol (stateless refactor).
%
% See also SDPVAR, JACOBIAN, VALUE

if isa(p,'double')
    plin = zeros(size(p));
    return
end

if is(p,'linear') & ~is(p,'compound')
    plin = p;
    return
end

x = recover(depends(p), sessOf(p));
x0 = value(x, sol);
p0 = value(p, sol);

n = size(p,1);
m = size(p,2);

if ~isfield(p.extra, 'jacobian') || isempty(p.extra.jacobian)
    p.extra.jacobian = jacobian(p,x);
end
J = value(p.extra.jacobian, sol);

if min(n,m)>1
    plin = [];
    for i = 1:m
        plin = [plin p0(:,i)+squeeze(J(:,i,:))*(x-x0)];
    end
else
    plin = p0+value(J, sol)*(x-x0);
end