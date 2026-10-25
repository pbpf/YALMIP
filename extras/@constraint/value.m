function x = value(x, solution)
%VALUE (Overloaded) Evaluate a constraint object given a solution payload

if nargin < 2
    error('YALMIP:sessionRequired',['Since the stateless refactoring, pass the solution: value(F, sol), where sol = optimize(F,obj).'])
end

x = value(x.Evaluated{1}, solution);

if isessentiallysymmetric(x)
    x = min(eig(x)) >= 0;
else
    x = min(x(:)) >= 0;
end
