function sys = value(X,sol)
%VALUE Overloaded: evaluates a constraint expression given a solution

% The stateless refactoring removed the global "last solution": the
% solution struct returned by OPTIMIZE must be passed explicitly.
if nargin < 2
    error('YALMIP:sessionRequired','Since the stateless refactoring, pass the solution: v = value(F, sol), where sol = optimize(Fc,obj).')
end

X = flatten(X);
nlmi = length(X.LMIid);

if (nlmi == 0)
 sys = NaN;
 return
end

if nlmi>1
 error('Value not applicable on list of constraints')
end

sys = value(X.clauses{1}.data,sol);
