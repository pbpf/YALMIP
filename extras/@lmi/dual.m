function sys = dual(X,sol)
%DUAL Extract dual variable
%
%   Z = DUAL(F,sol)  Returns the dual variable for the constraint F,
%                    with sol = optimize(Fc,obj)
%
%   See also OPTIMIZE

% The stateless refactoring removed the global "last solution": the
% solution struct returned by OPTIMIZE must be passed explicitly.
if nargin < 2
    error('YALMIP:sessionRequired','Since the stateless refactoring, pass the solution: z = dual(F, sol), where sol = optimize(Fc,obj).')
end

X = flatten(X);
nlmi = length(X.LMIid);

% Is it an empty SET
if (nlmi == 0)
    sys = [];
    return
end

if nlmi>1
    if ~(all(is(X,'elementwise')) || all(is(X,'equality')))
        error('Dual not applicable on list of constraints. Use dual(F(index),sol) or dual(F(''tag''),sol)')
    end
end

% Get dual from solution payload
sys = [];
for i = 1:length(X.LMIid)
    thisdual = [];
    if isfield(sol,'eval') && isfield(sol.eval,'duals_index') && ~isempty(sol.eval.duals_index)
        index_to_dual = find(sol.eval.duals_index==X.LMIid(i));
        if ~isempty(index_to_dual)
            thisdual = sol.eval.duals_data{index_to_dual};
        end
    end
    sys = [sys;thisdual];
end

% If no dual available, returns NaNs with correct dimension
if isempty(sys)
    sys = real(double(value(X,sol)))+NaN;
end
