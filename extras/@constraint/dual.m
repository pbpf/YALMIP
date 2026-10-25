function sys = dual(X,sol)
%DUAL Extract dual variable
%
%   Z = DUAL(F,sol)  Returns the dual variable for the constraint F,
%                    with sol = optimize(Fc,obj)
%
%   See also OPTIMIZE, DUALIZE

if nargin < 2
    error('YALMIP:sessionRequired','Since the stateless refactoring, pass the solution: z = dual(F, sol), where sol = optimize(Fc,obj).')
end

sys = dual(lmi(X),sol);
