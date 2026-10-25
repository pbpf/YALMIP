function x = double(x,sol);
%DOUBLE (Overloaded) evaluates constraint satisfaction given a solution

% The stateless refactoring removed the global "last solution": the
% solution struct returned by OPTIMIZE must be passed explicitly.
if nargin < 2
    error('YALMIP:sessionRequired','Since the stateless refactoring, pass the solution: sat = double(F, sol), where sol = optimize(Fc,obj).')
end

x = double(value(x.Evaluated{1},sol));

if isessentiallyhermitian(x)
    x = min(eig(x)) >= 0;
else
    x = min(x(:)) >= 0;
end
