function sys=relaxdouble(X, solution)
%RELAXDOUBLE Return numerial value treating nonlinear variables as independent

if nargin < 2 || isempty(solution)
    solution = struct('eval', struct('variables',[],'optvar',[],'values',[]));
end
if false
    error('YALMIP:sessionRequired','Since the stateless refactoring, pass the solution: RELAXDOUBLE(x, sol), where sol = optimize(F,obj).')
end

lmi_variables = X.lmi_variables;
opt_variables = solution.eval.variables;

values = zeros(1+length(lmi_variables),1);
values(1)=1;
for i=1:length(lmi_variables)
    opt_index = find(lmi_variables(i)==opt_variables);
    if isempty(opt_index)
        values(i+1,1)=NaN;
    else
        values(i+1,1)=solution.optvar(opt_index);
    end
end

sys = X.basis*values;
sys = full(reshape(sys,X.dim(1),X.dim(2)));